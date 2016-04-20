require_relative 'coinbase_transaction'

class BitcoinOrder
  attr_reader :completed
  
  def initialize(btc_trans, buy_or_sell, order_type, total_order_amount, price_thresh=nil, per_thresh=nil, effective_dttm=nil, expiration_dttm=nil, times_to_order=1, amount_each_order=nil)
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
    able_to_run = pre_run_checks
    if able_to_run
      fulfill_order
    else
      return false
    end
  end
  
  private
  
  def pre_run_checks
    #TODO: Run checks for orders that are not market orders to check all params there.
    #only run if not completed
    if @completed
      @logger.info("Order not able to run because already in completed status")
      return false
    end
    #only run if it is past the effective date
    if @effective_dttm > DateTime.now
      @logger.info("Order not able to run because it is not effective yet")
      return false
    end
    #only run if not past the expiration date
    #don't check this for market orders
    if !@order_type.eql?(:market)
      if @expiration_dttm < DateTime.now
        @logger.info("Order not able to run because it is already expired")
        #since the order is expired mark it as complete
        @completed = true
        return false
      end
    end
    #only run if amount so far is less than so_far + how much for each order
    #don't check for market orders
    if !@order_type.eql?(:market)
      if ((@amount_so_far+@amount_each_order) > @total_order_amount)
        @logger.info("Order is not able to run because doing so will put it over the total order amount")
        #mark it as complete now
        @completed = true
        return false
      end
    end
    @logger.info("Pre-run checks complete, attempting to fulfill #{@buy_or_sell} #{@order_type} order")
    return true
  end
  
  def fulfill_order
    trans_executed = false
    #get the price
    #TODO: Try-catch block
    curr_price = @btc_trans.get_price.amount.to_f
    per_thresh = percent_diff(@price_thresh, curr_price) unless @order_type.eql?(:market)
    case @buy_or_sell
    when :buy
      #@logger.info("Buy order")
      case @order_type
      when :market
          @logger.info("Executing market buy order at price #{curr_price}")
          trans_executed = true
          @completed = true
      when :absolute
        if curr_price <= @price_thresh
          #exectute order
          @logger.info("Executing absolute buy order at #{curr_price}, price_thresh is #{@price_thresh}")
          trans_executed = true
        end
      when :percent
        if per_thresh < -@per_thresh
          #execute order
          @logger.info("Executing percent buy order at #{curr_price}, per_thresh is #{-@per_thresh}")
          trans_executed = true
        end
      else
        @logger.warn("Unknown order_type #{@order_type}")
        return false
      end
    when :sell
      #@logger.info("Sell order")
      case @order_type
      when :market
          @logger.info("Executing market sell order at price #{curr_price}")
          trans_executed = true
          @completed = true
      when :absolute
        if curr_price >= @price_thresh
          #execute order
          @logger.info("Executing absolute sell order at #{curr_price}, price_thresh is #{@price_thresh}")
          trans_executed = true
        end
      when :percent
        if (per_thresh > @per_thresh)
          @logger.info("Executing percent sell order at #{curr_price}, per_thresh is #{@per_thresh}")
          trans_executed = true
        end
      end
    else
      @logger.warn("Unknown buy_or_sell type #{@buy_or_sell}")
      return false
    end
    if trans_executed
      @logger.info("Order executed")
      post_run_checks
    else
      @logger.info("Order not exectued")
    end
  end
  
  def post_run_checks
    if !@order_type.eql?(:market)
      @num_times_run += 1
      @completed = true if @num_times_run == @times_to_order
      @completed = true if @expiration_dttm < DateTime.now
      @amount_so_far += @amount_each_order
      @completed = true if @amount_so_far >= @total_order_amount
    end
    if @completed
      @logger.info("Order is complete")
    else
      @logger.info("Order is not complete, may complete later")
    end
  end
  
  def percent_diff(base, change)
    (1-base.to_f/change.to_f) * 100
  end
  
end