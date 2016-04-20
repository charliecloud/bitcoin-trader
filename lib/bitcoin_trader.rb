require_relative 'email_transaction'
require_relative 'coinbase_transaction'
require_relative 'bitcoin_order'
require_relative 'email_command'
require 'logger'

class BitcoinTrader
  
  #Initalizes the program
  def initialize(min_check, abs_max, live, key, secret, url, email_from, pw, email_to)
    @min_check = min_check
    @abs_max = abs_max
    @email_from = email_from
    @pw = pw
    @email_to = email_to
    @logger = Logger.new(STDOUT)
    if !live
      @logger.info("Using Coinbase sandbox environment")
      @client = CoinbaseTransaction.new(key,secret,url)
    else
      @logger.info("Using Coinbase live env")
      @client = CoinbaseTransaction.new(key,secret)
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
    @logger.info("Performing price-check action")
    @logger.info("There are #{@price_percent_checks.length} price-checks to perform")
    curr_price = btc_price
    #for each of the price-check thresholds do a price check
    @price_percent_checks.each {
      |k,v| per_diff = percent_diff(k, curr_price)
      send_email("Notification price change above threshold #{v}%","Price is: #{curr_price}, Threshold price is #{k}") if per_diff >= v
    }
  end

  def get_email_commands_action
    @logger.info("Performing get-email-commands action")
    messages = get_emails
    @logger.info("There are #{messages.length} new emails to be acted on")
    # process the commands from the email subject lines
    messages.each {|message| read_email_subject_for_command(message.subject)}
  end
  
  def run_order_book_action
    @logger.info("Performing run-order-book action")
    @logger.info("There are #{@order_book.length} orders in the order-book")
    @order_book.each{|order| 
      if order.completed
        @order_book.delete(order)
      else
        order.run_order
      end}
  end

  def read_email_subject_for_command(email_subject)
    #TODO: Integrate BTC order into command structure
    if (!email_subject.nil? && !email_subject.eql?(""))
      email_subject.strip!
      strings = email_subject.split
      if strings[0] == "order"
        prepare_btc_order(strings)
        return
      end
    end
    #TODO: Create a standardized command format
    email_command = EmailCommand.new(email_subject)
    if email_command
      amt = email_command.btc_amount
      perc = email_command.percentage
      comm = email_command.command
      #check to see what command to do
      case comm
      when "buy"
        @logger.info("Buying: #{amt} BTC")
        bought = buy_btc(amt)
        if bought
          @logger.info("Bought #{amt} BTC successfully")
        else
          @logger.warn("Unable to buy #{amt} BTC")
        end
      when "sell"
        @logger.info("Selling: #{amt} BTC")
        sold = sell_btc(amt)
        if sold
          @logger.info("Sold #{amt} BTC successfully")
        else
          @logger.warn("Unable to sell #{amt} BTC")
        end
      when "price" 
        send_email("Price update: price is #{btc_price}")
      when "alert"
        add_price_check(amt,perc)
        @logger.info("Price check added for price: #{amt} and percent #{perc}")
      else
        @logger.warn("Unknown command #{comm}")
        return false
      end
    else
      @logger.warn("Unable to create email command object due to errors")
      return false
    end
  end
  
  def prepare_btc_order(array_of_strings)
    #format: order buy absolute 1(BTC) 11000 12 7(days to last for) 1(TTO) .01
    #First four parameters are required
    arr_length = array_of_strings.length
    if arr_length < 4
      @logger.error("To create btc_order need at least 4 params. Got #{arr_length}")
      return false
    end      
    #All the string transforms are safe           
    buy_or_sell = array_of_strings[1].to_sym
    order_type = array_of_strings[2].to_sym
    total_order_amount = array_of_strings[3].to_f
    price_thresh = array_of_strings[4].to_f unless array_of_strings[4].nil?
    per_thresh = array_of_strings[5].to_i unless array_of_strings[5].nil?
    effective_dttm = DateTime.now
    expiration_dttm = (DateTime.now + array_of_strings[6].to_i) unless array_of_strings[6].nil?
    times_to_order = array_of_strings[7].to_f unless array_of_strings[7].nil?
    amount_each_order = array_of_strings[8].to_f unless array_of_strings[8].nil?
     
    btc_order = BitcoinOrder.new(@client, buy_or_sell, order_type, total_order_amount, price_thresh, per_thresh, effective_dttm, 
                  expiration_dttm, times_to_order, amount_each_order)
    #Adding the order to the order book              
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
    if amt > @abs_max
      @logger.warn("Unable to execute buy BTC command for #{amt} BTC when max threshold is #{@abs_max} BTC")
      return false
    end
    return @client.buy_btc(amt, currency)                                
  end

  def sell_btc(amt, currency="BTC")
   if amt > @abs_max
      @logger.warn("Unable to execute sell BTC command for #{amt} BTC when max threshold is #{@abs_max} BTC")
      return false
    end
    return @client.sell_btc(amt, currency)
  end

  def percent_diff(base, change)
    (1-base/change) * 100
  end
  
  def btc_price
    price = @client.get_price
    price["amount"].to_f
  end

end

