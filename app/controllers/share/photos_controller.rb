require 'rubygems'
require 'google_geocode'


class Share::PhotosController < ApplicationController
before_filter :authorize_user
before_filter :user_information  
layout 'home'
  
  
  
  # index page to add new photoset and to edit the existing photoset.
  def index 
     @page_title = "Share - Photoset - Create new photoset"       
     @photoset = Photoset.new   
  end  



  #method to add new photoset.
  def new_photoset
    
  if request.post?
    
    @photoset = Photoset.new(params[:photoset])
    @photoset.user_id = session[:user_id] unless session[:user_id].blank?
    @photoset.created_on = Time.now
    @photoset.updated_on = Time.now

    if @photoset.save!
    photoset_adv = PhotosetAdv.create!(:photoset_id=>@photoset.id)
    link_set = Linkset.create!(:source_id=>@photoset.id, :source_type => 'photoset')
    flash[:notice] = "New photoset - '#{@photoset.title}' successfully created" 
    redirect_to :action => 'add_photo_to_set', :id => @photoset.permalink 
    else
    flash[:notice] = "Unable to add new photoset" 
    render :action => 'index'
   end

  else
   flash[:notice] = "Unable to add new photoset" 
   redirect_to :action => 'index'  
 end  
 
    rescue
    flash[:notice] = 'Some thing went wrong!!'
    render :template => 'shared/error'and return 
  end  


#method to edit existing photoset

def edit_photoset
  @page_title = "Share - Photoset - Edit photoset"    
  if request.post?
  @photoset = @user_profile.photosets.find_by_permalink(params[:photoset])
  else
   flash[:notice] = "Please select a photoset."  
   redirect_to :action => 'index' 
  end  
 
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return 
end


#method to update the edited details for the photoset

def update_photoset  
  @photoset = @user_profile.photosets.find_by_permalink(params[:id])
  #@photoset = @user_profile.photosets.find(:first, :conditions => ["user_id like ? AND permalink like ?",session[:user_id],params[:id]])
  if request.post?
    @photoset.updated_on = Time.now 
    @photoset.permalink = nil
      if  @photoset.update_attributes(params[:photoset])
      flash[:notice] = "Photoset details successfully updated"   
      redirect_to :action =>  "add_photo_to_set" , :id => @photoset.permalink
      else
      flash[:notice] = "Unable to edit photoset details" 
      render :action => 'edit_photoset'
    end
  else
   flash[:notice] = "Please select a photoset to edit."     
   redirect_to :action => 'index' 
 end
 
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return  
end  


#method to display the photos and providing option to add new photos to photoset

def add_photo_to_set
  @page_title = "Share - Photoset - Add photo to set"
  if !params[:id].blank?
  @photoset = @user_profile.photosets.find_by_permalink(params[:id])  
  #@photoset = Photoset.find(:first, :conditions => ["user_id like ? AND permalink like ?",session[:user_id],params[:id]])
  @photo =  Photo.new   
  if @photoset.blank?
 flash[:notice] = "Unknown photoset"
 redirect_to :action => 'index'     
  end  
 else
 flash[:notice] = "Please select a photoset to add photos."
 redirect_to :action => 'index' 
 end 
 
 
  rescue
  flash[:notice] = "You didn't have access to view this page."
  render :template => 'shared/error'and return  
end  



#method to add photos to photo set
def add_photo   
    @photoset = @user_profile.photosets.find_by_permalink(params[:id])   
   #render :text =>@photoset.id and return 
 if !@photoset.blank?   
      if request.post? 
             if !params[:file_0].blank?
              first_photo = upload_image(params[:file_0],@photoset)
             end    
             if !params[:file_1].blank?
              second_photo=  upload_image(params[:file_1],@photoset)
             end  
             if !params[:file_2].blank?
              third_photo =  upload_image(params[:file_2],@photoset)
            end   
           if !params[:file_3].blank?
          fourth_photo=  upload_image(params[:file_3],@photoset)
         end  
         if !params[:file_4].blank?
          fifth_photo =  upload_image(params[:file_4],@photoset)
         end            

             if first_photo == "unsaved" || second_photo== "unsaved" || third_photo == "unsaved" || fourth_photo == "unsaved" || fifth_photo == "unsaved"
                 flash[:notice] = "Unable to add some of these photos to photoset" 
                 render :action => 'add_photo_to_set'and return  
             else
                linkset =  Linkset.add_linkset(@photoset.id,'photoset',params[:linkset])
                flash[:notice] = "Photo was successfully added to photoset - ' #{@photoset.title}'" 
                redirect_to :action => 'add_photo_to_set', :id => @photoset.permalink and return  
               # render :text => "Photo was successfully added to photoset - ' #{@photoset.title}'" 
             end

    else
             linkset =  Linkset.add_linkset(@photoset.id,'photoset',params[:linkset])  
             flash[:notice] = "Link set was successfully updated." 
             redirect_to :action => 'add_photo_to_set', :id => @photoset.permalink and return   
             #render :text => "Link set was successfully updated"  
    end  
           
   else
        flash[:notice] = "Please select a photoset to add photos."
         redirect_to :action => 'index'   and return 
   end    
  rescue
   flash[:notice] = "Unable to add photo to photoset" 
   render :template => 'shared/error'and return 
  
end 


#method created for testing the image upload using swfupload

 #~ def imag_upload
  #~ if params[:Filedata]
   #~ @photo = Photo.new(:swfupload_file => params[:Filedata])
   #~ @photoset = Photoset.find(1)
   #~ #@photo = Photo.new(params[:photo])
   #~ @photo.photoset_id = @photoset.id
   #~ @photo.created_on= Time.now
   #~ @photo.updated_on= Time.now
   #~ @photo.save!
   #~ end
   #~ end
   
   
   
   
#method to find location lat and long from google map.

def add_tag
  @page_title = "Share - Photoset - Add Geo locations to photoset"
  if !params[:id].blank?
  @photoset = @user_profile.photosets.find_by_permalink(params[:id])  
  #@photoset = Photoset.find(:first, :conditions => ["user_id like ? AND permalink like ?",session[:user_id], params[:id]])
  else
  flash[:notice] = "Please select a photoset to add tag."
  redirect_to :action => 'index'   and return 
 end  
  if @photoset.blank?
  flash[:notice] = "You have no access to view this Photoset"
  redirect_to :action => 'index' and return 
  end
  rescue
  flash[:notice] = "You didn't have access to view this page"
  render :template => 'shared/error'and return  
 
end  


 #method commented after using the contry, state and location saving procress
  #~ def update_taglocation 
    #~ @set= Photoset.find(:all, :conditions => ["user_id LIKE ?", session[:user].id]) 
    #~ @photoset = Photoset.find(:first, :conditions => ["user_id like ? AND id like ?",session[:user].id,params[:id]])
    #~ @photoset.updated_on = Time.now
      #~ if  @photoset.update_attributes(params[:photoset])
      #~ flash[:notice] = "Tag and Location was successfully updated for photoset - '#{@photoset.title}'"
      #~ redirect_to :action => "add_photo_to_set", :id =>  @photoset.id
      #~ else
      #~ flash[:notice] = "Unable to add tag location to this photoset"   
      #~ render :action =>  "add_photo_to_set", :id =>  @photoset.id
    #~ end 
  #~ rescue
  #~ flash[:notice] = 'Some thing went wrong!!'
  #~ render :template => 'shared/error'and return  
#~ end 
    
    
  def display_geo_location  
    @page_title = "Share - Photoset - Add Geo locations to photoset"
   #~ @t1 = Thread.new {
  begin
    if request.post? 
          @photoset = @user_profile.photosets.find_by_permalink(params[:id])
           raw_photos = params[:photo]
          if !raw_photos.blank?
              raw_photos.each do |row, item|
              pht = Photo.find(item[:id])
              pht.title = item[:title]
              pht.caption = item[:caption]
              pht.tags = item[:tags]
              if params[:photoset][:coverimage_id] == item[:id]
              pht.is_cover = 1
              else
              pht.is_cover = 0  
              end
              pht.update_attributes(params[:pht]) 
            end
          end   
          # conditions to find country and place for the given lat and longt   
          if !params[:photoset][:lat].blank? && !params[:photoset][:longt].blank?
            country_place = Country.get_address_state(params[:photoset][:lat],params[:photoset][:longt],'photoset')
            #render :text => country_place.inspect and return 
            inlat = params[:photoset][:lat]
            inlong =  params[:photoset][:longt]     
         elsif !params[:photoset][:address].blank?   
                gg = GoogleGeocode.new "ABQIAAAAVoAlk6p9spXkKKCobYyalBRze0qnd8claLFqBbJJqRHNIHp5uBS0EvSI9Bbvn6y41ZqIP-URI-Ortg"
                locations = gg.locate(params[:photoset][:address])  
                if !locations.latitude.blank? &&  !locations.longitude.blank?
                    country_place = Country.get_address_state(locations.latitude,locations.longitude,'photoset') 
                    #render :text => country_place.inspect and return 
                    inlat = locations.latitude
                    inlong = locations.longitude
                 end   
        else    
              flash[:notice] = "Unable to modified photoset details"
              render :action => 'add_tag' and return           
        end
 
      if country_place == nil
              flash[:notice] = "Unable to modified photoset details"
              render :action => 'add_tag' and return  
      else
               if @photoset.location.blank? && @photoset.location != country_place[2] 
                  params[:photoset][:lat]=country_place[0]
                  params[:photoset][:longt]=country_place[1]
              else
                 params[:photoset][:lat]=inlat
                  params[:photoset][:longt]=inlong
              end
            @photoset.location=country_place[2] # location
            @photoset.country=country_place[3] #country
            @photoset.state=country_place[4]#state
            @photoset.continent=country_place[5] # continent
      end  
    
  if params[:photoset][:coverimage_id].blank? 
    default_coverimage = Photo.find(:first, :conditions => ["photoset_id LIKE ?",@photoset.id])
      if !default_coverimage.blank?
        @photoset.coverimage_id = default_coverimage.id
      end
  end   
    
        
        if @photoset.update_attributes(params[:photoset])                  
                    if !@photoset.lat.blank? && !@photoset.longt.blank?
                       flash[:notice] = "Photoset details successfully modified"  
                       render :action => 'add_tag' and return
                     else
                       flash[:notice] = "Unable to modify photoset details"
                       render :action => 'add_tag' 
                     end
         else
                       flash[:notice] = "Unable to modify photoset details"
                       render :action => 'add_tag' 
        end
 else
   flash[:notice] = "Please select a photoset"
    redirect_to :action => "index" 
 end  
  rescue #Exception => e
  flash[:notice] = "Unable to modify photoset details"
  render :action => 'add_tag' and return  
end

#end
end



#method to delet photo
def delete_photo
@photo =   @user_profile.photos.find(params[:id])
if !@photo.blank? 
    if @photo.photoset.coverimage_id == @photo.id    
          coverphoto = Photo.find(:first, :conditions => ["photoset_id LIKE ? and id != ?",@photo.photoset_id,@photo.id],:select => ["id"])
              if !coverphoto.blank?
              @photo.photoset.coverimage_id = coverphoto.id
              else 
              @photo.photoset.coverimage_id =""          
              end
          @photo.photoset.update_attributes(params[:photoset])            
        end  
        
        
    for story in @user_profile.stories
        if !story.added_images.blank?      
             if story.added_images.include?("#{@photo.id}")
             story.update_attributes(:added_images => story.added_images.delete("#{@photo.id}"))
             end   
      end   
    end         
     
  for review in @user_profile.reviews
        if !review.added_images.blank?            
             if review.added_images.include?("#{@photo.id}")
            review.update_attributes(:added_images => review.added_images.delete("#{@photo.id}"))
             end       
        end   
    end
    
         for travelog in @user_profile.travelogs
        if !travelog.added_images.blank?
                
             if travelog.added_images.include?("#{@photo.id}")
            travelog.update_attributes(:added_images => travelog.added_images.delete("#{@photo.id}"))
             end
        end   
    end
 
        
@photo.destroy
flash[:notice] = "Photo(s) successfully deleted"
redirect_to :action => 'add_photo_to_set', :id => @photo.photoset.permalink and return 
else 
  flash[:notice] = "you have no access to delete this photo" 
  redirect_to :action => 'index'
end

#~ @photo = Photo.find(params[:id])
#~ @photoset = Photoset.find(:first, :conditions => ["user_id like ? AND id like ?",session[:user_id],@photo.photoset_id])

#~ if !@photoset.blank?
       #~ if @photo.id == @photoset.coverimage_id
      #~ @photoset.update_attributes(:coverimage_id => 0)
     #~ end 
#~ @photo.destroy
#~ flash[:notice] = "Photos was successfully deleted from photoset"
#~ else
#~ flash[:notice] = "you have no access to delete this photo" 
#~ end

#~ redirect_to :action => 'add_photo_to_set', :id => @photoset.permalink and return  

 #~ rescue
  #~ flash[:notice] = 'Access denied'
   #~ render :template => 'shared/error'and return  

end  




def send_invitation
   flash[:notice] = ""
@photoset = @user_profile.photosets.find_by_permalink(params[:id])
if request.post?
  user = User.find(session[:user_id],:select => "first_name,email,id,screen_name,last_name")   
  sendername = user.first_name.to_s + " " + user.last_name.to_s 
  url = photopermalink_url(:continent => check_content(@photoset.continent),:country => check_content(@photoset.country), :state => check_content(@photoset.state), :location => check_content(@photoset.location),:id => @photoset.permalink) 
  
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
                                          :subject => "Photo's invitaion",
                                          :message => "#{user.screen_name} has Invited you to view his photos.<br/><br/> Click on the below URL to view this Photos.<br/<br/>. <a href='#{url}' target='blank' class='story_view12'>#{url}</a>"
                                            } 
                                          if UserMail.create(user_message)
                                          @sucess_count = @sucess_count+1  
                                          @sent_invitations.push(emails[count])                        
                                         end  
                                  else
                                   @user_itself = "You can’t send invitation to your self"    
                                  end       
                  else
                                 for_user = emails[count].gsub(/ /,'')
                                  if for_user   != user.email  
                                        if for_user.match(email_exp)                 
                                                begin 
                                                Emailer.deliver_photos_invitation(for_user,sendername,url)
                                                #Emailer.deliver_photos_invitation(for_user,user.first_name,url)
                                                @sucess_count = @sucess_count+1
                                                @sent_invitations.push(for_user)  
                                              end  
                                        end                          
                                 else
                                       @user_itself = "You can’t send invitation to your self" 
                                 end              
                end 
             
      end
      count = count+1
      @message = "#{@sucess_count} invitation(s) sent."
  end

end

end

# method to delete photoset 
def delete_photoset
   @photoset = @user_profile.photosets.find_by_permalink(params[:id])
   deleted = Photoset.forced_delete(@photoset)
   @photoset.destroy
   flash[:notice] = "Photoset was successfully deleted."
   redirect_to :action => 'index'  
 end
 
 private 
 def check_content(content)
   if !content.blank?
     return content.gsub(/\?/,'-')
  end
end
 
def  upload_image(image,photoset)
    photo = Photo.new
    photo.image = image
    photo.photoset_id = photoset.id
      if photo.save  
        return "saved"
      else 
        return "unsaved"
      end 
  end
 
end
