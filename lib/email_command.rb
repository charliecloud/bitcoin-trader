class EmailCommand
  
  attr_accessor :command
  attr_accessor :btc_amount
  attr_accessor :percentage
  attr_reader :parameters
  
  def initialize(email_subject_command)
    @logger = Logger.new(STDOUT)
    #make sure it is not blank email subject
    if email_subject_command.nil? || email_subject_command.eql?("")
      log("Blank email subject line", :error)
      raise ArgumentError, "Blank email subject line"
    end
    email_subject_command.strip!
    strings = email_subject_command.split
    @parameters = strings
    #command is first position
    if strings[0].is_a? String
      @command = strings[0].downcase.to_sym
    else
       log("Expected first word in subject line to be a string. Got #{strings[0]}", :error)
       raise ArgumentError, "First word in subject line not a String"
    end
    #switch based on the type of command
    case @command
    when :order
    when :price
    when :alert
      @btc_amount = strings[1].to_f
      if @btc_amount.zero?
        log("BTC amount must be greater than 0 for alert command", :warn)
        raise ArgumentError, "BTC amount must be greater than 0 for alert command"
      end
      @percentage = strings[2].to_i
      if @percentage.zero? 
        log("Percentage must be greater than 0 for alert command", :warn)
        raise ArgumentError, "Percentage must be greater than 0 for alert command"
      end
    else 
      log("Command type given is unknown", :warn)
      raise ArgumentError, "Unknown command type"
    end
  end
  
  private
  
  #TODO: Make into a module and then mix-in
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