class See::PhotosController < ApplicationController
  
  before_filter :user_information 

  before_filter :left_top_adv,:left_bottom_adv,:right_adv
  
  layout 'see'
  
  

    def index
      
    if session[:user_id].blank? 
      layout_map
    end
    
      @page_title = "Photos"  
     #~ select = "continent country state, location, permalink, title,coverimage_id"
      if  !params[:search_by].blank? 
        
               if params[:search_by] =="Today"
                @page_title = "Photos - Today" 
                conditions =["lat is not null and longt is not null and date(created_on) LIKE ?",Time.now.to_date]
                @message = "No Photosets have been uploaded Today"
              elsif params[:search_by] =="Yestarday"
                @page_title = "Photos - Yestarday" 
                conditions =["lat is not null and longt is not null and date(created_on) LIKE ?",Time.now.yesterday.to_date]
                @message = "No Photosets have been uploaded on Yestarday"
              elsif   params[:search_by] =="Last Week"
               @page_title = "Photos - Last Week"  
               conditions =[" lat is not null and longt is not null and date(created_on) LIKE ?",1.week.ago.to_date]
               @message = "No Photosets have been uploaded on Last Week"
              elsif   params[:search_by] =="Most popular"
              @page_title = "Photos - Most popular"   
               conditions = ["lat is not null and longt is not null and id is not null" ]          
              else   
               @page_title = "Photos - #{params[:search_by]}"  
                conditions = ["lat is not null and longt is not null and country LIKE ?",params[:search_by]] 
              end  
                @photosets = Photoset.paginate :page => params[:page], :per_page => 45,   :conditions => conditions,:order => 'created_on DESC'
                @total = @photosets.total_entries          
     else
             conditions = ["lat is not null and longt is not null"] 
             @photosets = Photoset.paginate :page => params[:page], :per_page => 45,   :conditions => conditions, :order => 'created_on DESC'
             @total = @photosets.total_entries
     end 
           @countries = Photoset.find(:all, :select => "DISTINCT country as name", :conditions =>["lat IS NOT NULL AND longt IS NOT NULL AND country IS NOT NULL"], :order => "country DESC")
   end    
         
end
