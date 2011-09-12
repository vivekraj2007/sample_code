class VideosController < ApplicationController
  
   before_filter :authorize_user  
  layout 'home'
  
  
    #method to display videos index page
  def index   
    
    page = params[:page].blank? ? 1 : params[:page]
   @videosets = Videoset.paginate :per_page=>4, :page=>page, :conditions => ["user_id like ?",session[:user_id]],:order=>"updated_on DESC"

     if params[:id].blank?
    @index_videoset = Videoset.find(:first, :conditions => ["user_id like ?", session[:user_id]], :order => "updated_on DESC")
        else
    @index_videoset = Videoset.find(:first, :conditions => ["user_id like ? AND id LIKE ?", session[:user_id],params[:id]], :order => "updated_on DESC")  
  end
  
  end
    def video
    videoset_id = params[:vdst_id]
   @index_videoset = Videoset.find(videoset_id)
   @video_display = Video.find(params[:id]) 
   render :layout => false
 end 
 
 
 
end
