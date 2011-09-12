class Myworld::LatestController < ApplicationController

  before_filter :user_profile_info 
  before_filter :left_top_adv,:left_bottom_adv,:right_adv


  layout 'myworld'
  
  
def posts
    screenname = params[:id].gsub('_', ' ')
    @user = User.find_by_screen_name(screenname)     
     if @user
       @page_title = "#{@user.screen_name} - Latest Adventures"
       @latest = @user.latest_adventures.paginate :page => params[:page], :per_page => 5
     end
    rescue
    flash[:notice] = 'Some thing went wrong!!'
    render :template => 'shared/error'and return      
end



end
