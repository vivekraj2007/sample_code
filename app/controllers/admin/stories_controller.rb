require 'rubygems'
require 'google_geocode'
require 'mechanize'

class Admin::StoriesController < ApplicationController
  before_filter :authorize_admin
  before_filter :user_information
  layout 'admin'
  
  
  def index
     page = params[:page].blank? ? 1 : params[:page]
   sort = case params['sort']
   when "title"  then "title"  
   when "screen_name" then "users.screen_name"
   when "created_at" then "created_at"
   when "status" then "status"
   when "title_reverse"  then "title DESC"
   when "screen_name_reverse"  then "users.screen_name DESC"
   when "created_at_reverse"  then "created_at DESC"
   when "status_reverse"  then "status DESC"
 end  
 
   
   sort = sort.blank? ? "stories.created_at DESC" : sort
    if !params[:search].blank?
        condition = [	"users.screen_name like ? or title like ? or sub_title like ? or tag like ? or stories.continent like ? or stories.country like ? or stories.state like ? or stories.location like ?", "%"+params[:search]+"%","%"+params[:search]+"%",params[:search],params[:search],params[:search],params[:search],params[:search],params[:search]]
    else
        condition = ""
    end   
    
    
    @stories = Story.paginate :per_page=>25, :page=>page,:conditions => condition,:order => sort, :include => "user"
  end
 
 def details
   @story  = Story.find_by_permalink(params[:id])
   @story_comments = @story.story_comments.find(:all)
 end 
 
 def edit
   @story = Story.find_by_permalink(params[:id])
 end
 
  
    
 def update
   @story = Story.find(params[:id])
   @story.updated_at = Time.now
   if @story.update_attributes(params[:story])
       flash[:notice] = 'Story details was successfully updated.'
      redirect_to :action => 'edit', :id => @story.permalink
    else
      flash[:notice] = 'Unable to update'
      render :action => 'edit',:id => @story.permalink
    end
  end
  

def edit_geo_location  
   @story = Story.find(params[:id])
   if request.post?
         if !params[:story][:lat].blank? && !params[:story][:longt].blank?
                        country_place = Country.get_address_state(params[:story][:lat],params[:story][:longt],'story')
                        #~ render :text => country_place.inspect and return 
                        inlat = params[:story][:lat]
                        inlong =  params[:story][:longt]     
                   elsif !params[:story][:where_is].blank?   
                          gg = GoogleGeocode.new "ABQIAAAAVoAlk6p9spXkKKCobYyalBRze0qnd8claLFqBbJJqRHNIHp5uBS0EvSI9Bbvn6y41ZqIP-URI-Ortg"
                          locations = gg.locate(params[:story][:where_is])  
                                  if !locations.latitude.blank? && !locations.longitude.blank?
                                      country_place = Country.get_address_state(locations.latitude,locations.longitude,'story')  
                                      inlat = locations.latitude
                                      inlong =  locations.longitude
                                  end   
                else    
                          flash[:notice] = 'Please specify Address or Geo-coord'
                          redirect_to :action => 'edit',:id => @story.permalink and return           
                end
              
            if country_place == nil
                     flash[:notice] = 'unable to find address'
                      redirect_to :action => 'edit',:id => @story.permalink and return   
            else
                     if @story.location.blank? && @story.location  != country_place[2] 
                        @story.lat=country_place[0]
                        @story.longt=country_place[1]
                      else
                        @story.lat=inlat
                        @story.longt=inlong
                      end    
                      #@story.loct = Country.composite_address(country_place)
                      @story.location = country_place[2]
                      @story.country = country_place[3]
                      @story.state = country_place[4]
                      @story.continent = country_place[5]
                      @story.where_is = country_place[2] + ', '+country_place[4] + ', '+country_place[3]
                      
                     if @story.update_attributes(params[@story])
                           flash[:notice] ="GEO locations was successfully updated."      
                           redirect_to :action => 'edit',:id => @story.permalink and return   
                     else
                           flash[:notice] = 'unknown address'
                            redirect_to :action => 'edit',:id => @story.permalink and return
                    end   
              end      
   end
  #~ rescue #Exception => e
  #~ flash[:notice] = "unknown address"
  #~ render :action => 'add_geo_locations' and return  
end  


def publish
     @story = Story.find(params[:id])
  if @story 
          if request.post? 
              @story.slideshow_id = params[:photoslideshow]
              @story.updated_at = Time.now       
           
                if params[:story_submit] == "Publish"  
                  @story.status = 1
                   image_splitted_content = grapimage_tag(params[:story][:write_it_with_images],"<img src=\"../../../photo/image/")
                   added_images_id  = grapimage_id(image_splitted_content)                      
                   
                   image_splitted_content= grapcontent_without_images(params[:story][:write_it_with_images],"<img src=") 
                   
                   
                   #render :text => image_splitted_content and return 
                   #render :text => image_splitted_content.join('') and return 
                   #added_images_id  = graptext(image_splitted_content)                        
                   
                  video_splitted_content = grapimage_tag(params[:story][:write_it_with_images],"<img src=\"../../../video/videofile/") 
                  added_video_id  = grapimage_id(video_splitted_content)             
                   @story.added_images = added_images_id 
                   @story.added_videos = added_video_id 
                  @story.write_it = image_splitted_content.join('')               
                   
                   
                   else
                   @story.status = 0  
               end

               if @story.update_attributes(params[:story]) 
                    if params[:story_submit] == "Publish"   
                    flash[:notice] ="Story was successfully published."      
                    redirect_to :action => 'edit', :id => @story.permalink and return
                    else
                    flash[:notice] ="Story was successfully saved"
                    redirect_to :action => 'edit', :id => @story.permalink  and return
                    end
                
              else
                    flash[:notice] ="Unable to save this Story"
              end
           
         end     

   else
       flash[:notice] ="You have no access to view this page"
       redirect_to :action => 'edit', :id => @story.permalink and return
  end
  
  
  
end

  
  def status
     @story = Story.find(params[:id])
     @story.status = params[:status]
     if @story.update_attributes(params[:story])
      redirect_to params[:url]
    end
  end   
  
  
  
  def add_advertisement
    @story = Story.find(params[:id]) 
    @default_ad_top = DefaultAd.find(2)
    #@default_ad_top = DefaultAd.find(:first, :select => "coalesce(advertisement_id, 0) as add_id", :conditions => ["id = ?", 2])
   #~ render :text => @default_ad_top.adv_id, :layout => false and return
   @default_ad_left_top = DefaultAd.find(3)
    @default_ad_left_bottom = DefaultAd.find(4)
    @default_ad_right = DefaultAd.find(5)
    
    
    @adv = StoryAdv.find_by_story_id(@story)

   end  
  
  #~ 11-feb-09
  
  def adv_save
     @story = Story.find(params[:id])
     @adv = StoryAdv.find_by_story_id(@story)
     #~ render :text => params.inspect, :layout => false and return
      @adv.headeradv_id = params[:adv][:headeradv_id]
      @adv.topadv_id =  params[:adv][:topadv_id]
      @adv.bottomadv_id =  params[:adv][:bottomadv_id]
      @adv.rightadv_id = params[:adv][:rightadv_id]
      if @adv.update_attributes(params[@adv])
           flash[:notice] = 'Advertisement was sucessfully added to this story'
           redirect_to :action => 'index'
      else
          flash[:notice] = 'Advertisement was sucessfully added to this story'
           redirect_to :action => 'add_advertisement',:id => @story.id
      end
    
  end
  
  #~ 11-feb-09
  
def save_adv
 @story = Story.find(params[:id]) 
 @adv = StoryAdv.find_by_story_id(@story)
       if params[:position]=='header'      
           @adv.headeradv_id = params[:adv_id]
           @adv.update_attributes(params[:adv])
           flash[:notice] = 'Advertisement was sucessfully added to this story'
           redirect_to :action => 'add_advertisement', :id => @story.id
      elsif params[:position]=='left_top'
#~ render :text => params[:adv_id], :layout => false and return        
           @adv.topadv_id= params[:adv_id]
           @adv.update_attributes(params[:adv])
           flash[:notice] = 'Advertisement was sucessfully added to this story'
           redirect_to :action => 'add_advertisement', :id => @story.id
      elsif params[:position]=='left_bottom'       
           @adv.bottomadv_id= params[:adv_id]
           @adv.update_attributes(params[:adv])
           flash[:notice] = 'Advertisement was sucessfully added to this story' 
            redirect_to :action => 'add_advertisement', :id => @story.id   
      elsif params[:position]=='right'       
           @adv.rightadv_id= params[:adv_id]
           @adv.update_attributes(params[:adv])
           flash[:notice] = 'Advertisement was sucessfully added to this story' 
            redirect_to :action => 'add_advertisement', :id => @story.id               
      end 
end  
  
  
  
  def delete_adv
    @story = Story.find(params[:id])  
    @adv = StoryAdv.find_by_story_id(@story)
    @story.updated_at = Time.now
    
  if params[:position]=='header'      
       @adv.headeradv_id = nil
   elsif params[:position]=='left_top'       
       @adv.topadv_id= nil
   elsif params[:position]=='left_bottom'       
       @adv.bottomadv_id= nil 
  elsif params[:position]=='right'       
       @adv.rightadv_id= nil   
  end  
      if @adv.update_attributes(params[:adv])
          flash[:notice] = 'Advertisement was sucessfully deleted for this story'     
           else
          flash[:notice] = 'Unable to delete Advertisement to this story'   
          end  
      redirect_to :action => 'add_advertisement', :id => @story.id       
  end  
  
  #~ def edit_advertisement
   #~ sort = case params['sort']
   #~ when "sponser_name"  then "sponser_name"  
   #~ when "created_at" then "created_at"
   #~ when "status" then "status"
   #~ when "sponser_name_reverse"  then "sponser_name DESC"
   #~ when "created_at_reverse"  then "created_at DESC"
   #~ when "status_reverse"  then "status DESC"
 #~ end  
  
  
    #~ page = params[:page].blank? ? 1 : params[:page]
  
    #~ if !params[:id].blank?
      #~ condition = ["parient_id LIKE ?",params[:id]]
      #~ @adv = Advertisement.paginate :per_page=>5, :page=>page,:conditions => condition,:order => sort
   #~ end
#~ end
  
  
  
  def delete
    Story.find_by_permalink(params[:id]).destroy
    flash[:notice] = "Story was successfully deleted."
    redirect_to :action => 'index'
  end
  
  def add_adv
    @story =  Story.find(:all)
     for story in @story
    story_adv = StoryAdv.create!(:story_id=>story.id)
     end
    
  end  
  
  
  
  
  # To change the permalink for all the stories #
  def change_permalink
   @story =  Story.find(:all)
     for story in @story
      story.permalink = nil
      story.update_attributes(params[:story])
    end
  end
   # End ------- To change the permalink for all the stories #
   
     
     def change_geolocations
       story = Story.find(params[:id])
       if !story.blank?
           if !story.lat.blank? and !story.longt.blank?
               country_place = Country.get_address_state(story.lat,story.longt,'story')
               if country_place == nil
               render :text => "Unable to find address"   and return 
               else  
              story.where_is = Country.composite_address(country_place)
              story.location = country_place[2]
              story.country= country_place[3]
              story.state= country_place[4]
              story.continent= country_place[5]
              story.update_attributes(params[:story])
              end
          else 
          render :text => "lat and longt blank"    and return 
        end
        else
          render :text => "story not found"    and return 
        end  
 end 
   
   
   # method to extract images from description and store the images less content in another field
   
   
   def change_writeit
     stories = Story.find(:all)
     for story in stories
     if !story.write_it.blank?
       story.write_it_with_images = story.write_it
      image_splitted_content = Story.grapimage_tag(story.write_it,"<img src=\"../../../photo/image/")
      added_images_id  = Story.grapimage_id(image_splitted_content) 
      
    video_splitted_content = Story.grapimage_tag(story.write_it,"<img src=\"../../../video/videofile/") 
    added_video_id  = Story.grapimage_id(video_splitted_content)   
    story.added_images = added_images_id 
    story.added_videos = added_video_id     
      
      
      image_splitted_content= Story.grapcontent_without_images(story.write_it,"<img src=")       
      
      story.write_it = image_splitted_content.join('')
      story.update_attributes(params[:story])
    end
    end
     end
   
   
   
   def add_to_lateslist
      stories = Story.find(:all)
         if !stories.blank?
             for story in stories
                   if !story.lat.nil? && !story.longt.nil? && story.status == 1
                     latest_list = LatestAdventure.add_to_list(story.id,'story',story.user_id)
                   end     
             end
           
         end  
 end  
   
   
    def grapcontent_without_images(content,content_type)       
      fsplitcontent =  content.split(content_type)
    #return  fsplitcontent 
      count = 0  
      ssplitcontent = Array.new      
       for fs in fsplitcontent
           if count != 0
                mmsplit = Array.new 
                mmsplit <<  fsplitcontent[count].split('" />')
                 if !mmsplit[0][1].nil?
                     ssplitcontent << mmsplit[0][1]   
                 end
           else         
                ssplitcontent <<  fsplitcontent[count]  
           end             
          count = count+1
        end
      return ssplitcontent       
    end 
  
  def graptext(content)
       count = 0
     fplit = Array.new
      for fs in content
        fplit << content[count][0].split('/')
        count = count+1
      end      
      images_id = Array.new
       for imageid in fplit     
         if  !images_id.include?(imageid)
         images_id << imageid
        end   
     end          
     if images_id.size == 0
     return nil    
     else
      return images_id.join(',')   
       end
     end 
  
   
   
   def grapimage_tag(content,content_type)       
      fsplitcontent =  content.split(content_type)
     # return  fsplitcontent 
      count = 0  
      ssplitcontent = Array.new 
       for fs in fsplitcontent
           if count != 0
           ssplitcontent <<  fsplitcontent[count].split('/')
           end  
          count = count+1
        end
       return ssplitcontent        
    end 
  
       def grapimage_id(content)
     count = 0
     fplit = Array.new
      for fs in content
        fplit << content[count][0].split('/')
        count = count+1
      end      
      images_id = Array.new
       for imageid in fplit     
         if  !images_id.include?(imageid)
         images_id << imageid
        end   
     end          
     if images_id.size == 0
     return nil    
     else
      return images_id.join(',')   
       end
     end   
   
   
end
