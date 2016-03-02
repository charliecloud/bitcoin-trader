require 'gmail'

module EmailHelper
  @@gmail = nil
 
  def EmailHelper.init_email(email,pw)
    @@gmail = Gmail.new(email, pw)
  end
  
  def EmailHelper.send_email(fromAdd, toAdd, eSub, eBody)
    return false unless !@@gmail.nil?
    email = @@gmail.generate_message do
      from fromAdd
      to toAdd
      subject eSub
      body eBody
    end
    email.deliver! 
  end
  
  def EmailHelper.get_emails(peek=false, fromAdd)
    return false unless !@@gmail.nil?
    #Mark it as read?
    @@gmail.peek = peek
    messages = @@gmail.inbox.emails(:unread, :from => fromAdd)
    messages
  end
  
  def EmailHelper.close_email
    @@gmail.logout unless @@gmail.nil?
  end
    
end