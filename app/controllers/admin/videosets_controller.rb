class Admin::VideosetsController < ApplicationController
  before_filter :authorize_admin
  layout 'admin'
  def index
     page = params[:page].blank? ? 1 : params[:page]
    @videoset = Videoset.paginate :per_page=>5, :page=>page,:order=>"created_on DESC"  
  end
  
  def details
   @videoset  = Videoset.find_by_permalink(params[:id])
   @videos = Video.find(:all,:conditions => ["videoset_id LIKE ?",@videoset.id])
 end 
 
 def show
    @video = Video.find(params[:id])
    render :layout => false
  end
  
   # To change the permalink for all the photosets #
  def change_permalink
   @videoset =  Videoset.find(:all)
   for videoset in @videoset
      videoset.permalink = nil
      videoset.update_attributes(params[:videoset])
   end
  end
 # End ------- To change the permalink for all the photosets #
  
    def forced_delete
    videoset = Videoset.find_by_permalink(params[:id])
    deleted = Videoset.forced_delete(videoset)
    videoset.destroy
    flash[:notice] = "Videoset was sucessfully deleted."
    redirect_to :action => 'index'
  end 
  
  
  
     def change_geolocations
       videoset = Videoset.find(params[:id])
       if !videoset.blank?
           if !videoset.lat.blank? and !videoset.longt.blank?
               country_place = Country.get_address_state(videoset.lat,videoset.longt,'videoset')
               if country_place == nil
               render :text => "Unable to find address"   and return 
               else  
              videoset.location = country_place[2]
              videoset.country= country_place[3]
              videoset.state= country_place[4]
              videoset.continent= country_place[5]
              videoset.update_attributes(params[:videoset])
              end
          else 
          render :text => "lat and longt blank"    and return 
        end
        else
          render :text => "videoset not found"    and return 
        end  
end 
  
 
end
