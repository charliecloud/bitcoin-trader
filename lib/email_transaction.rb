require 'gmail'

class EmailTransaction
 
  def initialize(email,pw)
    @gmail = Gmail.new(email, pw)
    @logger = Logger.new(STDOUT)
  end
  
  def send_email(fromAdd, toAdd, eSub, eBody)
    email = @gmail.generate_message {
      from fromAdd
      to toAdd
      subject eSub
      body eBody }
    email.deliver! 
    @logger.info("Email delivered")
    return true
  end
  
  def get_emails(peek=false, fromAdd)
    #Mark it as read?
    @gmail.peek = peek
    messages = @gmail.inbox.emails(:unread, :from => fromAdd)
    messages
  end
  
  def close_email
    @gmail.logout
  end
    
end