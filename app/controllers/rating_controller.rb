class RatingController < ApplicationController

     
#method for saving rating details given by the clients in database
   
def rate 
    @story =   Story.find(params[:id])    
    @user = User.find(session[:user_id])
    @storyrating = StoryRating.new
    @storyrating.rating = params[:rating]
     @storyrating.user_id = @user.id
       @storyrating.story_id = @story.id
       @storyrating.save!
    #~ @storyrating.add_rating StoryRating.new(:rating => params[:rating], :user_id => @user.id,  :story_id => @story.id) 
    #~ @storyrating.rate=@storyrating.rating
    #~ if @storyrating.update_attributes(params[:storyrating])
    #~ end
    @x=0
end
            
  
  



   end
