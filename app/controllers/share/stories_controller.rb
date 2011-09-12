require 'rubygems'
require 'google_geocode'
require 'mechanize'

class Share::StoriesController < ApplicationController
  
    before_filter :authorize_user
    before_filter :user_information
    layout 'home', :except =>[:map,:edit_map]
    
    
  #~ def test
  #~ render :text => request.host
  #~ end
    
  #index page for the stories to add new storie and edit storie
  def index
    @page_title = "Share - Story - Create new story"   
    #cart_reset_all
   @story = Story.new
 end
 
 
 #method to display Google map to locate location for story.

  def map      
    
   if request.post?     
         find_cart      
     if !params[:lat].blank? && !params[:longt].blank?
                    country_place = Country.get_address_state(params[:lat],params[:longt],'story')
                    #render :text => country_place.inspect and return 
                    inlat =  params[:lat]
                    inlong =  params[:longt]
    elsif !params[:location].blank?   
                  gg = GoogleGeocode.new "ABQIAAAALHXVqR3ivZP4lPuASHGUbRRxI6gS_yiE9yY2PwSnUHXXLgJkihRW61pIbuWHVb-9kU-NwqDke2W2iw"
                  locations = gg.locate(params[:location])  
                  if !locations.latitude.blank? && !locations.longitude.blank?
                    country_place = Country.get_address_state(locations.latitude,locations.longitude,'story')  
                     inlat= locations.latitude
                     inlong  = locations.longitude
                   end
    else
                 flash[:notice] = 'unknown address'
                 render :action => 'map', :layout => false    
    end  


    if country_place == nil
       flash[:notice] = 'unknown address'
       render :action => 'map', :layout => false    
    else
       if @cart.loct.blank? && @cart.loct  != country_place[2] 
          @cart.lat=country_place[0]
          @cart.longt=country_place[1]
        else
          @cart.lat=inlat
          @cart.longt=inlong
        end    
      @cart.loct = Country.composite_address(country_place)
      @cart.location = country_place[2]
      @cart.country = country_place[3]
      @cart.state = country_place[4]
      @cart.continent = country_place[5]
    end         


    else
        
        if params[:cat_id]
         find_cart 
         @cart.bpage = params[:bpage]
         @cart.cat_id=params[:cat_id]
         @cart.map_title = params[:title]
         @cart.map_subt = params[:sub_title]
         else           
         new_cart
         @cart.map_title = params[:title]
         @cart.map_subt = params[:sub_title]
         @cart.bpage = params[:bpage]
         @cart.cat_id=params[:cat_id]
         end
         
      end
    
  #~ rescue
      #~ reset_cart
      #~ flash[:notice] = 'unknown address'
      #~ render :action => 'map', :layout => false  
  end
    
    
  #method to display the title, sub title, and location in the index page with the added location from google map.
   #~ def set_location
     #~ @page_title = "Share - Story - Create new story"  
    #~ find_cart     
     #~ @story = Story.new
     #~ render :action => 'index'
  #~ end
  
  
    #method to display the title, sub title, and location in the index page with the edit location from google map.
   #~ def edit_location
     #~ @page_title = "Share - Story - Edit story"  
    #~ find_cart     
    #~ id = @cart.cat_id
     #~ @story = @user_profile.stories.find_by_permalink(id)
     #~ if @story
      #~ render :action => 'edit_story' 
     #~ else
      #~ flash[:notice] = "You have no access to view this story"  
      #~ redirect_to :action => 'index'and return
     #~ end   
  #~ end  
  
  
 #method to edit map location   
  #~ def edit_map
    #~ find_cart
    #~ @cart.lat = nil
    #~ @cart.longt  = nil
    #~ @cart.loct  = nil
    #~ @cart.location=nil
    #~ @cart.country=nil
    #~ @cart.continent=nil
    #~ @cart.state=nil
    #~ render :action => 'map'
#~ end

  #method to add new story    
 def new_story    
      if request.post?
         @story = Story.new(params[:story])  
         @story.user_id = session[:user_id] unless session[:user_id].blank?
         find_cart  
         if !params[:story][:lat].blank? && !params[:story][:longt].blank?
                        country_place = Country.get_address_state(params[:story][:lat],params[:story][:longt],'story')
                        #~ render :text => country_place and return
                        inlat = params[:story][:lat]
                        inlong =  params[:story][:longt]   
          elsif !params[:story][:where_is].blank?   
                  gg = GoogleGeocode.new "ABQIAAAAVoAlk6p9spXkKKCobYyalBRze0qnd8claLFqBbJJqRHNIHp5uBS0EvSI9Bbvn6y41ZqIP-URI-Ortg"
                  locations = gg.locate(params[:story][:where_is])  
                  if !locations.latitude.blank? && !locations.longitude.blank?
                    country_place = Country.get_address_state(locations.latitude,locations.longitude,'story')  
                     inlat= locations.latitude
                     inlong  = locations.longitude
                   end
          else
                 flash[:notice] = 'unknown address'
                 render :action => 'index'
          end
               
    if country_place == nil
                     flash[:notice] = 'unable to find address'
                     render :action => 'add_geo_locations'
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
    end
    
               
          @story.lat=inlat
          @story.longt=inlong            
        

        @story.created_at = Time.now
         @story.updated_at = Time.now
          if @story.save!
          story_adv = StoryAdv.create!(:story_id=>@story.id)
          link_set = Linkset.create!(:source_id=>@story.id, :source_type => 'story')
          #~ cart_reset_all
          flash[:notice] ="New Story was successfully added"
          #~ redirect_to :action=> :add_tag, :id => @story.permalink
           redirect_to :action=> :edit_story,:id => @story.permalink
         else
          flash[:notice] ="Unable to add new Story"
          render :action=> :index
        end    
    else
          redirect_to :action=> 'index'  
    end  
    rescue
    flash[:notice] = 'Some thing went wrong!!'
    render :template => 'shared/error'and return        
end 


#method to add tag for story.
def add_tag
  @story = @user_profile.stories.find_by_permalink(params[:id])
    if @story
            if request.post?   
               @story.updated_at = Time.now
               if @story.update_attributes(params[:story])
                  linkset =  Linkset.add_linkset(@story.id,'story',params[:linkset])
                  flash[:notice] ="Tag was successfully added to story"
                  redirect_to :action => 'add_tag', :id => @story.permalink and return
              else
                  flash[:notice] ="Unable to add tag to this Story"
                  render :action => 'add_tag' and return
              end
            end  
    else
      flash[:notice] ="You have no access to view this page"
      redirect_to :action => 'index'
    end     
   rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return      
end  
  
 #method to publish the story.
  
  def publish    
   @story = @user_profile.stories.find_by_permalink(params[:id])
  if @story 
          if request.post? 
              @story.slideshow_id = params[:photoslideshow]
              @story.updated_at = Time.now    

                image_splitted_content = grapimage_tag(params[:story][:write_it_with_images],"<img src=\"../../../photo/image/")
                added_images_id  = grapimage_id(image_splitted_content)                      
                image_splitted_content= grapcontent_without_images(params[:story][:write_it_with_images],"<img src=") 
                   
               video_splitted_content = grapimage_tag(params[:story][:write_it_with_images],"<img src=\"../../../video/videofile/") 
               added_video_id  = grapimage_id(video_splitted_content)             
               @story.added_images = added_images_id 
               @story.added_videos = added_video_id 
               @story.write_it = image_splitted_content.join('')      
               
               #render :text => image_splitted_content and return 
               #render :text => image_splitted_content.join('') and return 
               #added_images_id  = graptext(image_splitted_content)                        
                   
                 
           
                if params[:story_submit] == "Publish"  
                  @story.status = 1
               else
                   @story.status = 0  
                  # @story.write_it = params[:story][:write_it_with_images]
                end

               if @story.update_attributes(params[:story]) 
                    if params[:story_submit] == "Publish"   
                    flash[:notice] ="Story was successfully published."      
                    redirect_to :action => 'send_invitation', :id => @story.permalink   
                    else
                    flash[:notice] ="Story was successfully saved"
                    render :action => 'publish' 
                    end
                
              else
                    flash[:notice] ="Unable to save this Story"
              end
           
         end     

   else
       flash[:notice] ="You have no access to view this page"
       redirect_to :action => 'index'
  end
  end  
  
  
  #method to edit exixting story
  def edit_story
   @story_id = params[:id]    
   
   if @story_id.blank?
    @story =  @user_profile.stories.find_by_permalink(params[:storyedit])
    else
    @story =  @user_profile.stories.find_by_permalink(@story_id)
   end
  
   #~ new_cart
   #~ @cart.lat = @story.lat
   #~ @cart.longt  = @story.longt
   #~ @cart.loct  = @story.where_is
  #~ @cart.location=@story.location
  #~ @cart.country=@story.country
  #~ @cart.state=@story.state   
  #~ @cart.continent=@story.continent   
  #~ @cart.map_title = @story.title
  #~ @cart.map_subt = @story.sub_title
  rescue 
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return      
  end
  
  
  def update_story     
     if @story = @user_profile.stories.find_by_permalink(params[:id])       
           if request.post?

#~ sarma 22_01_09
        find_cart  
         if !params[:story][:lat].blank? && !params[:story][:longt].blank?
                        country_place = Country.get_address_state(params[:story][:lat],params[:story][:longt],'story')
                        #~ render :text => country_place and return
                        inlat = params[:story][:lat]
                        inlong =  params[:story][:longt]   
          elsif !params[:story][:where_is].blank?   
                  gg = GoogleGeocode.new "ABQIAAAAVoAlk6p9spXkKKCobYyalBRze0qnd8claLFqBbJJqRHNIHp5uBS0EvSI9Bbvn6y41ZqIP-URI-Ortg"
                  locations = gg.locate(params[:story][:where_is])  
                  if !locations.latitude.blank? && !locations.longitude.blank?
                    country_place = Country.get_address_state(locations.latitude,locations.longitude,'story')  
                     inlat= locations.latitude
                     inlong  = locations.longitude
                   end
          else
                 flash[:notice] = 'unknown address'
                 redirect_to :action=>'edit_story', :id => @story.permalink,:value => 'add'and return
          end
               
            if country_place == nil
                     flash[:notice] = 'unable to find address'
                    redirect_to :action=>'edit_story', :id => @story.permalink,:value => 'add'and return
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
           end
                       @story.lat=inlat
                       @story.longt=inlong            

#~ sarma 22_01_09

                       @story.updated_at = Time.now 
                       @story.title = params[:story][:title]
                       @story.sub_title = params[:story][:sub_title]
                       #~ render :text =>   params.inspect and return
                       @story.permalink=nil
                           if  @story.update_attributes(params[@story])
                                flash[:notice] ="Story was successfully updated"
                                redirect_to :action=>'edit_story', :id => @story.permalink and return
                           else
                                flash[:notice] = "Unable to edit Story" 
                                render :action => 'edit_event'
                         end          
                  end
            else
                  flash[:notice] ="You have no access to view this page"
                  redirect_to :action => 'index'     
            end   
            rescue
                  flash[:notice] = 'Some thing went wrong!!'
                  render :template => 'shared/error'and return  
end
  
  # method to delete story
def delete_story
  @story = @user_profile.stories.find_by_permalink(params[:id])
  if @story
  @story.destroy
    flash[:notice] = "Story was successfully deleted."
    redirect_to :action => 'index'  
   else
     flash[:notice] = "You have no access to delete this story"
     redirect_to :action => 'index'  
     end
 end
 
 
 #method to send inviatation to users to view story
     
def send_invitation
  @story = @user_profile.stories.find_by_permalink(params[:id])
if request.post?
  user = User.find(session[:user_id],:select => "first_name,email,id,screen_name,last_name")   
  sendername = user.first_name.to_s + " " + user.last_name.to_s 
  url = storypermalink_url(:continent => check_content(@story.continent),:country => check_content(@story.country), :state => check_content(@story.state), :location => check_content(@story.location),:id => @story.permalink) 
  
  total_invitations = params[:invitation].gsub(/, /,',')
  emails = total_invitations.split(',')
  
  count = 0 
  @sucess_count = 0
  email_exp = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
  @sent_invitations = Array.new
  
  
 emails.size.times do   
        
      if !@sent_invitations.include?("#{emails[count]}")

         
          invited_friends = User.find(:first, :conditions => ["screen_name LIKE ?",emails[count]], :select => 'id,email,screen_name')
                  if !invited_friends.blank?
                    
                                   if invited_friends.email != user.email                          
                                           user_message = {
                                          :from_user => user.id, 
                                          :to_user => invited_friends.id,
                                          :date_sent => Time.now,
                                          :subject => "Stories invitaion",
                                          :message => "#{user.screen_name} has Invited you to view his Story.<br/><br/> Click on the below URL to view this Story.<br/<br/>. <a href='#{url}' target='blank' class='story_view12'>#{url}</a>"
                                            } 
                                          if UserMail.create(user_message)
                                          @sucess_count = @sucess_count+1  
                                          @sent_invitations.push(emails[count])                        
                                         end  
                                  else
                                   @user_itself = "You can’t send invitation to your self "    
                                  end       
                  else
                                 for_user = emails[count].gsub(/ /,'')
                                  if for_user   != user.email  
                                        if for_user.match(email_exp)                 
                                                begin 
                                                Emailer.deliver_story_invitation(for_user,sendername,url)
                                                @sucess_count = @sucess_count+1
                                                @sent_invitations.push(for_user)  
                                              end  
                                        end                          
                                 else
                                       @user_itself = "You can’t send invitation to your self " 
                                 end              
                end 
             
      end
      count = count+1
      @message = "#{@sucess_count} invitation(s) sent."
  end

end
end

  
  def cart_reset
    @cart = session[:cart] = nil
  end
  
  private  
  
  def cart_reset_all
    @cart = session[:cart] = nil    
  end
  
   def new_cart
    @cart = session[:cart] = Cart.new  
   end
  
  
  def reset_cart
    #@cart = session[:cart] = nil
          @cart.lat = nil
          @cart.longt  = nil
          @cart.loct  = nil
          @cart.location=nil
          @cart.country=nil
          @cart.continent = nil
          @cart.state=nil
    end
  
    def find_cart
    @cart = session[:cart] ||= Cart.new  
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

     def check_content(content)
   if !content.blank?
     return content.gsub(/\?/,'-')
  end
   end




   
      
   
end
