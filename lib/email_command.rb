class EmailCommand
  
  attr_accessor :command
  attr_accessor :btc_amount
  attr_accessor :percentage
  
  def initialize(email_subject_command)
    @logger = Logger.new(STDOUT)
    #make sure it is not blank email subject
    if email_subject_command.nil? || email_subject_command.eql?("")
      @logger.warn("Blank email subject line")
      return false
    end
    email_subject_command.strip!
    strings = email_subject_command.split
    #command is first position and amount is second
    if strings[0].is_a? String
      @command = strings[0].downcase
    else
       @logger.error("Expected first word in subject line to be a string. Got #{strings[0]}")
       return false
    end
    #to_f never throws exception, so this is safe.
    @btc_amount = strings[1].to_f
    if @btc_amount.zero? && @command != "check"
      @logger.warn("BTC Amount must be greater than 0")
      return false
    end
    #percentage will be 3rd parameter for adding alerts
    @percentage = strings[2].to_i
    if @percentage.zero? 
      @logger.warn("Percentage must be greater than 0")
      return false
    end
    
  end
  
end