class Admin::FlagMessagesController < ApplicationController
  before_filter :authorize_admin
  layout 'admin'
  
  def index
  page = params[:page].blank? ? 1 : params[:page]
   sort = case params['sort']
   when "name"  then "name"  
   when "email" then "email"
   when "created_at" then "created_at"
   when "name_reverse"  then "name DESC"
   when "email_reverse"  then "email DESC"
   when "created_at_reverse"  then "created_at DESC"
 end   
  if sort.blank?
     sort = "created_at DESC"
  end  
  @flag = FlagedContent.paginate :per_page=>25, :page=>page,:order => sort
 end  

 def show_details
  @flag = FlagedContent.find(params[:id])   
 end   

  def forced_delete
  @flag = FlagedContent.find(params[:id]).destroy
  flash[:notice] = "message was sucessfully deleted"
  redirect_to :action => "index"
  end
end
