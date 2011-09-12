class PhotosController < ApplicationController
  
  before_filter :authorize_user  
    before_filter :story_advertisements
  layout 'home'
  
  
  
  
  def profile
  @user = User.find_by_screen_name(params[:id])
   end
  
  def photoset
  @story = Story.find(:first,:conditions => ["user_id LIKE ? AND permalink LIKE ?",session[:user_id],params[:id]])
  #@photoset = Photoset.find_by_permalink(params[:id])  
   render :template => '/myworld/stories/preview'
  end  
 
 
 
  #method to display photos index page
  def index       
    page = params[:page].blank? ? 1 : params[:page]
   @photosets = Photoset.paginate :per_page=>4, :page=>page, :conditions => ["user_id like ?",session[:user_id]],:order=>"updated_on DESC"

     if params[:id].blank?
    @index_photoset = Photoset.find(:first, :conditions => ["user_id like ?", session[:user_id]], :order => "updated_on DESC")
        else
    @index_photoset = Photoset.find(:first, :conditions => ["user_id like ? AND id LIKE ?", session[:user_id],params[:id]], :order => "updated_on DESC")  
  end
  
  
  
    #~ if request.post?
      #~ photosetid = params[:photoset]      
     #~ @photos= Photo.find(:all, :conditions => ["photoset_id like ?", photosetid])       
    #~ else
    #~ @photos = Photo.find(:all, :conditions =>["photoset_id like ?",@user_photsets[0].id])
    #~ end
  end  
  
  def photo
    photoset_id = params[:phst_id]
   @index_photoset = Photoset.find(photoset_id)
   @photo_display = Photo.find(params[:id]) 
   render :layout => false
 end  
 
  def search
    #render :text => 'ccsf'
    @user = User.find_by_sql("select * from photos")
    render :text => @user.inspect
   #~ search_word = params[:search]
   #~ @story = Story.find(:first, :conditions => ["user_id like ? and (title like ? or sub_title like ? or where_is like ? or tag like ?)",session[:user_id],search_word,search_word,search_word,search_word])   
   #~ if @story
    #~ flash[:notice] = "Your search for '  #{search_word} ' found story ' #{@story.title.humanize} '"    
   #~ else
     #~ @search_result = "no result"
    #~ flash[:notice] = "Your search for ' #{search_word} ' found no result"    
   #~ end
    #~ render :action => 'index'
  end  
  
  
  
  # method fo resize profile images at once.
  
  def profile_photo
    @profile = Profile.find(:all)
    
    for profile in @profile
    if !profile.profile_image.blank?
    original_image   =  RAILS_ROOT + "/public/profile/profile_image/#{profile.id}/#{File.basename(profile.profile_image)}"
   # main = RAILS_ROOT + "/public/profile/profile_image/#{profile.id}/main/#{File.basename(profile.profile_image)}"
   submain = RAILS_ROOT + "/public/profile/profile_image/#{profile.id}/submain/#{File.basename(profile.profile_image)}"
    image   = Magick::ImageList.new(original_image)    
    image   = image.change_geometry!('171x171!') { |c, r, i| i.resize!(c, r) } 
    image.write(submain) 
    end  
    end
    
    
 end   
  
 
  
  #methdo to edit image size to user defined size.
  def recreate
    #photo   = Photo.find(params[:id])
    #degrees = if params[:direction] == 'left' then -90 else 90 end

    #~ #main photo
    #~ image   = Magick::ImageList.new(photo.file)
    #~ image   = image.rotate(degrees)
    #~ image.write(photo.file)

    # thumb
    @photoset = Photoset.find(params[:id])
    #@photos = Photo.find(:all)
    for photo in @photoset.photos 
   # render :text => photo.id and return
    photo   = Photo.find(photo.id)
    if !photo.image.blank?
    original_image   =  RAILS_ROOT + "/public/photo/image/#{photo.id}/#{File.basename(photo.image)}"
    
    main = RAILS_ROOT + "/public/photo/image/#{photo.id}/main/#{File.basename(photo.image)}"
    
    #~ thumbnail = RAILS_ROOT + "/public/photo/image/#{photo.id}/thumbnail/#{File.basename(photo.image)}"
    
    #~ submain = RAILS_ROOT + "/public/photo/image/#{photo.id}/submain/#{File.basename(photo.image)}"
    

    
    
    image   = Magick::ImageList.new(original_image)    
    image   = image.change_geometry!('600x450>') { |c, r, i| i.resize!(c, r) } 
    image.write(main)
   
    #~ image   = Magick::ImageList.new(original_image) 
    #~ image   = image.change_geometry!('51x51!') { |c, r, i| i.resize!(c, r) } 
    #~ image.write(thumbnail)
    
    #~ image   = Magick::ImageList.new(original_image) 
    #~ image   = image.change_geometry!('97x97!') { |c, r, i| i.resize!(c, r) } 
    #~ image.write(submain)    
    
 end
  
  end
     render :text => "image croped"
    #redirect_to :action => 'index'
  end
  
    public
  
  def story_advertisements
   @top_adv = Advertisement.find(1)
   @bottom_adv = Advertisement.find(6)    
  end   
  
end
