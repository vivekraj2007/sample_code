class Share::TravelogsController < ApplicationController

  before_filter :authorize_user
  before_filter :user_information
  layout 'home',:except =>[:map,:edit_map]
  
  
  
  #index page for the travelog to add new travelog and edit review
  def index
    cart_reset_all
    @travelog = Travelog.new
  end
  
   #method to display Google map to locate location for travelogs

  def map      
    
   if request.post?     
         find_cart      
     if !params[:lat].blank? && !params[:longt].blank?
                  country_place = Country.get_address_state(params[:lat],params[:longt],'travelog')
                    inlat =  params[:lat]
                    inlong =  params[:longt]
     elsif !params[:location].blank?   
                  gg = GoogleGeocode.new "ABQIAAAAVoAlk6p9spXkKKCobYyalBRze0qnd8claLFqBbJJqRHNIHp5uBS0EvSI9Bbvn6y41ZqIP-URI-Ortg"
                  locations = gg.locate(params[:location])  
                  if !locations.latitude.blank? && !locations.longitude.blank?
                    country_place = Country.get_address_state(locations.latitude,locations.longitude,'travelog')  
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
  
    #method to display the title, sub title, and location in the index page with the added location from google map.
   def set_location
    find_cart     
     @travelog = Travelog.new
     render :action => 'index'
  end
  
    #method to display the title, sub title, and location in the index page with the edit location from google map.
   def edit_location
    find_cart     
    id = @cart.cat_id
     @travelog = @user_profile.travelogs.find_by_permalink(id)
     if @travelog
      render :action => 'edit_travelog' 
     else
      flash[:notice] = "You have no access to view this Travelog"  
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
  
  
    #method to add new travelog   
  def new_travelog    
      if request.post?
         @travelog = Travelog.new(params[:travelog])   
         @travelog.user_id = session[:user_id] unless session[:user_id].blank?
         @travelog.created_at = Time.now
         @travelog.updated_at = Time.now
          if @travelog.save!
         # story_adv = StoryAdv.create!(:story_id=>@story.id)
          link_set = Linkset.create!(:source_id=>@travelog.id, :source_type => 'travelog')
          cart_reset_all
          flash[:notice] ="New Travelog was successfully added"
          redirect_to :action=> :add_tag, :id => @travelog.permalink
         else
          flash[:notice] ="Unable to add new Travelog"
          render :action=> :index
        end    
    else
          redirect_to :action=> 'index'  
    end  
    #~ rescue
    #~ flash[:notice] = 'Some thing went wrong!!'
    #~ render :template => 'shared/error'and return        
end 
  
  
  
#method to add tag for travelog
def add_tag
  @travelog = @user_profile.travelogs.find_by_permalink(params[:id])
    if @travelog
            if request.post?   
               @travelog.updated_at = Time.now
               if @travelog.update_attributes(params[:travelog])
                  linkset =  Linkset.add_linkset(@travelog.id,'travelog',params[:linkset])
                  flash[:notice] ="Tag was successfully added to travelog"
                  redirect_to :action => 'publish', :id => @travelog.permalink
              else
                  flash[:notice] ="Unable to add tag to this Travelog"
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
  
  
    #method to publish the travelog
  
  def publish
  @travelog = @user_profile.travelogs.find_by_permalink(params[:id])
  if @travelog 
          if request.post?    
            
              @travelog.slideshow_id =params[:photoslideshow]
              @travelog.updated_at = Time.now       
           
                        if params[:story_submit] == "Publish"  
                  @travelog.status = 1
                   image_splitted_content = grapimage_tag(params[:travelog][:tellus],"<img src=\"../../../photo/image/") 
                   added_images_id  = grapimage_id(image_splitted_content)          
                   
                  video_splitted_content = grapimage_tag(params[:travelog][:tellus],"<img src=\"../../../video/videofile/") 
                  added_video_id  = grapimage_id(video_splitted_content)             
                   @travelog.added_images = added_images_id 
                   @travelog.added_videos = added_video_id 
                   
                   else
                   @travelog.status = 0  
                   
                end

               if @travelog.update_attributes(params[:travelog]) 
                           if params[:story_submit] == "Publish"  
                    flash[:notice] ="Travelog was successfully published."
                    redirect_to :action => 'index'and return 
                    else
                    flash[:notice] ="Travelog was successfully saved"
                    end
              
              else
                    flash[:notice] ="Unable to save this Travelog"
              end
           
         end     

   else
       flash[:notice] ="You have no access to view this page"
       redirect_to :action => 'index'
  end
  end  
  
  
   #method to edit exixting travelog
  def edit_travelog
    
    if request.post?
        @travelog =  @user_profile.travelogs.find_by_permalink(params[:travelogedit])      
   elsif !params[:id].blank?   
        @travelog =  @user_profile.travelogs.find_by_permalink(params[:id])
   else
    flash[:notice] = "Please select Travelog"
    redirect_to :action => 'index' and return 
   end
     new_cart
       @cart.lat = @travelog.lat
       @cart.longt  = @travelog.longt
       @cart.loct  = @travelog.where
      @cart.location=@travelog.location
      @cart.country=@travelog.country
      @cart.continent=@travelog.continent
      @cart.state=@travelog.state   
      @cart.map_title = @travelog.title
      @cart.map_subt = @travelog.description
  #~ rescue 
  #~ flash[:notice] = 'Some thing went wrong!!'
  #~ render :template => 'shared/error'and return      
  end
  
  
  
   def update_travelog
    
     if @travelog = @user_profile.travelogs.find_by_permalink(params[:id])
       
           if request.post?
             
                 @travelog.updated_at = Time.now 
                 @travelog.permalink=nil
                  if  @travelog.update_attributes(params[:travelog])
                   flash[:notice] ="Travelog was successfully updated"
                   redirect_to :action=>'add_tag', :id => @travelog.permalink
                  else
                  flash[:notice] = "Unable to edit Travelog" 
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
