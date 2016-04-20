require 'coinbase/wallet'

class CoinbaseTransaction

  def initialize(key, secret, abs_max, url=nil)
     @client = Coinbase::Wallet::Client.new(api_key: key, api_secret: secret, api_url: url)
     @abs_max = abs_max
     @file_logger = Logger.new('btc_trader_coinbase_transaction.log', 10, 1024000)
  end
  
  def get_price(currency="USD")
    @file_logger.info("Price Check Attempt")
    price = @client.buy_price({:currency => currency})
    @file_logger.info(price)
    price
  end
  
  def buy_btc(amt, currency="BTC", p_method=@client.payment_methods.first)
    @file_logger.info("BTC Buy Attempt")  
    if amt > @abs_max
      @file_logger.warn("Attempting to buy #{amt} when max is #{@abs_max}") 
      return false
    end
    begin
      buy = @client.primary_account.buy({:amount => amt,
                                        :currency => currency,
                                        :payment_method => p_method.id})
    rescue Exception => e
      @file_logger.error(e.message)
      return false
    end                                    
    @file_logger.info(buy)                                           
    case buy.status
    when "completed"
      return true
    else
      return false
    end 
   end
   
 def sell_btc(amt, currency="BTC", p_method=@client.payment_methods.first)
    @file_logger.info("BTC Sell Attempt") 
    if amt > @abs_max
      @file_logger.warn("Attempting to sell #{amt} when max is #{@abs_max}") 
      return false
    end
    begin
      sell = @client.primary_account.sell({:amount => amt,
                        :currency => "BTC",
                        :payment_method => p_method.id})  
    rescue Exception => e
      @file_logger.error(e.message)
      return false
    end                     
    @file_logger.info(sell)  
    case sell.status
    when "completed"
      return true
    else
      return false
    end  
  end
                                      
  
end