module ConsoleLogger
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