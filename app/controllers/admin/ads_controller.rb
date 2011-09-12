class Admin::AdsController < ApplicationController
  
  before_filter :authorize_admin  
  layout "admin"
  
  
 def index
    page = params[:page].blank? ? 1 : params[:page]
    sort = case params['sort']
   when "company_name"  then "company_name"  
   when "created_at" then "created_at"
   when "title" then "title"
   when "position" then "parient_id"
   when "company_name_reverse"  then "company_name DESC"
   when "created_at_reverse"  then "created_at DESC"
   when "title_reverse" then "title DESC"
   when "position_reverse" then "parient_id DESC"
  end   
   
    sort = sort.blank? ? "created_at DESC" : sort
 
     if !params[:search].blank?
        condition = [	"(title like ? or company_name like ? or position like ?) and parient_id != 0", "%"+params[:search]+"%","%"+params[:search]+"%",params[:search]]
     else
       condition = "parient_id != 0"
    end  
    @adv = AdvList.paginate :per_page=>25, :page=>page, :conditions => condition,:order => sort
    default_list
   end
   def new_advertisement
        @adv = AdvList.new
  end
  
  
  def save_advertisement
    
    @adv = AdvList.new(params[:adv])
     if params[:adv][:parient_id] == '1'
           @adv.position = 'top'
    elsif  params[:adv][:parient_id] == '2'
        @adv.position = 'left'
    elsif params[:adv][:parient_id] == '3'
        @adv.position = 'right'
    end
   
             if @adv.save!
               flash[:notice] = "New Advertisement was successfully added." 
               redirect_to :action => 'index'  
               else
               flash[:notice] = "Unable to add new advertisement"     
               redirect_to :action => 'save_advertisement' and return
            end
     
  end
  
  def edit_advertisement
       @adv = AdvList.find(params[:id]) 
 end  
  
  
def update_advertisement
    @adv = AdvList.find(params[:id]) 
      if params[:adv][:parient_id] == '1'
           @adv.position = 'top'
    elsif  params[:adv][:parient_id] == '2'
        @adv.position = 'left'
    elsif params[:adv][:parient_id] == '3'
        @adv.position = 'right'
   end
    
    
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
  AdvList.find(:first, :conditions => ["id like ?",params[:id]]).destroy 
  flash[:notice] = "Advertisement was successfully deleted"  
  redirect_to :action => 'index'
end  

private

def default_list      
   default_added_list = DefaultAd.find(:all, :conditions => ["advertisement_id 	is not null"], :select => "advertisement_id")
   @default_list = Array.new
   for ad_list in default_added_list
   @default_list << ad_list.advertisement_id
   end
  end  
end
