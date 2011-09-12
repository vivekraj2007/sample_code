class See::ReviewsController < ApplicationController
  before_filter :get_browser_details
  before_filter :user_information 
  before_filter :review_countries
  layout 'see'
  
   def index
    if request.post?
      if params[:user][:country] =="Date"
          conditions = ["status LIKE ?",1]
          order = 'updated_on DESC'
      elsif params[:user][:country] =="Best"  
          conditions = ["status LIKE ?",1]
          order = 'rating DESC'        
      elsif params[:user][:country] =="Worst"  
          conditions = ["status LIKE ?",1]
          order = 'rating ASC'         
      elsif params[:user][:country] =="Places to stay"  
          conditions = ["status LIKE ?",1]
          order = 'rating ASC'    
        elsif params[:user][:country] =="Places to eat"  
          conditions = ["status LIKE ?",1]
          order = 'rating ASC' 
        elsif params[:user][:country] =="Entertainment"  
          conditions = ["status LIKE ?",1]
          order = 'rating ASC'   
        elsif params[:user][:country] =="Attractions"  
          conditions = ["status LIKE ?",1]
          order = 'rating ASC'     
        elsif params[:user][:country] =="Activities"  
          conditions = ["status LIKE ?",1]
          order = 'rating ASC'            
      else
       conditions = ["country_id LIKE ? AND status LIKE ?",params[:user][:country],1] 
       order = 'title ASC'
       end
       @reviews = Review.paginate :page => params[:page], :per_page => 6, :conditions => conditions, :order =>  order
       @total = Review.find(:all,:conditions => conditions,:select => "id")    
    else     
       conditions = ["status LIKE ?",1]
       @reviews = Review.paginate :page => params[:page], :per_page => 6, :conditions => conditions, :order => 'title ASC'
       @total = Review.find(:all,:conditions => conditions,:select => "id")  
    end   
     end
  
  
    private
  
  def review_countries
     list = Array[] 
     total_reviews = Review.find(:all,:conditions =>["country is not null "], :select => "country")
       total_reviews.each do |review| 
         if  !list.include?("'"+review.country+"'")
         list.push("'"+review.country+"'")
         end
       end    
       if !list.blank?      
       @countries = Location.find(:all, :conditions => ["name in (#{list.join(",")})"]) 
         else
       @countries = nil
       end  
     end  
end
