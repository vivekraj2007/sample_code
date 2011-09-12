class StoriesController < ApplicationController
  before_filter :authorize_user  
  layout 'home'
  
  
  #method to display stories index page
  def index
    if request.post?
    @story = Story.find(params[:story])       
    else
    @story = Story.find(:first, :conditions =>["user_id LIKE ?",session[:user_id]], :order => "updated_at DESC")
    end
  end  
  
  def search
   search_word = params[:search]
   @story = Story.find(:first, :conditions => ["user_id like ? and (title like ? or sub_title like ? or where_is like ? or tag like ?)",session[:user_id],search_word,search_word,search_word,search_word])   
   if @story
    flash[:notice] = "Your search for '  #{search_word} ' found story ' #{@story.title.humanize} '"    
   else
     @search_result = "no result"
    flash[:notice] = "Your search for ' #{search_word} ' found no result"    
   end
    render :action => 'index'
  end  
  def test

  end

  
end
