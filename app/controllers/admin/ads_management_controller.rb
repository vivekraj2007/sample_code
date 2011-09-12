class Admin::AdsManagementController < ApplicationController
  before_filter :authorize_admin  
  layout "admin"
  
  
  
 # home page default ads management  
def index
  @home_page = DefaultAd.find(1)  
end  

def add_home_page_default_adv
  @default_adv = DefaultAd.find_by_id(params[:id])
  @parient_id = params[:parient_id]
   sort = case params['sort']
   when "title"  then "title"
   when "company_name"  then "company_name"  
   when "created_at" then "created_at"
   when "position" then "position"
   when "title_reverse"  then "title DESC"
   when "company_name_reverse"  then "company_name DESC"
   when "created_at_reverse"  then "created_at DESC"
   when "position_reverse" then "position DESC"
  end   
    page = params[:page].blank? ? 1 : params[:page]
    if !params[:search].blank?
        condition = [	"company_name like ? and parient_id LIKE ?", "%"+params[:search]+"%",@parient_id]
    else
        condition = [	"parient_id LIKE ?", @parient_id]
    end  
  @adv = AdvList.paginate :per_page=>25, :page=>page,:conditions => condition,:order => sort   
end
  
  
def add_adv_home_page
  @default_adv = DefaultAd.find_by_id(params[:id])
  @parient_id = params[:parient_id]
   if  @default_adv.update_attributes(:advertisement_id => params[:adv_id])
       flash[:notice] = "Ad was successfully added"
       redirect_to :action => 'index'
     else
       flash[:notice] = "Unable to add Ad"
       render :action => 'add_home_page_default_adv'
   end
end

def delete_adv_home_page
  @default_adv = DefaultAd.find_by_id(params[:id])
   if  @default_adv.update_attributes(:advertisement_id => nil)
       flash[:notice] = "Ad was successfully deleted"
       redirect_to :action => 'index'
     else
       flash[:notice] = "Unable to delete Ad"
       render :action => 'add_home_page_default_adv'
   end
end

# stories page default page ads managment  
def stories_page
    @stories_page = DefaultAd.find(2) 
    @stories_page_left_top = DefaultAd.find(3) 
    @stories_page_left_bottom = DefaultAd.find(4) 
    @stories_page_right = DefaultAd.find(5) 
end  
  
 def photos_page
    @photos_page_top = DefaultAd.find(10) 
    @photos_page_left_top = DefaultAd.find(11) 
    @photos_page_left_bottom = DefaultAd.find(12) 
    @photos_page_right = DefaultAd.find(13) 
end  
   
  
def add_stories_page_default_adv
  @default_adv = DefaultAd.find_by_id(params[:id])
  @parient_id = params[:parient_id]
  sort = case params['sort']
  when "title"  then "title"  
   when "company_name"  then "company_name"  
   when "created_at" then "created_at"
   when "position" then "position"
    when "title_reverse"  then "title DESC"
   when "company_name_reverse"  then "company_name DESC"
   when "created_at_reverse"  then "created_at DESC"
   when "position_reverse" then "position DESC"
  end   
    page = params[:page].blank? ? 1 : params[:page]
    if !params[:search].blank?
        condition = [	"company_name like ? and parient_id LIKE ?", "%"+params[:search]+"%",@parient_id]
    else
        condition = [	"parient_id LIKE ?", @parient_id]
    end  
  @adv = AdvList.paginate :per_page=>25, :page=>page,:conditions => condition,:order => sort      
end


def add_photos_page_default_adv
  @default_adv = DefaultAd.find_by_id(params[:id])
  @parient_id = params[:parient_id]
  sort = case params['sort']
  when "title"  then "title"  
   when "company_name"  then "company_name"  
   when "created_at" then "created_at"
   when "position" then "position"
    when "title_reverse"  then "title DESC"
   when "company_name_reverse"  then "company_name DESC"
   when "created_at_reverse"  then "created_at DESC"
   when "position_reverse" then "position DESC"
  end   
    page = params[:page].blank? ? 1 : params[:page]
    if !params[:search].blank?
        condition = [	"company_name like ? and parient_id LIKE ?", "%"+params[:search]+"%",@parient_id]
    else
        condition = [	"parient_id LIKE ?", @parient_id]
    end  
  @adv = AdvList.paginate :per_page=>25, :page=>page,:conditions => condition,:order => sort      
end
  
def add_adv_stories_page
  @default_adv = DefaultAd.find_by_id(params[:id])
  @parient_id = params[:parient_id]
   if  @default_adv.update_attributes(:advertisement_id => params[:adv_id])
       flash[:notice] = "Ad was successfully added"
       redirect_to :action => 'stories_page'
     else
       flash[:notice] = "Unable to add Ad"
       render :action => 'add_stories_page_default_adv'
   end
 end
 
 def add_adv_photos_page
  @default_adv = DefaultAd.find_by_id(params[:id])
  @parient_id = params[:parient_id]
   if  @default_adv.update_attributes(:advertisement_id => params[:adv_id])
       flash[:notice] = "Ad was successfully added"
       redirect_to :action => 'photos_page'
     else
       flash[:notice] = "Unable to add Ad"
       render :action => 'add_photos_page_default_adv'
   end
end
 
  
def delete_adv_stories_page
@default_adv = DefaultAd.find_by_id(params[:id])
 if  @default_adv.update_attributes(:advertisement_id => nil)
     flash[:notice] = "Ad was successfully deleted"
     redirect_to :action => 'stories_page'
   else
     flash[:notice] = "Unable to delete Ad"
     render :action => 'add_stories_page_default_adv'
 end
end
  
def delete_adv_photos_page
@default_adv = DefaultAd.find_by_id(params[:id])
 if  @default_adv.update_attributes(:advertisement_id => nil)
     flash[:notice] = "Ad was successfully deleted"
     redirect_to :action => 'photos_page'
   else
     flash[:notice] = "Unable to delete Ad"
     render :action => 'add_photos_page_default_adv'
 end
end
  
  
  
def add_adv_to_story
    @story = Story.find(params[:id])
    @story_adv = StoryAdv.find_by_id(params[:id])
    
    page = params[:page].blank? ? 1 : params[:page]
    sort = case params['sort']
     when "created_at" then "created_at"
     when "title" then "title"
     when "position" then "parient_id"
     when "created_at_reverse"  then "created_at DESC"
     when "title_reverse" then "title DESC"
     when "position_reverse" then "parient_id DESC"
    end   
   
    sort = sort.blank? ? "created_at DESC" : sort
    
  if params[:position] == 'header'
     @default_header = DefaultAd.find(2)
      if !params[:search].blank?
            condition = [	"(title like ? or company_name like ? or position like ?) and parient_id = 1 and id not like ?", "%"+params[:search]+"%","%"+params[:search]+"%",params[:search],@default_header.advertisement_id]
         else
           condition = ["parient_id = 1 and id not like ?",@default_header.advertisement_id]
         end  
     
  elsif params[:position] == 'left_top'
    @default_left = DefaultAd.find(3)
       if !params[:search].blank?
            condition = [	"(title like ? or company_name like ? or position like ?) and parient_id = 2 and id not like ?", "%"+params[:search]+"%","%"+params[:search]+"%",params[:search],@default_left.advertisement_id]
         else
           condition = ["parient_id = 2 and id not like ?",@default_left.advertisement_id]
         end  
         
   elsif params[:position] == 'left_bottom'
    @default_left = DefaultAd.find(4)
       if !params[:search].blank?
            condition = [	"(title like ? or company_name like ? or position like ?) and parient_id = 2 and id not like ?", "%"+params[:search]+"%","%"+params[:search]+"%",params[:search],@default_left.advertisement_id]
         else
           condition = ["parient_id = 2 and id not like ?",@default_left.advertisement_id]
         end 
elsif params[:position] == 'right'
    @default_left = DefaultAd.find(5)
       if !params[:search].blank?
            condition = [	"(title like ? or company_name like ? or position like ?) and parient_id = 3 and id not like ?", "%"+params[:search]+"%","%"+params[:search]+"%",params[:search],@default_left.advertisement_id]
         else
           condition = ["parient_id = 3 and id not like ?",@default_left.advertisement_id]
         end  

   end
   
   @adv = AdvList.paginate :per_page=>25, :page=>page, :conditions => condition,:order => sort
end

  
  def add_adv_to_photo
    @photoset = Photoset.find(params[:id])
    @photoset_adv = PhotosetAdv.find_by_id(params[:id])
    
    page = params[:page].blank? ? 1 : params[:page]
    sort = case params['sort']
     when "created_at" then "created_at"
     when "title" then "title"
     when "position" then "parient_id"
     when "created_at_reverse"  then "created_at DESC"
     when "title_reverse" then "title DESC"
     when "position_reverse" then "parient_id DESC"
    end   
   
    sort = sort.blank? ? "created_at DESC" : sort
    
  if params[:position] == 'header'
     @default_header = DefaultAd.find(10)
      if !params[:search].blank?
            condition = [	"(title like ? or company_name like ? or position like ?) and parient_id = 1 and id not like ?", "%"+params[:search]+"%","%"+params[:search]+"%",params[:search],@default_header.advertisement_id]
         else
           condition = ["parient_id = 1 and id not like ?",@default_header.advertisement_id]
         end  
     
  elsif params[:position] == 'left_top'
    @default_left = DefaultAd.find(11)
       if !params[:search].blank?
            condition = [	"(title like ? or company_name like ? or position like ?) and parient_id = 2 and id not like ?", "%"+params[:search]+"%","%"+params[:search]+"%",params[:search],@default_left.advertisement_id]
         else
           condition = ["parient_id = 2 and id not like ?",@default_left.advertisement_id]
         end  
         
   elsif params[:position] == 'left_bottom'
    @default_left = DefaultAd.find(12)
       if !params[:search].blank?
            condition = [	"(title like ? or company_name like ? or position like ?) and parient_id = 2 and id not like ?", "%"+params[:search]+"%","%"+params[:search]+"%",params[:search],@default_left.advertisement_id]
         else
           condition = ["parient_id = 2 and id not like ?",@default_left.advertisement_id]
         end 
elsif params[:position] == 'right'
    @default_left = DefaultAd.find(13)
       if !params[:search].blank?
            condition = [	"(title like ? or company_name like ? or position like ?) and parient_id = 3 and id not like ?", "%"+params[:search]+"%","%"+params[:search]+"%",params[:search],@default_left.advertisement_id]
         else
           condition = ["parient_id = 3 and id not like ?",@default_left.advertisement_id]
         end  

   end
   
   @adv = AdvList.paginate :per_page=>25, :page=>page, :conditions => condition,:order => sort
end

  
 #~ def index
    #~ page = params[:page].blank? ? 1 : params[:page]
    #~ sort = case params['sort']
   #~ when "sponser_name"  then "sponser_name"  
   #~ when "created_at" then "created_at"
   #~ when "title" then "title"
   #~ when "position" then "parient_id"
   #~ when "sponser_name_reverse"  then "sponser_name DESC"
   #~ when "created_at_reverse"  then "created_at DESC"
   #~ when "title_reverse" then "title DESC"
   #~ when "position_reverse" then "parient_id DESC"
  #~ end   
   
    #~ sort = sort.blank? ? "created_at DESC" : sort
 
     #~ if !params[:search].blank?
        #~ condition = [	"title like ? or sponser_name like ?", "%"+params[:search]+"%","%"+params[:search]+"%"]
     #~ else
       #~ condition = ""
    #~ end  
    
   
   #~ @adv = Advertisement.paginate :per_page=>25, :page=>page, :conditions => condition,:order => sort

 #~ end
  
  
  
def stories_header 
  @story = Story.find_by_id(params[:story_id],:select => "id,title")
  @adver_id = params[:id]
  
   sort = case params['sort']
   when "sponser_name"  then "sponser_name"  
   when "created_at" then "created_at"
   when "status" then "status"
   when "sponser_name_reverse"  then "sponser_name DESC"
   when "created_at_reverse"  then "created_at DESC"
   when "status_reverse" then "status DESC"
  end   
    page = params[:page].blank? ? 1 : params[:page]
    if !params[:search].blank?
        condition = [	"sponser_name like ? and parient_id LIKE ?", "%"+params[:search]+"%",params[:id]]
    else
        condition = [	"parient_id LIKE ?", params[:id]]
    end  
  @adv = Advertisement.paginate :per_page=>5, :page=>page,:conditions => condition,:order => sort 
end  



def stories_left_top 
  @story = Story.find_by_id(params[:story_id],:select => "id,title")
  
  sort = case params['sort']
   when "sponser_name"  then "sponser_name"  
   when "created_at" then "created_at"
   when "status" then "status"
   when "sponser_name_reverse"  then "sponser_name DESC"
   when "created_at_reverse"  then "created_at DESC"
   when "status_reverse" then "status DESC"
  end  
  
  
  page = params[:page].blank? ? 1 : params[:page]
  if !params[:search].blank?
        condition = [	"sponser_name like ? and parient_id LIKE ?", "%"+params[:search]+"%",params[:id]]
    else
        condition = [	"parient_id LIKE ?", params[:id]]
    end  
 @adv = Advertisement.paginate :per_page=>5, :page=>page,:conditions => condition,:order => sort 
end 


def stories_left_bottom 
  @story = Story.find_by_id(params[:story_id],:select => "id,title")
  
  sort = case params['sort']
   when "sponser_name"  then "sponser_name"  
   when "created_at" then "created_at"
   when "status" then "status"
   when "sponser_name_reverse"  then "sponser_name DESC"
   when "created_at_reverse"  then "created_at DESC"
   when "status_reverse" then "status DESC"
  end  
  
  
  page = params[:page].blank? ? 1 : params[:page]
  if !params[:search].blank?
        condition = [	"sponser_name like ? and parient_id LIKE ?", "%"+params[:search]+"%",params[:id]]
    else
        condition = [	"parient_id LIKE ?", params[:id]]
    end  
 @adv = Advertisement.paginate :per_page=>5, :page=>page,:conditions => condition,:order => sort 
end 


def photoset_header 
  @photoset = Photoset.find_by_id(params[:photoset_id],:select => "id,title")
      page = params[:page].blank? ? 1 : params[:page]
  condition = ["parient_id LIKE ?",params[:id]]
  @adv = Advertisement.paginate :per_page=>5, :page=>page,:conditions => condition 
end  


  def new_advertisement
        @adv = Advertisement.new
  end
  
  
  def save_advertisement
   @adv = Advertisement.new(params[:adv])
   #@adv.parient_id = 0 
   @adv.status = 1
             if @adv.save!
               flash[:notice] = "New Advertisement was successfully added." 
               redirect_to :action => 'index'  
               else
               flash[:notice] = "Unable to add new advertisement"     
               redirect_to :action => 'save_advertisement' and return
            end
     
  end
  
  def edit_advertisement
       @adv = Advertisement.find(params[:id]) 
 end  
  
  
  def update_advertisement
    @adv = Advertisement.find(params[:id]) 
    @adv.status = 1
   if request.post?
         if @adv.update_attributes(params[:adv])
       flash[:notice] = "Advertisement was successfully updated"
       redirect_to :action => 'index'
    else
        flash[:notice] ="Unable to update advertisement"
        redirect_to :action => 'edit_advertisement',:id => @adv.id and return
     end
  end    
  end
  
  def delete_advertisement
  Advertisement.find(:first, :conditions => ["id like ?",params[:id]]).destroy 
  flash[:notice] = "Advertisement was successfully deleted"  
  redirect_to :action => 'index'
 end  
 
 
  def new_add
    @adv = Advertisement.new
    @adv.position = 'story_bottom'
    if @adv.save!
      render :text => "adv saved"
    end    
  end  
  
  
  def edit_add
    @adv = Advertisement.find(params[:id])
     @adv.position = 'story_top'
    if @adv.update_attributes!(params[:adv])
       render :text => "adv updated"
  end    
  end  
  
end
