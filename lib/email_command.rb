class EmailCommand
  
  attr_accessor :command
  attr_accessor :btc_amount
  attr_accessor :percentage
  
  def initialize(email_subject_command)
    @logger = Logger.new(STDOUT)
    #make sure it is not blank email subject
    if email_subject_command.nil? || email_subject_command.eql?("")
      log("Blank email subject line", :error)
      return false
    end
    email_subject_command.strip!
    strings = email_subject_command.split
    #command is first position
    if strings[0].is_a? String
      @command = strings[0].downcase
    else
       log("Expected first word in subject line to be a string. Got #{strings[0]}", :error)
       return false
    end
    #to_f never throws exception, so this is safe.
    @btc_amount = strings[1].to_f
    if @btc_amount.zero? && @command != "check"
      log("BTC Amount must be greater than 0", :warn)
      return false
    end
    #percentage will be 3rd parameter for adding alerts
    @percentage = strings[2].to_i
    if @percentage.zero? 
      log("Percentage must be greater than 0", :warn)
      return false
    end
    
  end
  
  private
  
  def log(message, severity)
    case severity
    when :info
      @logger.info(self.class.name+": "+message)
    when :warn
      @logger.warn(self.class.name+": "+message)
    when :error
      @logger.error(self.class.name+": "+message)
    end
  end
  
end