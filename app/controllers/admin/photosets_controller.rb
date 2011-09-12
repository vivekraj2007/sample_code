require 'rubygems'
require 'google_geocode'


class Admin::PhotosetsController < ApplicationController
  before_filter :authorize_admin
  before_filter :user_information
  layout 'admin'
  
  
  def index
    page = params[:page].blank? ? 1 : params[:page]
    sort = case params['sort']
   when "title"  then "title"  
   when "screen_name" then "users.screen_name"
   when "created_on" then "created_on"
   when "status" then "lat"
   when "title_reverse"  then "title DESC"
   when "screen_name_reverse"  then "users.screen_name DESC"
   when "created_on_reverse"  then "created_on DESC"
   when "status_reverse" then "lat DESC"  
  end     
    
   sort = sort.blank? ? "created_on DESC" : sort
  if !params[:search].blank?
  condition = ["	users.screen_name like ? or title like ? or tag like ? or photosets.continent like ? or photosets.country like ? or photosets.state like ?", "%"+params[:search]+"%",params[:search],"%"+params[:search]+"%",params[:search],params[:search],params[:search]]
  else
  condition = ""
  end        
    @photoset = Photoset.paginate :per_page=>25, :page=>page,:conditions => condition,:order => sort, :include => "user" 
  end
  
  # To display the details of photoset #
  def details
    #permalink = params[:id]+".html"
   @photoset  = Photoset.find_by_permalink(params[:id])
   @photos = Photo.find(:all,:conditions => ["photoset_id LIKE ?",@photoset.id])
  end 
 
 
 def edit
   @photoset = Photoset.find_by_permalink(params[:id])
 end
 
def update

   @photoset = Photoset.find_by_id(params[:id])
   @photoset.updated_on = Time.now
   if @photoset.update_attributes(params[:photoset])
       flash[:notice] = 'Photoset details was successfully updated'
      redirect_to :action => 'edit', :id => @photoset.permalink
    else
       flash[:notice] = 'Unable to update'
      render :action => 'edit',:id => @photoset.permalink
    end
  end
  
def edit_photos
        @photoset = Photoset.find_by_id(params[:id])
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

      if @photoset.update_attributes(params[:photoset])
            flash[:notice] = 'Update photos successfully'
            redirect_to :action => 'edit',:id => @photoset.permalink and return
      else
            flash[:notice] = 'Unable to update photos'
            redirect_to :action => 'edit',:id => @photoset.permalink and return
      end
  
end

def edit_geo_location  
  
 if request.post?
          @photoset = Photoset.find_by_id(params[:id])
        
         if !params[:photoset][:lat].blank? && !params[:photoset][:longt].blank?
             country_place = Country.get_address_state(params[:photoset][:lat],params[:photoset][:longt],'photoset')
            #~ render :text => country_place.inspect and return 
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
              flash[:notice] = "Unable to find Geo-location"
              redirect_to :action => 'edit',:id => @photoset.permalink and return           
        end
 
     if country_place == nil
              flash[:notice] = "Unable to find Geo-location"
              redirect_to :action => 'edit',:id => @photoset.permalink and return 
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
            @photoset.state=country_place[4] #state
            @photoset.continent=country_place[5] # continent
      end  
    
     if @photoset.update_attributes(params[:photoset])                  
                    if !@photoset.lat.blank? && !@photoset.longt.blank?
                       flash[:notice] = "Geo-location details successfully updated"  
                      redirect_to :action => 'edit',:id => @photoset.permalink and return
                     else
                       flash[:notice] = "Unable to find Geo-location"
                      redirect_to :action => 'edit',:id => @photoset.permalink 
                     end
         else
                       flash[:notice] = "Unable to find Geo-location"
                       redirect_to :action => 'edit',:id => @photoset.permalink
        end
    else
                     flash[:notice] = "Please select a photoset"
                      redirect_to :action => 'edit',:id => @photoset.permalink 
    end  
  
  rescue #Exception => e
  flash[:notice] = "Unable to find Geo-location"
  redirect_to :action => 'edit',:id => @photoset.permalink and return  


end


#method to delete photo
def delete_photo
@photo =  Photo.find(params[:id])
@photoset = @photo.photoset


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
                  
                  
              for story in @photo.photoset.user.stories
                  if !story.added_images.blank?      
                       if story.added_images.include?("#{@photo.id}")
                       story.update_attributes(:added_images => story.added_images.delete("#{@photo.id}"))
                       end   
                end   
              end         
           
          @photo.destroy
          flash[:notice] = "Photo(s) successfully deleted"
          redirect_to :action => 'edit', :id => @photoset.permalink and return 
else 
        flash[:notice] = "Unable to delete photo from photoset" 
        redirect_to :action => 'edit', :id => @photoset.permalink
end

end  






 # To change the permalink for all the photosets #
  def change_permalink
   @photoset =  Photoset.find(:all)
   for photoset in @photoset
      photoset.permalink = nil
      photoset.update_attributes(params[:photoset])
   end
  end
 # End ------- To change the permalink for all the photosets #
   
   def change_geolocations
       photoset = Photoset.find(params[:id])
       if !photoset.blank?
           if !photoset.lat.blank? and !photoset.longt.blank?
               country_place = Country.get_address_state(photoset.lat,photoset.longt,'photoset')
               if country_place == nil
               render :text => "Unable to find address"   and return 
               else  
              photoset.location = country_place[2]
              photoset.country= country_place[3]
              photoset.state= country_place[4]
              photoset.continent= country_place[5]
              photoset.update_attributes(params[:photoset])
              end
          else 
          render :text => "lat and longt blank"    and return 
        end
        else
          render :text => "photoset not found"    and return 
        end  
end     
  
   #~ def add_advertisement
    #~ @photoset = Photoset.find(params[:id])  
    #~ @adv = PhotosetAdv.find_by_photoset_id(@photoset)
    #~ if !params[:headeradv_id].blank?
       #~ @photoset.updated_on = Time.now
       #~ if @adv.update_attributes(:headeradv_id => params[:headeradv_id] )
       #~ flash[:notice] = 'Advertisement was sucessfully added to this photoset'
       #~ else
      #~ flash[:notice] = 'Unable to add Advertisement to this photoset'   
       #~ end      
    #~ end  
  #~ end  
   
  #~ def delete_advertisement
    #~ @photoset = Photoset.find(params[:id])  
    #~ @adv = PhotosetAdv.find_by_photoset_id(@photoset)
    #~ @photoset.updated_on = Time.now
           #~ if @adv.update_attributes(:headeradv_id => 0 )
           #~ flash[:notice] = 'Advertisement was sucessfully deleted for this photoset'     
           #~ else
          #~ flash[:notice] = 'Unable to delete Advertisement to this photoset'   
        #~ end  
      #~ redirect_to :action => 'add_advertisement', :id => @photoset.id       
  #~ end  
  
  
def add_advertisement
    @photoset = Photoset.find(params[:id]) 
    @default_ad_top = DefaultAd.find(10)
    #@default_ad_top = DefaultAd.find(:first, :select => "coalesce(advertisement_id, 0) as add_id", :conditions => ["id = ?", 2])
   #~ render :text => @default_ad_top.adv_id, :layout => false and return
   @default_ad_left_top = DefaultAd.find(11)
   @default_ad_left_bottom = DefaultAd.find(12)
   @default_ad_right = DefaultAd.find(13)
   
    @adv = PhotosetAdv.find_by_photoset_id(@photoset)

   end  
  
  #~ 11-feb-09
  
  def adv_save
     @photoset = Photoset.find(params[:id])
     @adv = PhotosetAdv.find_by_photoset_id(@photoset)
     #~ render :text => params.inspect, :layout => false and return
      @adv.headeradv_id = params[:adv][:headeradv_id]
      @adv.topadv_id =  params[:adv][:topadv_id]
      @adv.bottomadv_id =  params[:adv][:bottomadv_id]
      @adv.rightadv_id = params[:adv][:rightadv_id]
      if @adv.update_attributes(params[@adv])
           flash[:notice] = 'Advertisement was sucessfully added to this photoset'
           redirect_to :action => 'index'
      else
          flash[:notice] = 'Advertisement was sucessfully added to this photoset'
           redirect_to :action => 'add_advertisement',:id => @photoset.id
      end
    
  end
  
  #~ 11-feb-09
  
def save_adv
 @photoset = Photoset.find(params[:id]) 
 @adv = PhotosetAdv.find_by_photoset_id(@photoset)
       if params[:position]=='header'      
           @adv.headeradv_id = params[:adv_id]
           @adv.update_attributes(params[:adv])
           flash[:notice] = 'Advertisement was sucessfully added to this photoset'
           redirect_to :action => 'add_advertisement', :id => @photoset.id
      elsif params[:position]=='left_top'
#~ render :text => params[:adv_id], :layout => false and return        
           @adv.topadv_id= params[:adv_id]
           @adv.update_attributes(params[:adv])
           flash[:notice] = 'Advertisement was sucessfully added to this photoset'
           redirect_to :action => 'add_advertisement', :id => @photoset.id
      elsif params[:position]=='left_bottom'       
           @adv.bottomadv_id= params[:adv_id]
           @adv.update_attributes(params[:adv])
           flash[:notice] = 'Advertisement was sucessfully added to this photoset' 
            redirect_to :action => 'add_advertisement', :id => @photoset.id   
      elsif params[:position]=='right'       
           @adv.rightadv_id= params[:adv_id]
           @adv.update_attributes(params[:adv])
           flash[:notice] = 'Advertisement was sucessfully added to this photoset' 
            redirect_to :action => 'add_advertisement', :id => @photoset.id               
      end 
end  
  
  
  
  def delete_adv
    @photoset = Photoset.find(params[:id])  
    @adv = PhotosetAdv.find_by_photoset_id(@photoset)
    @photoset.updated_on = Time.now
    
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
          flash[:notice] = 'Advertisement was sucessfully deleted for this photoset'     
           else
          flash[:notice] = 'Unable to delete Advertisement to this photoset'   
          end  
      redirect_to :action => 'add_advertisement', :id => @photoset.id       
  end  
   
  
  def add_adv
    @photoset =  Photoset.find(:all)
     for photoset in @photoset
    photoset_adv = PhotosetAdv.create!(:photoset_id=>photoset.id)
     end
    
  end  
  
   def forced_delete
    photoset = Photoset.find_by_permalink(params[:id])
    deleted = Photoset.forced_delete(photoset)
    photoset.destroy
    flash[:notice] = "Photoset was sucessfully deleted."
    redirect_to :action => 'index'
  end
  
def add_to_lateslist
       photosets = Photoset.find(:all) 
         if !photosets.blank?
             for photoset in photosets
                   if !photoset.lat.nil? && !photoset.longt.nil?
                     latest_list = LatestAdventure.add_to_list(photoset.id,'photoset',photoset.user_id)
                   end     
             end
           
         end  
 end  
 
end
