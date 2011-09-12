class See::StoriesController < ApplicationController
  
  before_filter :user_information 
  before_filter :left_top_adv,:left_bottom_adv,:right_adv
  layout 'see'
  
   def index
    if session[:user_id].blank? 
      layout_map
    end
    @page_title = "Stories"   
    select = "continent, country, state, location, permalink, title, sub_title, created_at, write_it,added_images "
    if !params[:search_by].blank?
         @place = params[:search_by]
         @page_title = "Stories - #{params[:search_by]}"
         conditions = ["lat is not null and longt is not null and country LIKE ? AND status LIKE ?",params[:search_by],1] 
         @see_stories = Story.paginate :page => params[:page], :per_page => 6, :select => select, :conditions => conditions,:order => 'updated_at DESC'
         @total =  @see_stories.total_entries    
    else
       conditions = ["lat is not null and longt is not null and status LIKE ?",1]
       @see_stories = Story.paginate :page => params[:page], :per_page => 6, :select => select, :conditions => conditions, :order => 'updated_at DESC'
       @total =  @see_stories.total_entries 
     end
      @countries = Story.find(:all, :select => "DISTINCT country as name", :conditions =>["lat IS NOT NULL AND longt IS NOT NULL AND country IS NOT NULL"], :order => "country DESC")
  end   

end
