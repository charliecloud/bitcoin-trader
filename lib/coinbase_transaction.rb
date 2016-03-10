require 'coinbase/wallet'

class CoinbaseTransaction
  @client = nil
  
  def initialize(key, secret, url)
     @client = Coinbase::Wallet::Client.new(api_key: key, api_secret: secret, api_url: url)
     @file_logger = Logger.new('btc_trader_coinbase_transaction.log', 10, 1024000)
  end
  
  def get_price(currency="USD")
    @file_logger.info("Price Check Attempt")
    price = @client.buy_price({:currency => currency})
    @file_logger.info(price)
    price
  end
  
  def buy_btc(amt, currency="BTC", p_method=@client.payment_methods.first)
    #TODO: cutoff point for how many BTC to buy?
    #TODO: Bubble up exceptions when buying
    buy = @client.primary_account.buy({:amount => amt,
                                       :currency => currency,
                                       :payment_method => p_method.id})
    @file_logger.info("BTC Buy Attempt")                                      
    @file_logger.info(buy)                                           
    case buy.status
    when "completed"
      return true
    else
      return false
    end 
   end
   
 def sell_btc(amt, currency="BTC", p_method=@client.payment_methods.first)
    #TODO: Threshold for amount or price?
    sell = @client.primary_account.sell({:amount => amt,
                       :currency => "BTC",
                       :payment_method => p_method.id})
    @file_logger.info("BTC Sell Attempt")                        
    @file_logger.info(sell)  
    case sell.status
    when "completed"
      return true
    else
      return false
    end  
  end
                                      
  
end