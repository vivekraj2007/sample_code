class Event < ActiveRecord::Base
  
  
  #relations
  
   belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  
  
  
  
  
  
  
    validates_uniqueness_of   :title
    validates_presence_of    :title ,:message => "Title can't be blank"  
    validates_presence_of    :description ,:message => "Description can't be blank"  
    validates_multiparameter_assignments :message => " is not entered correctly."

    validates_date :begin_date, :before => [:end_date], :after => '1 Jan 1900'
    validates_date :begin_date, :after => Proc.new { 0.day.from_now.to_date }
    validates_date :end_date
    
    
    
end
