class Travelog < ActiveRecord::Base
  
    acts_as_rateable
  
   has_permalink :title, :permalink  
   
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"

  belongs_to :photoset,:class_name => 'Photoset', :foreign_key => "slideshow_id"
  
  
  has_many :linksets, :class_name => 'Linkset',  :foreign_key => "source_id", :conditions => "source_type = 'travelog' ",:dependent => :delete_all
  
  has_many :travelog_comments,  :dependent => :destroy
  
    #validates_uniqueness_of   :title
  validates_presence_of    :title ,:message => " can't be blank"  
  validates_presence_of    :description ,:message => " can't be blank"  
  validates_presence_of    :where ,:message => " can't be blank"  
  validates_multiparameter_assignments :message => " is not entered correctly."

    def sliced_title    
    unless self.title==nil
   if self.title.size > 20 || self.title.size == 20
     title= self.title.slice(0,17)+"..."
     return title
   else
     return self.title
  end
  end   
 end





end
