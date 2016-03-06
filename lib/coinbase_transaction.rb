require 'coinbase/wallet'

class CoinbaseTransaction
  @client = nil
  
  def initialize(key, secret, url)
     @client = Coinbase::Wallet::Client.new(api_key: key, api_secret: secret, api_url: url)
  end
  
  def get_price()
    #TODO: Allow different currencies?
    @client.buy_price({currency: 'USD'})
  end
  
  def buy_btc(amt, currency="BTC", p_method=@client.payment_methods.first)
    #TODO: cutoff point for how many BTC to buy?
    #TODO: Bubble up exceptions when buying
    buy = @client.primary_account.buy({:amount => amt,
                                       :currency => currency,
                                       :payment_method => p_method.id})
    #puts buy.status                                           
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
    case sell.status
    when "completed"
      return true
    else
      return false
    end  
  end
                                      
  
end