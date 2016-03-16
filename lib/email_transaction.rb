require 'gmail'

class EmailTransaction
  @gmail = nil
 
  def initialize(email,pw)
    @gmail = Gmail.new(email, pw)
    @logger = Logger.new(STDOUT)
  end
  
  def send_email(fromAdd, toAdd, eSub, eBody)
    return false unless !@gmail.nil?
    email = @gmail.generate_message {
      from fromAdd
      to toAdd
      subject eSub
      body eBody }
    email.deliver! 
    @logger.info("Email delivered")
  end
  
  def get_emails(peek=false, fromAdd)
    return false unless !@gmail.nil?
    #Mark it as read?
    @gmail.peek = peek
    messages = @gmail.inbox.emails(:unread, :from => fromAdd)
    messages
  end
  
  def close_email
    @gmail.logout unless @gmail.nil?
  end
    
end