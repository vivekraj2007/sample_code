class Admin::ReviewsController < ApplicationController
  before_filter :authorize_admin
  layout 'admin'
  
  def index
     page = params[:page].blank? ? 1 : params[:page]
    @reviews = Review.paginate :per_page=>5, :page=>page,:order=>"created_on DESC"  
  end
  def details
   @review  = Review.find(params[:id])
 end 
  
  
    def change_permalink
   @review =  Review.find(:all)
     for review in @review
      review.permalink = nil
      review.update_attributes(params[:review])
    end
  end
   # End ------- To change the permalink for all the reviews #
  
  
       
     def change_geolocations
       review = Review.find(params[:id])
       if !review.blank?
           if !review.lat.blank? and !review.longt.blank?
               country_place = Country.get_address_state(review.lat,review.longt,'review')
               if country_place == nil
               render :text => "Unable to find address"   and return 
               else  
              review.where = Country.composite_address(country_place)
              review.location = country_place[2]
              review.country= country_place[3]
              review.state= country_place[4]
              review.continent= country_place[5]
              review.update_attributes(params[:review])
              end
          else 
          render :text => "lat and longt blank"    and return 
        end
        else
          render :text => "review not found"    and return 
        end  
end 
   
end
