class See::VideosController < ApplicationController
  before_filter :get_browser_details
  before_filter :user_information 
  before_filter :videos_countries

  layout 'see'
  
  def index
      if request.post?
        
        if params[:user][:country] =="Today"
          conditions =["lat is not null and longt is not null and date(created_on) LIKE ?",Time.now.to_date]
          @message = "No Video Sets have been uploaded Today"
        elsif params[:user][:country] =="Yestarday"
          conditions =["lat is not null and longt is not null and date(created_on) LIKE ?",Time.now.yesterday.to_date]
          @message = "No Video Sets have been uploaded on Yestarday"
        elsif   params[:user][:country] =="Last Week"
         conditions =["lat is not null and longt is not null and date(created_on) LIKE ?",1.week.ago.to_date]
         @message = "No Video Sets have been uploaded on Last Week"
        elsif   params[:user][:country] =="Most popular"
         conditions = ["id is not null" ]          
        else   
          conditions = ["lat is not null and longt is not null and country LIKE ?",params[:user][:country]] 
        end  
        
      @videosets = Videoset.paginate :page => params[:page], :per_page => 45, :conditions => conditions,:order => 'created_on DESC'
      @total = Videoset.find(:all,:conditions => conditions,:select => "id")     
    else
      conditions =["lat is not null and longt is not null"]
     @videosets = Videoset.paginate :page => params[:page], :per_page => 45,  :conditions => conditions,:order => 'created_on DESC'
     @total = Videoset.find(:all, :conditions => conditions, :select => "id") 
   end
   
  end
  
  
  
    private
  
  def videos_countries
     list = Array[] 
     total_videosets = Videoset.find(:all,:conditions =>["country is not null"],:select => "country")
       total_videosets.each do |videoset| 
         if  !list.include?("'"+videoset.country+"'")
         list.push("'"+videoset.country+"'")
         end
       end    
       if !list.blank?      
       @countries = Location.find(:all, :conditions => ["name in (#{list.join(",")})"]) 
         else
       @countries = nil
       end  
     end  
     
     
end
