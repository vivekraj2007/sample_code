class ContactMailer < ActionMailer::Base
  self.smtp_settings = {
    :address => "smtp.gmail.com",
    :port => 587,
    :authentication => :plain,
    :enable_starttls_auto => true,
    :user_name => "contactform@tatango.com",
    :password => 'happyburger25',
  }

  def contact_message(subject, email, phone, business, fullname, textbox) 
    mail(
      :subject => subject,
      :from => "#{fullname} <#{email}>",
      :reply_to => "#{fullname} <#{email}>",
      :to => 'support@tatango.com',
      :body => "Phone: #{phone}\nBusiness/Organization: #{business}\n\n#{textbox}"
    )
  end
end
