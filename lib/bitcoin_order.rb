require_relative 'coinbase_transaction'

class BitcoinOrder
  attr_reader :completed
  
  def initialize(btc_trans, buy_or_sell, price_thresh, per_thresh, effective_dttm, expiration_dttm, order_type, total_order_amount, times_to_order=1, amount_each_order)
    @btc_trans = btc_trans
    @buy_or_sell = buy_or_sell
    @price_thresh = price_thresh
    @per_thresh = per_thresh
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
    able_to_run = true;
    #TODO: set to complete on certain criteria
    #only run if not completed
    if @completed
      @logger.info("Order not able to run because already in completed status")
      able_to_run = false;
    end
    #only run if it is past the effective date
    if @effective_dttm > DateTime.now
      @logger.info("Order not able to run because it is not effective yet")
      able_to_run = false;
    end
    #only run if not past the expiration date
    if @expiration_dttm < DateTime.now
      @logger.info("Order not able to run because it is already expired")
      able_to_run = false;
    end
    #only run if amount so far is less than so_far + how much for each order
    if ((@amount_so_far+@amount_each_order) > @total_order_amount)
      @logger.info("Order is not able to run because doing so will put it over the total order amount")
      able_to_run = false;
    end
    return false unless able_to_run
    @logger.info("Initial checks complete, attempting to fulfill #{@order_type} order for #{@amount_each_order} BTC")
    fulfill_order
  end
  
  private
  
  def fulfill_order
    trans_executed = false;
    #get the price
    curr_price = @btc_trans.get_price.amount.to_f
    per_thresh = percent_diff(@price_thresh, curr_price)
    #check the type first
    @logger.info("Current price is #{curr_price}, threshold is #{@price_thresh}")
    @logger.info("Percent diff is #{per_thresh}, threshold is #{@per_thresh}")
    if @buy_or_sell == :buy
      @logger.info("Buy order")
      if @order_type == :absolute
        if curr_price <= @price_thresh
          #exectute order
          @logger.info("Executing absolute buy order for price_thresh #{@price_thresh}, price is #{curr_price}")
          trans_executed = true;
        end
      elsif @order_type == :percent
        if (per_thresh < -@per_thresh)
          #execute order
          @logger.info("Executing percent buy order for per_thresh #{-@per_thresh}, price is #{curr_price}")
          trans_executed = true;
        end
      else
        @logger.warn("Unknown order_type #{@order_type}")
      end
    elsif @buy_or_sell == :sell
      @logger.info("Sell order")
      if @order_type == :absolute
        if curr_price >= @price_thresh
          #execute order
          @logger.info("Executing absolute sell order for price_thresh #{@price_thresh}, price is #{curr_price}")
          trans_executed = true;
        end
      elsif @order_type == :percent
        if (per_thresh > @per_thresh)
          @logger.info("Executing percent sell order for per_thresh #{@per_thresh}, price is #{curr_price}")
          trans_executed = true;
        end
      end
    else
      @logger.warn("Unknown buy_or_sell type #{@buy_or_sell}")
    end
    if trans_executed
      @logger.info("Order exectued")
      post_order_updates
    else
      @logger.info("Order not exectued")
    end
  end
  
  def post_order_updates
    @num_times_run += 1
    @completed = true if @num_times_run == @times_to_order
    @completed = true if @expiration_dttm < DateTime.now
    @amount_so_far += @amount_each_order
    @completed = true if @amount_so_far >= @total_order_amount
    if(@completed)
      @logger.info("Order is complete")
    else
      @logger.info("Order is not complete, may complete later")
    end
  end
  
  def percent_diff(base, change)
    (1-base.to_f/change.to_f) * 100
  end
  
end