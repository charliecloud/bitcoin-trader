require_relative 'coinbase_transaction'
require_relative 'console_logger'

class BitcoinOrder
  include ConsoleLogger
  attr_reader :completed
  
   def initialize(btc_trans, array_of_strings)
     #TODO: Only allow certain order types
    @logger = Logger.new(STDOUT)
    #first three are required
    arr_length = array_of_strings.length
    if arr_length < 4
      log("To create btc order need at least 4 params. Got #{arr_length}", :error)
      raise ArgumentError, "wrong number of arguments"
    end  
    @buy_or_sell = array_of_strings[1].to_sym
    @order_type = array_of_strings[2].to_sym
    @total_order_amount = array_of_strings[3].to_f
    #make this required when the order type is absolute
    @price_thresh = array_of_strings[4].to_f unless array_of_strings[4].nil?
    if @price_thresh.nil? && @order_type.eql?(:absolute)
      log("Absolute btc order requires a price threshold", :error)
      raise ArgumentError, "absolute orders require a price threshold"
    end
    #make this required when the order type is percent
    @per_thresh = array_of_strings[5].to_i unless array_of_strings[5].nil?
    if @price_thresh.nil? && @order_type.eql?(:percent)
      log("Percent btc order requires a percent threshold", :error)
      raise ArgumentError, "percent orders require a price threshold"
    end
    #TODO: Allow an effective dttm to be passed in
    @effective_dttm = DateTime.now
    #set a default expiration date
    @expiration_dttm = (DateTime.now + array_of_strings[6].to_i) unless array_of_strings[6].nil?
    @expiration_dttm ||= DateTime.now + 1
    #default the times to order to 1
    @times_to_order = array_of_strings[7].to_f unless array_of_strings[7].nil?
    @times_to_order ||= 1
    #default the amount each order to total order / number of times to order
    @amount_each_order = array_of_strings[8].to_f unless array_of_strings[8].nil?
    @amount_each_order ||= @total_order_amount/@times_to_order.to_f
    
    @btc_trans = btc_trans
    
    @completed = false
    @num_times_run = 0
    @amount_so_far = 0
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
    #only run if not completed
    if @completed
      log("Order not able to run because already in completed status", :info)
      return false
    end
    #only run if it is past the effective date
    if @effective_dttm > DateTime.now
      log("Order not able to run because it is not effective yet", :info)
      return false
    end
    #only run if not past the expiration date
    if @expiration_dttm < DateTime.now
      log("Order not able to run because it is already expired", :info)
      #since the order is expired mark it as complete
      @completed = true
      return false
    end
    #only run if amount so far is less than so_far + how much for each order
    if ((@amount_so_far+@amount_each_order) > @total_order_amount)
      log("Order is not able to run because doing so will put it over the total order amount", :info)
      #mark it as complete now
      @completed = true
      return false
    end
    log("Pre-run checks complete, attempting to fulfill #{@buy_or_sell} #{@order_type} order", :info)
    return true
  end
  
  def fulfill_order
    #TODO: Implement the buy and sell to do actual transactions
    trans_executed = false
    #get the price
    #TODO: Try-catch block
    curr_price = @btc_trans.get_price.amount.to_f
    per_thresh = percent_diff(@price_thresh, curr_price) unless @order_type.eql?(:market)
    case @buy_or_sell
    when :buy
      #log("Buy order")
      case @order_type
      when :market
          log("Executing market buy order at price #{curr_price}", :info)
          trans_executed = true
          @completed = true
      when :absolute
        if curr_price <= @price_thresh
          #exectute order
          log("Executing absolute buy order at #{curr_price}, price_thresh is #{@price_thresh}", :info)
          trans_executed = true
        end
      when :percent
        if per_thresh < -@per_thresh
          #execute order
          log("Executing percent buy order at #{curr_price}, per_thresh is #{-@per_thresh}", :info)
          trans_executed = true
        end
      else
        log("Unknown order_type #{@order_type}", :warn)
        return false
      end
    when :sell
      #log("Sell order")
      case @order_type
      when :market
          log("Executing market sell order at price #{curr_price}", :info)
          trans_executed = true
          @completed = true
      when :absolute
        if curr_price >= @price_thresh
          #execute order
          log("Executing absolute sell order at #{curr_price}, price_thresh is #{@price_thresh}", :info)
          trans_executed = true
        end
      when :percent
        if (per_thresh > @per_thresh)
          log("Executing percent sell order at #{curr_price}, per_thresh is #{@per_thresh}", :info)
          trans_executed = true
        end
      end
    else
      log("Unknown buy_or_sell type #{@buy_or_sell}", :warn)
      return false
    end
    if trans_executed
      log("Order executed", :info)
      post_run_checks
    else
      log("Order not executed", :info)
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
      log("Order is complete", :info)
    else
      log("Order is not complete, may complete later", :info)
    end
  end
  
  def percent_diff(base, change)
    (1-base.to_f/change.to_f) * 100
  end
  
end