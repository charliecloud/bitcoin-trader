require_relative 'email_transaction'
require_relative 'coinbase_transaction'

MIN_CHECK = 1

PRICE_BASE = 430
#TODO: Allow multiple price checks at different percentages
PER_THRESHOLD = 30

class BitcoinTrader
  
  #Initalizes the program
  def initialize(live, key, secret, url, email_from, pw, email_to)
    @email_from = email_from
    @email_to = email_to
    @email_transact = EmailTransaction.new(email_from, pw)
    if !live
      puts "Using sandbox"
      @client = CoinbaseTransaction.new(key,secret,url)
    else
      puts "Using live env"
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
    per_diff = percent_diff(PRICE_BASE, btc_price)
    log_event(per_diff) if per_diff >= PER_THRESHOLD
  end

  def get_email_commands_action
    messages = get_emails()
    # process the commands from the email subject lines
    messages.each {|m| read_email_subject_for_command(m.subject)}
  end

  def send_email(content)
    #TODO: Return whether it was successful?
    @email_transact.send_email(@email_from, @email_to, 
                         "Notification price change above #{PER_THRESHOLD}%",
                          "Price is: #{content}")                         
  end

  def get_emails()
    emails = @email_transact.get_emails(false, @email_to)
    emails
  end

  def read_email_subject_for_command(email_subject)
    #make sure it is not blank email subject
    #TODO: Seperate all the subject checking to seperate function
    if email_subject.nil?
      puts "Blank email subject line"
      return
    end
    email_subject.strip!
    strings = email_subject.split
    #command is first position and amount is second
    if strings[0].is_a? String
      comm = strings[0].downcase
    else
       puts "First word in subject line must be a string. Got #{strings[0]}"
       return
    end
    #to_f never throws exception, so this is safe.
    amt = strings[1].to_f
    if amt.zero? && comm != "check"
      puts "Amount must be greater than 0"
      return
    end
    #check to see what command to do
    case comm
    when "buy"
      puts "Buying: #{amt} BTC"
      bought = buy_btc(amt)
      puts "Bought #{amt} BTC successfully" unless !bought
    when "sell"
      puts "Selling: #{amt} BTC"
      sold = sell_btc(amt)
      puts "Sold #{amt} BTC successfully" unless !sold
    when "check" 
      @email_transact.send_email(@email_from, @email_to, 
                            "Price update: price is #{btc_price}",
                            nil)
    else
      puts "Error: Unknown command #{comm}"
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

  def log_event(event)
    #TODO: Log to a text file
    puts event
    send_email(event)
  end
  
  def btc_price
    price = @client.get_price()
    price["amount"].to_f
  end

end

