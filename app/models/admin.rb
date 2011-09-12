class Admin < ActiveRecord::Base
  
   #validations
	validates_presence_of :email, :name, :password,:confirmation_password
	validates_uniqueness_of :email

  
    def validate_on_create
      @email_format = Regexp.new(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/)
      errors.add(:email, "must be a valid format") unless @email_format.match(email)
      errors.add(:confirmation_password, "does not match") unless password == confirmation_password
      errors.add(:password, "cannot be blank") unless !password or password.length > 0
      errors.add(:password, "must be minimum 5 charecters") unless !password or password.length > 4      
    end




  #~ def password
  #~ @password
  #~ end

 def self.authenticate(email,password)
		admin = self.find_by_email(email)
		if admin
			expected_password = encrypted_password(password)
			if admin.password != expected_password
				admin=nil
			end
		end
		admin
	end
  
 def before_create
  		self.password  = Admin.encrypted_password(self.password)
      self.confirmation_password =self.password
  end
  

  
  
	
	private
	
	def self.encrypted_password(password)
    string_to_hash = password + "unchatted" 
		Digest::SHA1.hexdigest(string_to_hash)
	end
  
  
  
  end
