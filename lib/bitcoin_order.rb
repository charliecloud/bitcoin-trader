require_relative 'coinbase_transaction'

class BitcoinOrder
  attr_reader :created_dttm
  
  def initialize(btc_trans, buy_or_sell, price_thresh, effective_dttm, expiration_dttm, order_type, total_order_amount, times_to_order=1, amount_each_order)
    @btc_trans = btc_trans
    @buy_or_sell = buy_or_sell
    @price_thresh = price_thresh
    @created_dttm = DateTime.now
    @effective_dttm = effective_dttm
    @expiration_dttm = expiration_dttm
    @order_type = order_type
    @total_order_amount = total_order_amount
    @times_to_order = times_to_order
    @amount_each_order = amount_each_order
    @completed = false
    @num_times_run = 0
    @amount_so_far = 0
    
    @logger = Logger.new(STDOUT)
  end
  
  def run_order
    #only run if not completed
    return false if @completed
    #only run if it is past the effective date
    return false if @effective_dttm > DateTime.now
    #only run if not past the expiration date
    return false if @expiration_dttm < DateTime.now
    #only run if amount so far is less than so_far + how much for each order
    return false if ((@amount_so_far+@amount_each_order) > @total_order_amount)
    @logger.info("Checking conditions")
    check_conditions
  end
  
  private
  
  def check_conditions
    #get the price
    curr_price = @btc_trans.get_price.amount
    #check the type first
    @logger.info("Current price is #{curr_price}")
    if @buy_or_sell == :buy
      if @order_type == :absolute
        if curr_price <= @price_thresh
          #exectute order
          @logger.info("Executing but order for price_thresh #{@price_thresh}")
        end
      end
    end
    #if @order_type == :percent
      #check if the price is within the percent threshold
     # if #within the threshold
        #make the order
        #execute the order
      #else
      #  return false
      #end
    #else
     # if @buy_or_sell == :buy
      #  if curr_price <=  @price_thresh
          
     #   end
     # else
        
        
    #end
  end
  
  
  
end