require_relative 'email_transaction'
require_relative 'coinbase_transaction'
require 'logger'

MIN_CHECK = 1

PRICE_BASE = 430
#TODO: Allow multiple price checks at different percentages
PER_THRESHOLD = 30

class BitcoinTrader
  
  #Initalizes the program
  def initialize(live, key, secret, url, email_from, pw, email_to)
    @logger = Logger.new(STDOUT)
    @email_from = email_from
    @email_to = email_to
    @email_transact = EmailTransaction.new(email_from, pw)
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
    #counter = 0
    while(true) do
      #puts counter
      #first do any standard actions and send notification if neccesary
      check_price_action
      #check for any actions that are needed
      get_email_commands_action
      sleep(60*MIN_CHECK)
      #counter += 1
    end
  end

  private
  
  def check_price_action
    @logger.info("Performing Price Check")
    curr_price = btc_price
    per_diff = percent_diff(PRICE_BASE, curr_price)
    send_email("Notification price change above #{per_diff}%","Price is: #{curr_price}") if per_diff >= PER_THRESHOLD
  end

  def get_email_commands_action
    messages = get_emails()
    # process the commands from the email subject lines
    messages.each {|m| read_email_subject_for_command(m.subject)}
  end

  def send_email(subject, body=nil)
    #TODO: Return whether it was successful?
    #TODO: Pass in subject and message
    @email_transact.send_email(@email_from, @email_to, 
                         subject,
                         body)                         
  end

  def get_emails()
    emails = @email_transact.get_emails(false, @email_to)
    emails
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
    #to_f never throws exception, so this is safe.
    amt = strings[1].to_f
    if amt.zero? && comm != "check"
      @logger.warn("Amount must be greater than 0")
      return
    end
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
    else
      @logger.warn("Unknown command #{comm}")
      return false
    end
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

