class Emailer < ActionMailer::Base
  
   def new_account(email,password,url)
    @subject                   = 'Account Login Details'
    @body['email']         =  email
    @body['password']  = password
    @body['url']          = url
    @recipients              =  email
    @from                     = 'postmaster@uncharted.net'      
  end
  
  def admin_accountactivation(email,url)
    @subject                   = 'Account Login Details'
    #@body['email']         =  email
    #@body['password']  = password
    @body['url']          = url
    @recipients              =  email
    @from                     = 'postmaster@uncharted.net'      
  end 
  
  
def photos_invitation(email,sendername,url)
  @subject                       = "Photo Invitation"
  @body['sendername']     =  sendername   
  @body['url']                =  url
  @recipients                    =  email
  @from                           = "postmaster@uncharted.net"
end  
 
  def story_invitation(email,sendername,url)
  @subject                      = "Story Invitation"
  @body['sendername']   =  sendername   
  @body['url']              = url
  @recipients                  =  email
  @from                         = "postmaster@uncharted.net"
  end  



  
  def videos_invitation(email,sendername,url)
  @subject                 = "Video's invitaion"
  @body['name']         =  sendername   
  @body['url']          = url
  @recipients              =  email
  @from                     = "postmaster@uncharted.net"
  end  
  
  def change_password(email,password)
  @subject                 = "Password Change notification for uncharted.net"
  @body['email']         =  email
   @body['password']  = password
  @recipients              =  email 
  @from                     = "postmaster@uncharted.net"
end  

def reset_password(email,password,url)
  @subject                 = "Forgot password notification for uncharted.net"
  @body['email']       =  email
  @body['password']  = password
  @body['url']          = url
  @recipients              =  email 
  @from                     = "postmaster@uncharted.net"
end

def admin_usermessage(name,email,message)
  @subject = "Message from Uncharted.net Admin"
  @body['name']   = name
  @body['message']   = message
  @recipients  = email
  @from        = "postmaster@uncharted.net"
  
end

def contact_form(name,email,message)
   @subject                   = 'Uncharted.net - Contact Us '
   @body['name'] = name
   @body['email']         =  email
   @body['message']          =message
   @recipients              =  'feedback@uncharted.net'
   @from                     = "postmaster@uncharted.net"  
  
end
  
end
