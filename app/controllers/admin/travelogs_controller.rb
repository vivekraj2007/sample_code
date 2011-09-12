class Admin::TravelogsController < ApplicationController
  before_filter :authorize_admin
  layout 'admin'
  
  def index
     page = params[:page].blank? ? 1 : params[:page]
    @travelogs = Travelog.paginate :per_page=>5, :page=>page,:order=>"created_on DESC"  
  end
  def details
   @travelogs  = Travelog.find(params[:id])
 end 
  
  
    def change_permalink
   @travelog =  Travelog.find(:all)
     for travelog in @travelog
      travelog.permalink = nil
      travelog.update_attributes(params[:travelog])
    end
  end
   # End ------- To change the permalink for all the travelogs #
  
  
       
     def change_geolocations
       travelog = Travelog.find(params[:id])
       if !travelog.blank?
           if !travelog.lat.blank? and !travelog.longt.blank?
               country_place = Country.get_address_state(travelog.lat,travelog.longt,'travelog')
               if country_place == nil
               render :text => "Unable to find address"   and return 
               else  
              travelog.where = Country.composite_address(country_place)
              travelog.location = country_place[2]
              travelog.country= country_place[3]
              travelog.state= country_place[4]
              travelog.continent= country_place[5]
              travelog.update_attributes(params[:travelog])
              end
          else 
          render :text => "lat and longt blank"    and return 
        end
        else
          render :text => "travelog not found"    and return 
        end  
end 
   
end
