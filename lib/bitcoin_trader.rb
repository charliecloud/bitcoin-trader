require_relative 'email_transaction'
require_relative 'coinbase_transaction'
require_relative 'bitcoin_order'
require_relative 'email_command'
require_relative 'console_logger'
require 'logger'

class BitcoinTrader
  include ConsoleLogger
  #TODO: Get all current alerts
  
  #Initalizes the program
  def initialize(min_check, abs_max, live, key, secret, url, email_from, pw, email_to)
    @min_check = min_check
    @abs_max = abs_max
    @email_from = email_from
    @pw = pw
    @email_to = email_to
    @logger = Logger.new(STDOUT)
    if !live
      log("Using Coinbase sandbox environment", :info)
      @client = CoinbaseTransaction.new(key,secret,abs_max,url)
    else
      log("Using Coinbase LIVE environment!", :warn)
      @client = CoinbaseTransaction.new(key,secret,abs_max)
    end
    @price_percent_checks = {}
    #order book that will contain all of the current orders that need to be executed
    @order_book = []
  end
  
  #Main program loop
  def run
    while true do
      #get all new actions from email
      get_email_commands_action
      #perform the check_price action as needed
      check_price_action
      #run the order book action to execute any valid orders
      run_order_book_action
      sleep(60*@min_check)
    end
  end

  private
  
  def check_price_action
    log("Performing price-check action", :info)
    log("There are #{@price_percent_checks.length} price-checks to perform", :info)
    curr_price = btc_price
    #for each of the price-check thresholds do a price check
    @price_percent_checks.each {
      |k,v| per_diff = percent_diff(k, curr_price)
      send_email("Alert update: price change above threshold #{v}%","Price is: #{curr_price}, Threshold price is #{k}, Percent difference is #{per_diff}") if per_diff >= v
    }
  end

  def get_email_commands_action
    log("Performing get-email-commands action", :info)
    messages = get_emails
    log("There are #{messages.length} new emails to be acted on", :info)
    # process the commands from the email subject lines
    messages.each {|message| 
      success = read_email_subject_for_command(message.subject)
      #let the user know whether the command was done successfully
      send_email("Encountered issue processing command, check syntax") unless success
      }
  end
  
  def run_order_book_action
    log("Performing run-order-book action", :info)
    log("There are #{@order_book.length} orders in the order-book", :info)
    @order_book.each{|order| 
      if order.completed
        @order_book.delete(order)
      else
        order.run_order
      end}
  end

  def read_email_subject_for_command(email_subject)
    begin
      email_command = EmailCommand.new(email_subject)
    rescue ArgumentError
      log("Unable to create email command object due to errors", :warn)
      return false
    end
    comm = email_command.command
    #check to see what command to do
    case comm
    when :order
      log("Creating btc order", :info)
      success = prepare_btc_order(email_command.parameters)
      return success
    when :price 
      log("Sending requested price update", :info)
      send_email("Price update: price is #{btc_price}")
      return true
    when :alert
      amt = email_command.btc_amount
      perc = email_command.percentage
      add_price_check(amt,perc)
      log("Price alert added for price: #{amt} and percent #{perc}", :info)
      return true
    when :cancel
      log("Cancelling all price alerts", :info)
      @price_percent_checks = {}
      log("All price alerts cancelled", :info)
      return true
    else
      log("Unknown command #{comm}. Will not act on it.", :warn)
      return false
    end
  end
  
  def prepare_btc_order(array_of_strings)
    #format: order buy absolute 1(BTC) 11000 12 7(days to last for) 1(TTO) .01
    begin
      btc_order = BitcoinOrder.new(@client, array_of_strings)
      @order_book.push(btc_order) if btc_order 
    rescue ArgumentError
      log("Unable to create btc order object due to errors", :warn)
      return false
    end
  end
  
  def send_email(subject, body=nil)
    email_transact = EmailTransaction.new(@email_from, @pw)
    result = email_transact.send_email(@email_from, @email_to, 
                         subject,
                         body)      
    #FIXME: Figure out how to close emails without erroring out 
    #email_transact.close_email
    result                  
  end

  def get_emails
    email_transact = EmailTransaction.new(@email_from, @pw)
    emails = email_transact.get_emails(false, @email_to)
    #email_transact.close_email
    emails
  end
  
  def add_price_check(price, percent)
    @price_percent_checks[price] = percent
  end

  def percent_diff(base, change)
    (1-base/change) * 100
  end
  
  def btc_price
    price = @client.get_price
    price["amount"].to_f
  end

end

