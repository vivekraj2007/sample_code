class Review < ActiveRecord::Base
  
   acts_as_rateable
   
  has_permalink :title, :permalink  
  #relations
  
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  has_many :review_comments,  :dependent => :delete_all
  has_many :linksets, :class_name => 'Linkset',  :foreign_key => "source_id", :conditions => "source_type = 'review' ",:dependent => :delete_all


  belongs_to :photoset,:class_name => 'Photoset', :foreign_key => "slideshow_id"
  #validates_uniqueness_of   :title
  validates_presence_of    :title ,:message => " can't be blank"  
  validates_presence_of    :description ,:message => " can't be blank"  
  validates_presence_of    :where ,:message => " can't be blank"  
  validates_multiparameter_assignments :message => " is not entered correctly."
  
  
  PLACES = ["Excellent","Best","Average","Below Average","Super"]
  #RATING = [1,2,3,4,5]
  RATING = [["My rating...",''],["1",1],["2",2],["3",3],["4",4],["5",5]]
  
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
