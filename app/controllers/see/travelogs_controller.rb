class See::TravelogsController < ApplicationController
  before_filter :get_browser_details
  before_filter :user_information 
  before_filter :travelog_countries
  layout 'see'
  
   def index
    if request.post?
         conditions = ["country_id LIKE ? AND status LIKE ?",params[:user][:country],1] 
         @travelogs = Travelog.paginate :page => params[:page], :per_page => 6, :conditions => conditions,:order => 'updated_at DESC'
         @total = Travelog.find(:all,:conditions => conditions,:select => "id")     
    else
       conditions = ["status LIKE ?",1]
       @travelogs = Travelog.paginate :page => params[:page], :per_page => 6, :conditions => conditions, :order => 'updated_at DESC'
       @total = Travelog.find(:all,:conditions => conditions,:select => "id")  
     end
     
   end  
       
  private
  
  def travelog_countries
     list = Array[] 
     total_travelogs = Travelog.find(:all,:conditions =>["country is not null "], :select => "country")
       total_travelogs.each do |travelog| 
         if  !list.include?("'"+travelog.country+"'")
         list.push("'"+travelog.country+"'")
         end
       end    
       if !list.blank?      
       @countries = Location.find(:all, :conditions => ["name in (#{list.join(",")})"])  
         else
       @countries = nil
       end  
     end  
end
