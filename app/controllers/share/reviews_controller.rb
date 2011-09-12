class Share::ReviewsController < ApplicationController
  before_filter :authorize_user
  before_filter :user_information
   layout 'home',:except =>[:map,:edit_map]
  
  
  
  #index page for the review to add new review and edit review
  def index
    cart_reset_all
    @review = Review.new
  end
  
  
    def map      
    
   if request.post?     
         find_cart      
     if !params[:lat].blank? && !params[:longt].blank?
                    country_place = Country.get_address_state(params[:lat],params[:longt],'review')
                    inlat =  params[:lat]
                    inlong =  params[:longt]
    elsif !params[:location].blank?   
                  gg = GoogleGeocode.new "ABQIAAAAVoAlk6p9spXkKKCobYyalBRze0qnd8claLFqBbJJqRHNIHp5uBS0EvSI9Bbvn6y41ZqIP-URI-Ortg"
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
      @cart.loct=Country.composite_address(country_place)
      @cart.location=country_place[2]
      @cart.country=country_place[3]
      @cart.state=country_place[4]
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
    
  rescue
      reset_cart
      flash[:notice] = 'unknown address'
      render :action => 'map', :layout => false  
  end
  
    
  
  #method to display the title, description, and location in the index page with the added location from google map.
   def set_location
    find_cart     
     @review = Review.new
    render :action => 'index'
  end
  
  
#method to display the title, description, and location in the index page with the edit location from google map.
   def edit_location
    find_cart     
    id = @cart.cat_id   
     @review = @user_profile.reviews.find_by_permalink(id)
     if @review
        render :action => 'edit_review'
     else
      flash[:notice] = "You have no access to view this review"  
      redirect_to :action => 'index'and return
    end   
  end  
  
  
   #method to edit map location   
  def edit_map
    find_cart
    @cart.lat = nil
    @cart.longt  = nil
    @cart.loct  = nil
    @cart.location=nil
    @cart.country=nil
    @cart.continent=nil
    @cart.state=nil
    render :action => 'map'
  end
  
#method to add new review    
  def new_review
  if request.post?
   @review = Review.new(params[:review])
   @review.user_id = session[:user_id] unless session[:user_id].blank?
   @review.created_on = Time.now
   @review.updated_on = Time.now      
    if @review.save!
      link_set = Linkset.create!(:source_id=>@review.id, :source_type => 'review')   
      cart_reset_all    
     flash[:notice] =" New Review was successfully added"
     redirect_to :action=> :add_tag, :id => @review.permalink
   else
       flash[:notice] ="Unable to add new Review"
       render :action=> 'index'
  end     
  else
       redirect_to :action=> 'index'  
  end 
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return        
end

  #method to edit exixting review
  def edit_review
    
    if request.post?      
       @review_id = params[:id]
        if @review_id.blank?       
          @review = @user_profile.reviews.find_by_permalink(params[:reviewedit])
        else
         @review  =  @user_profile.reviews.find_by_permalink(params[:review_id])
       end      
   new_cart
   @cart.lat = @review.lat
   @cart.longt  = @review.longt
   @cart.loct  = @review.where
   @cart.map_title = @review.title
   @cart.map_subt = @review.description  
   
   
   else
     flash[:notice] = "Please select review"
     redirect_to :action => "index"
   end  
   
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return      
  end
  
  
  def update_review    
      if request.post?
      @review = @user_profile.reviews.find_by_permalink(params[:id])
          if @review
                @review.updated_on = Time.now 
                @review.permalink=nil          
                       if  @review.update_attributes(params[:review])
                       flash[:notice] ="Review was successfully updated"
                        redirect_to :action=>'add_tag', :id => @review.permalink
                      else
                       flash[:notice] = "Unable to edit Review" 
                       render :action => 'edit_review'
                      end
                   
           else
                flash[:notice] = "You have no access to view this review"  
                 redirect_to :action => 'index'and return 
           end 
       else
         flash[:notice] = "Please select review"
         redirect_to :action => "index"           
       end  
  #~ rescue
  #~ flash[:notice] = 'Some thing went wrong!!'
  #~ render :template => 'shared/error'and return  
    
end
  
#method to add tag for review.
def add_tag
  @review = @user_profile.reviews.find_by_permalink(params[:id])
  if @review  
        if request.post?   
             @review.updated_on = Time.now 
            if @review.update_attributes(params[:review])
              linkset =  Linkset.add_linkset(@review.id,'review',params[:linkset])
              flash[:notice] ="Tag was successfully added to review"
              redirect_to :action => 'publish', :id => @review.permalink
            else
             flash[:notice] ="Unable to add tag to this Review"
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
      
 
 #method to publish the review.
  
  def publish
   @review = @user_profile.reviews.find_by_permalink(params[:id])  
   if @review
        if request.post?                        
                    @review.slideshow_id =params[:photoslideshow]
                    @review.updated_on = Time.now     
                   
                                 if params[:story_submit] == "Publish"  
                          @review.status = 1
                           image_splitted_content = grapimage_tag(params[:review][:how_was_it],"<img src=\"../../../photo/image/") 
                           added_images_id  = grapimage_id(image_splitted_content)          
                           
                          video_splitted_content = grapimage_tag(params[:review][:how_was_it],"<img src=\"../../../video/videofile/") 
                          added_video_id  = grapimage_id(video_splitted_content)             
                           @review.added_images = added_images_id 
                           @review.added_videos = added_video_id 
                           
                           else
                           @review.status = 0  
                           
                        end

                       if @review.update_attributes(params[:review]) 
                              if params[:story_submit] == "Publish"  
                            flash[:notice] ="Review was successfully published."
                            redirect_to :action => 'index'and return 
                            else
                            flash[:notice] ="Review was successfully saved"
                            end
                      
                      else
                            flash[:notice] ="Unable to save this Review"
                      end
                   
                 end      
   else
      flash[:notice] ="You have no access to view this page"
      redirect_to :action => 'index'                  
    end
    
    
  end  


  
   # private methods
   
    private  
  
    def cart_reset_all
    @cart = session[:cart] = nil
   end
  
    def find_cart
    @cart = session[:cart] ||= Cart.new
    end
  
    def new_cart
    @cart = session[:cart] = Cart.new  
    end
  
    def reset_cart    
          @cart.lat = nil
          @cart.longt  = nil
          @cart.loct  = nil
          @cart.location=nil
          @cart.country=nil
          @cart.continent = nil
          @cart.state=nil
    end
  
   def grapimage_tag(content,content_type)       
      fsplitcontent =  content.split(content_type)
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
