class See::PeopleController < ApplicationController
  
  before_filter :user_information 
  
  before_filter :left_top_adv,:left_bottom_adv,:right_adv
  
  layout 'see'
  
  
  def index
    
    if session[:user_id].blank? 
      layout_map
    end    
    @countries = Country.find( :all,  :select => "countries.name,countries.id, count(countries.name) as user_count ", :joins => "inner join users on users.country_id = countries.id and users.activated_at is not null", :group=>"countries.name", :order => "user_count desc, countries.name")
    
    
    if !params[:search_by].blank?
          @country_name = Country.find_by_id(params[:search_by],:select => "name")
          @page_title = "People - #{@country_name.name}"  
          if !session[:user_id].blank?
         conditions = ["activated_at is not null AND country_id LIKE ? AND id != ?",params[:search_by],session[:user_id]] 
         else
         conditions = ["activated_at is not null AND country_id LIKE ?",params[:search_by]]  
         end         
    else
         @page_title = "People" 
           if !session[:user_id].blank?
              conditions = ["activated_at is not null AND id != ?",session[:user_id]]
           else
             conditions = ["activated_at is not null"] 
           end 
    end    

       select = "id, screen_name,country_id"
       @user = User.paginate :page => params[:page], :per_page => 45, :select => select, :conditions => conditions, :order => "activated_at ASC "
       @total = @user.total_entries
  end
  

end
