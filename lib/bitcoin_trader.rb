require_relative 'email_transaction'
require_relative 'coinbase_transaction'
require_relative 'bitcoin_order'
require 'logger'

class BitcoinTrader
  MIN_CHECK = 1
  
  #Initalizes the program
  def initialize(live, key, secret, url, email_from, pw, email_to)
    @price_percent_checks = {}
    #order book that will contain all of the current orders that need to be executed
    @order_book = []
    @logger = Logger.new(STDOUT)
    @email_from = email_from
    @pw = pw
    @email_to = email_to
    if !live
      @logger.info("Using sandbox")
      @client = CoinbaseTransaction.new(key,secret,url)
    else
      @logger.info("Using live env")
      @client = CoinbaseTransaction.new(key,secret)
    end
  end
  
  #Main program loop
  def run
    while(true) do
      #get all new actions from email
      get_email_commands_action
      #perform the check_price action as needed
      check_price_action
      #run the order book action to execute any valid orders
      run_order_book_action
      sleep(60*MIN_CHECK)
    end
  end

  private
  
  def check_price_action
    @logger.info("Performing price-check Action")
    @logger.info("There are #{@price_percent_checks.length} price-checks to perform")
    curr_price = btc_price
    #for each of the price-check thresholds do a price check
    @price_percent_checks.each {
      |k,v| per_diff = percent_diff(k, curr_price)
      send_email("Notification price change above threshold #{v}%","Price is: #{curr_price}, Threshold price is #{k}") if per_diff >= v
    }
  end

  def get_email_commands_action
    @logger.info("Performing get-email-commands Action")
    messages = get_emails()
    @logger.info("Retrieved #{messages.length} emails")
    # process the commands from the email subject lines
    messages.each {|m| read_email_subject_for_command(m.subject)}
  end
  
  def run_order_book_action
    @logger.info("Performing run-order-book Action")
    @logger.info("There are #{@order_book.length} orders in the order-book")
    @order_book.each{|order| 
      if order.completed
        @order_book.delete(order)
      else
        order.run_order
      end}
  end

  def read_email_subject_for_command(email_subject)
    #make sure it is not blank email subject
    #TODO: Seperate all the subject checking to seperate function
    if email_subject.nil?
      @logger.warn("Blank email subject line")
      return
    end
    email_subject.strip!
    strings = email_subject.split
    #command is first position and amount is second
    if strings[0].is_a? String
      comm = strings[0].downcase
    else
       @logger.error("First word in subject line must be a string. Got #{strings[0]}")
       return
    end
    #seperate out the fucntionality for managing an order for now
    if comm == "order"
      prepare_btc_order(strings)
      return
    end
    #to_f never throws exception, so this is safe.
    amt = strings[1].to_f
    if amt.zero? && comm != "check"
      @logger.warn("Amount must be greater than 0")
      return
    end
    #percentage will be 3rd parameter for adding alerts
    perc = strings[2].to_i
    
    #check to see what command to do
    case comm
    when "buy"
      @logger.info("Buying: #{amt} BTC")
      bought = buy_btc(amt)
      @logger.info("Bought #{amt} BTC successfully") unless !bought
    when "sell"
      @logger.info("Selling: #{amt} BTC")
      sold = sell_btc(amt)
      @logger.info("Sold #{amt} BTC successfully") unless !sold
    when "check" 
      send_email("Price update: price is #{btc_price}")
    when "add"
      add_price_check(amt,perc)
      @logger.info("Price check added for price: #{amt} and percent #{perc}")
    else
      @logger.warn("Unknown command #{comm}")
      return false
    end
  end
  
  def prepare_btc_order(array_of_strings)
     #order buy absolute 11000 12 7(days to last for) 1(BTC) 1(TTO) .01                     
     buy_or_sell = array_of_strings[1].to_sym
     order_type = array_of_strings[2].to_sym
     price_thresh = array_of_strings[3].to_f
     per_thresh = array_of_strings[4].to_i
     effective_dttm = DateTime.now
     expiration_dttm = DateTime.now + array_of_strings[5].to_i
     
     total_order_amount = array_of_strings[6].to_f
     times_to_order = array_of_strings[7].to_f
     amount_each_order = array_of_strings[8].to_f
     btc_order = BitcoinOrder.new(@client, buy_or_sell, price_thresh, per_thresh, effective_dttm, 
                  expiration_dttm, order_type, total_order_amount, times_to_order, amount_each_order)
     @order_book.push(btc_order)
     
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
  
  def buy_btc(amt, currency="BTC")  
    #TODO: Threshold for amount or price?
    return @client.buy_btc(amt, currency)                                
  end

  def sell_btc(amt, currency="BTC")
    #TODO: Threshold for amount or price?
    return @client.sell_btc(amt, currency)
  end

  def percent_diff(base, change)
    (1-base/change) * 100
  end
  
  def btc_price
    price = @client.get_price()
    price["amount"].to_f
  end

end

