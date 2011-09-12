require "digest/sha1"
class User < ActiveRecord::Base
 
 
   #relationship
   has_one :profile,  :dependent => :destroy
   has_one :user_setting,  :dependent => :destroy
   has_one :wanttoplace,  :dependent => :destroy
   
   belongs_to :country
   
   #inbox mails relation
   has_many :to_mails, :class_name => "UserMail",
   :foreign_key => "to_user", 
   :conditions => ["to_deleted = 0"], 
   :order => "date_sent desc",
   :dependent => :delete_all 
   
   #send mails relation
   has_many :from_mails, :class_name => "UserMail",
   :foreign_key => "from_user" ,
   :conditions => ["from_deleted = 0 and subject != 'friends request'" ], 
   :order => "date_sent desc",   
   :dependent => :delete_all   
   
   
   has_many :friends, :class_name => "UserNetwork", :foreign_key => "friend_id", :dependent => :delete_all   

   has_many :photosets,  :dependent => :delete_all
   has_many :photo_comments,  :dependent => :delete_all   
   has_many :photos,  :through => :photosets
   
   
   
   has_many :videosets,  :dependent => :delete_all
   has_many :videos,  :through => :videosets
   
   has_many :stories, :dependent => :delete_all
   has_many :story_comments,  :dependent => :delete_all
    
   has_many :reviews,  :dependent => :delete_all     
   has_many :travelogs,  :dependent => :delete_all   
   
   has_many :latest_adventures,  :order => "updated_at DESC",  :dependent => :delete_all     
   has_many :event, :class_name => "Event", :foreign_key => "user_id" , :dependent => :delete_all 

   
   #relations for see module display content  
   has_many :approved_videosets, :class_name => 'Videoset',  :foreign_key => "user_id",
   :conditions => "continent is not null AND country_id is not null AND state is not null AND location is not null"  
   
   
	 attr_accessor :password, :confirm_password, :agree
 
  
  
  #validations
	validates_presence_of :first_name, :last_name,:email, :city, :country_id,  :screen_name
	
  validates_uniqueness_of :screen_name,:email, :case_sensitive => false
  #validates_uniqueness_of 
 
  
    def validate_on_create
      @email_format = Regexp.new(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/)
      errors.add(:email, "must be a valid format") unless @email_format.match(email)
      errors.add(:confirm_password, "does not match") unless password == confirm_password
      errors.add(:password, "cannot be blank") unless !password or password.length > 0
      #errors.add(:password, "must be minimum 6 charecters") unless !password or password.length > 6      
    end

 def country_name
     self.country.name
 end
  
  
  
  #~ after_save :reload_yut  
  
  #~ def reload_yut    
  #~ ApplicationHelper.reload_session(self.id)
  #~ end


 

  def password
  @password
  end

 def self.authenticate(email, password)
		user = self.find_by_email(email)
		if user
			expected_password = encrypted_password(password, user.password_salt)
			if user.password_hash != expected_password
				user=nil
			end
		end
		user
	end
  
 def before_create
  create_new_salt
		self.password_hash = User.encrypted_password(self.password,self.password_salt)
 end
  

  
  
	
	private
	
	def self.encrypted_password(password,salt)
    string_to_hash = password + "unchatted" + salt 
		Digest::SHA1.hexdigest(string_to_hash)
	end
	def create_new_salt
		self.password_salt = self.object_id.to_s + rand.to_s
	end
  
  
  def self.generate_activation_code
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    activation_code = ''
    1.upto(8) { |i| activation_code << chars[rand(chars.size-1)] }
    return activation_code
  end

  
end
