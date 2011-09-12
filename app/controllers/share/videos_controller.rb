require 'google_geocode'
require 'fileutils'
require 'RMagick'

class Share::VideosController < ApplicationController
  before_filter :authorize_user
  before_filter :user_information
  layout 'home'

         

  
  def index
  @videoset = Videoset.new
  end

#method to add new videoset.

def new_videoset
  if request.post?
      @videoset = Videoset.new(params[:videoset])
      @videoset.user_id = session[:user_id] unless session[:user_id].blank?
      @videoset.created_on = Time.now
      @videoset.updated_on = Time.now
          if @videoset.save
           link_set = Linkset.create!(:source_id=>@videoset.id, :source_type => 'videoset')
           flash[:notice] = "New videoset - '#{@videoset.title}' was successfully created" 
           redirect_to :action => 'add_video_to_set', :id => @videoset.permalink and return 
          else
           flash[:notice] = "Unable to add new videoset" 
           render :action => 'index'and return 
         end
  else
    flash[:notice] = "Unable to add new videoset" 
    redirect_to :action => 'index'  
  end
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return 
end 

#method to edit existing videoset
def edit_videoset  
  if request.post?
  @videoset = @user_profile.videosets.find_by_permalink(params[:videoset])  
  else
   flash[:notice] = "Please select a Videoset."  
   redirect_to :action => 'index' 
  end   
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return 
end


#method to update the edited details for the videoset
def update_videoset  
 @videoset = @user_profile.videosets.find_by_permalink(params[:id])
 if request.post?
 @videoset.updated_on = Time.now
 @videoset.permalink = nil
      if  @videoset.update_attributes(params[:videoset])
      flash[:notice] = "Videoset was successfully updated"   
      redirect_to :action =>  "add_video_to_set" , :id => @videoset.permalink
      else
      flash[:notice] = "Unable to edit this videoset" 
      render :action => 'edit_videoset'
     end
  else
   flash[:notice] = "Please select videoset"     
   redirect_to :action => 'index' 
  end
  rescue
  flash[:notice] = 'Unable to update this videoset'
  render :template => 'shared/error'and return  
end 


#method to display the videos and providing option to add new videos to videoset
def add_video_to_set
      if !params[:id].blank?
         @videoset = @user_profile.videosets.find_by_permalink(params[:id])
          if @videoset.blank?
          flash[:notice] = "Unknown videoset"
          redirect_to :action => 'index' and return   
          else   
          @video = Video.new  
          end   
      else
      flash[:notice] = "Please select videoset"
      redirect_to :action => 'index' and return   
      end  
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return  
end  



#method to add videos to video set
def add_video
   @videoset = @user_profile.videosets.find_by_permalink(params[:id])
   if request.post?
     if !params[:video][:videofile].blank?
           @video = Video.new(params[:video])
           @video.videoset_id = @videoset.id
           @video.created_on= Time.now
           @video.updated_on= Time.now      
                if @video.save
                  return_val = grab_screenshot_from_video(@video.id)
                   if return_val == "Unknown file"
                    flash[:notice] = "The video file you have uploaded is corrupted or it doesn't support video format. Please upload a correct video file" 
                    redirect_to :action => 'add_video_to_set', :id => @videoset.permalink and return  
                   end
                      linkset =  Linkset.add_linkset(@videoset.id,'videoset',params[:linkset])  
                      flash[:notice] = "Video was successfully added to videoset - ' #{@videoset.title}'" 
                    redirect_to :action => 'add_video_to_set', :id => @videoset.permalink and return  
                else
                   flash[:notice] = "Unable to add video to this videoset" 
                   render :action => 'add_video_to_set'and return  
                end    
       else
         linkset =  Linkset.add_linkset(@videoset.id,'videoset',params[:linkset])  
         flash[:notice] = "Link set was successfully updated." 
         redirect_to :action => 'add_video_to_set', :id => @videoset.permalink and return   
       end 
  else
        flash[:notice] = "Please select a videoset"
         redirect_to :action => 'index'   and return           
  end  
  #~ rescue
  #~ flash[:notice] = "Unable to add video to this videoset" 
  #~ render :template => 'shared/error'and return  
end 

def update_coverid
  videoset = Videoset.find(params[:id])
  videoset.update_attributes(:covervideo_id => " ")
  end

#method to find location lat and long from google map.
def add_tag
    if !params[:id].blank?      
      @videoset = @user_profile.videosets.find_by_permalink(params[:id])  
        if @videoset.blank?
        flash[:notice] = "Unknown videoset"
        redirect_to :action => 'index'   and return   
        end  
    else
      flash[:notice] = "Please select videoset"
      redirect_to :action => 'index'   and return 
    end
  rescue
  flash[:notice] = "You didn't have access to view this page"
  render :template => 'shared/error'and return  
end  




#method to display geo location in the google map
def display_geo_location
  
if request.post?   
      @videoset = @user_profile.videosets.find_by_permalink(params[:id])  
      @videosett = @user_profile.videosets.find_by_permalink(params[:id])  
      
  # conditions to find country and place for the given lat and longt
   
   if !params[:videoset][:lat].blank? && !params[:videoset][:longt].blank?
      country_place = Country.get_address_state(params[:videoset][:lat],params[:videoset][:longt],'videoset')
      #render :text => country_place.inspect and return 
      inlat = params[:videoset][:lat]
      inlong =  params[:videoset][:longt]     
  elsif !params[:videoset][:address].blank?   
          gg = GoogleGeocode.new "ABQIAAAAVoAlk6p9spXkKKCobYyalBRze0qnd8claLFqBbJJqRHNIHp5uBS0EvSI9Bbvn6y41ZqIP-URI-Ortg"
          locations = gg.locate(params[:videoset][:address])  
          if !locations.latitude.blank? && !locations.longitude.blank?
              country_place = Country.get_address_state(locations.latitude,locations.longitude,'videoset')  
              inlat = locations.latitude
              inlong =  locations.longitude
          end   
  else    
        flash[:notice] = 'Please specify Address or Geo-coord'
        render :action => 'add_tag' and return           
      end
      
      
      
      if country_place == nil
        flash[:notice] = 'Unable to find Geo locations for this address'
        render :action => 'add_tag' and return  
      else
       if @videosett.location.blank? && @videosett.location != country_place[2] 
      @videosett.lat=country_place[0]
      @videosett.longt=country_place[1]
      else
      @videosett.lat=inlat
      @videosett.longt=inlong
      end
      @videosett.location= country_place[2]
      @videosett.country = country_place[3]
      @videosett.state= country_place[4]
      @videosett.continent= country_place[5]
     end  
  @videosett.tag = params[:videoset][:tag]  
  
  
  if params[:videoset][:covervideo_id].blank?
    #default_coverimage = @videoset.videos.find(:first,:select =>"id")  
    #@videosett.covervideo_id = @user_profile.videos.find(:first,:select =>"id")
   vid = Video.find(:first, :conditions => ["videoset_id LIKE ?",@videoset.id])
     if !vid.blank?  
      @videosett.covervideo_id = vid.id
    end   
     
    else
    @videosett.covervideo_id = params[:videoset][:covervideo_id]
  end     
      
        raw_videos = params[:video]
           if !raw_videos.blank?
            raw_videos.each do |row, item|
            videod = Video.find(item[:id])
            videod.title = item[:title]
            videod.caption = item[:caption]
            videod.tags = item[:tags]
            if @videosett.covervideo_id == item[:id]
            videod.is_cover = 1
            else
            videod.is_cover = 0  
            end
            videod.update_attributes(params[:videod]) 
          end
          end
          @videosett.update_attributes(params[:videosett])
          @videoset = @user_profile.videosets.find_by_permalink(params[:id])  
          if !@videoset.lat.nil? && !@videoset.longt.nil?
             flash[:notice] = "Tag and GEO Location was Successfully added to set."
          render :action => 'add_tag' and return  
           else
          flash[:notice] = "Unable to add Tag and GEO Location to set."
          render :action => 'add_tag' and return  
          end
 else
  flash[:notice] = "Please select videoset"
  redirect_to :action => "index" and return  
 end  

#~ rescue
#~ flash[:notice] = 'unknown address'
#~ render :action => 'add_tag' and return  

end
# method to delete videoset
def delete_videoset
  @videoset = @user_profile.videosets.find_by_permalink(params[:id])
  deleted = Videoset.forced_delete(@videoset)
  @videoset.destroy     
   flash[:notice] = "Videoset was successfully deleted."
   redirect_to :action => 'index'  
 end
 
 
#method to delet video
def delete_video
  @video = @user_profile.videos.find(params[:id])  
  
   if  !@video.blank?

            
            if @video.videosets.covervideo_id == @video.id    
           covervideo = Video.find(:first, :conditions => ["videoset_id LIKE ? and id != ?",@video.videoset_id,@video.id],:select => ["id"])
           
              if !covervideo.blank?
           @video.videosets.update_attributes(:covervideo_id => covervideo.id)    
             else 
          @video.videosets.update_attributes(:covervideo_id => "")         
              end
            end  
            
            
         for story in @user_profile.stories
        if !story.added_videos.blank?      
             if story.added_videos.include?("#{@video.id}")
             story.update_attributes(:added_images => story.added_videos.delete("#{@video.id}"))
             end   
      end   
    end         
     
  for review in @user_profile.reviews
        if !review.added_videos.blank?            
             if review.added_videos.include?("#{@video.id}")
            review.update_attributes(:added_images => review.added_videos.delete("#{@video.id}"))
             end       
        end   
    end
    
         for travelog in @user_profile.travelogs
        if !travelog.added_videos.blank?                
             if travelog.added_videos.include?("#{@video.id}")
            travelog.update_attributes(:added_images => travelog.added_videos.delete("#{@video.id}"))
             end
        end   
    end   
 
          @user_profile.videos.find(params[:id]).destroy   
         flash[:notice] = "video was successfully deleted" 
        redirect_to :action => 'index'  
    else 
          flash[:notice] = "you have no access to delete this video" 
          redirect_to :action => 'index'
   end
 #~ rescue
 #~ flash[:notice] = 'Access denied'
 #~ render :template => 'shared/error'and return  

end 



def send_invitation
 @videoset = @user_profile.videosets.find_by_permalink(params[:id])  
 if @videoset
   if request.post?
    user = User.find(session[:user_id],:select => "first_name")
    url = videopermalink_url(:continent => check_content(@videoset.continent),:country => check_content(@videoset.country), :state => check_content(@videoset.state), :location => check_content(@videoset.location),:id => @videoset.permalink) 
    Emailer.deliver_videos_invitation(params[:invitation],user.first_name,url)
   @message = "Invitations has been sent."
  end
#~ else
  #~ flash[:notice] = "Unknown videoset"
  #~ redirect_to :action => "index"
end  
end

private

  def grab_screenshot_from_video(id)
   video = Video.find(id)   
   
   FileUtils.mkdir("./video/videofile/#{id}/main")   
   FileUtils.mkdir("./video/videofile/#{id}/thumb")   
   FileUtils.mkdir("./video/videofile/#{id}/flv_file")   
   FileUtils.mkdir("./video/videofile/#{id}/converted_img")
   
   
  begin 
   #system "ffmpeg -i #{full_filename} -r 25 -acodec mp3 -ar 22050 -y -s 320x240 #{full_filename}.flv"

   #-------------------method to convert video file to .flv file type-------------------------
   system "ffmpeg -i #{video.videofile} -ar 22050 -ab 64 -f flv -s 320×240 ./video/videofile/#{id}/flv_file/#{id}.flv"
   system "ffmpeg flvtool2 -U ./video/videofile/#{id}/flv_file"
   #--------------------------------------------
    
   #-------------------------------method to grap image from video---------------------
   system "ffmpeg -y -i #{video.videofile} -vframes 1 -ss 00:00:02 -an -vcodec png -f rawvideo -s 320×240 ./video/videofile/#{id}/converted_img/#{id}.png"
   #system "ffmpeg -i #{vimage.videofile} -s sqcif -vframes 1 -f image2 -an ./video/videofile/#{id}/main/#{id}.jpg"
   # system "ffmpeg -i #{vimage.videofile} -s sqcif -vframes 1 -f image2 -an ./video/videofile/#{id}/thumb/#{id}.jpg"
    
   video.update_attributes(:video_image => "#{id}.png")
   

   # to create main image and thumb image
   original_image   =  RAILS_ROOT + "/public/video/videofile/#{id}/converted_img/#{File.basename(video.video_image)}"
  
   main_image   =  RAILS_ROOT + "/public/video/videofile/#{id}/main/#{File.basename(video.video_image)}" 
   thumb_image   =  RAILS_ROOT + "/public/video/videofile/#{id}/thumb/#{File.basename(video.video_image)}" 
  
   #original_image   =  RAILS_ROOT + "/public/video/videofile/#{id}/main/#{id}.jpg"   
   #thumb_image  = RAILS_ROOT + "/public/video/videofile/#{id}/thumb/#{id}.jpg"
   
  
    image   = Magick::ImageList.new(original_image)    
    image   = image.change_geometry!('51x51!') { |c, r, i| i.resize!(c, r) } 
    image.write(thumb_image)
    
    image   = Magick::ImageList.new(original_image)   
    image   = image.change_geometry!('104x104!') { |c, r, i| i.resize!(c, r) } 
    image.write(main_image)   
    
    rescue Exception => e
    video.destroy
    return  "Unknown file"
    
    end
    
  end


 def check_content(content)
   if !content.blank?
     return content.gsub(/\?/,'-')
   end
   
end



  
end
