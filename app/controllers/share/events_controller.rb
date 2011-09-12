class Share::EventsController < ApplicationController
  before_filter :authorize_user
  before_filter :user_information
  layout 'home'
  
  
    # index page to add new photoset and to edit the existing photoset.
  def index    
    @events = Event.find(:all, :conditions => ["user_id LIKE ?", session[:user_id]]) 
    @event = Event.new   
  end  
  
  
  # method to add new event
  def create
    @events = Event.find(:all, :conditions => ["user_id LIKE ?", session[:user_id]]) 
    @event = Event.new(params[:event])
    @event.user_id = session[:user_id] unless session[:user_id].blank?
    @event.created_on = Time.now
    @event.updated_on = Time.now
    if @event.save
          flash[:notice] =" New Event was successfully added"
          redirect_to :action=> :index
     else
          flash[:notice] ="Unable to add to new event"
          render :action=> :index
        end    
    rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return         
end

#method to edit existing events
def edit_event
  @events = Event.find(:all, :conditions => ["user_id LIKE ?",session[:user_id]]) 
  @event =  Event.find(params[:eventedit])
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return 
end

#method to update the edited details for the photo set
def update_event
 @events = Event.find(:all, :conditions => ["user_id LIKE ?", session[:user_id]])  
 @event = Event.find(:first, :conditions => ["user_id like ? AND id like ?",session[:user_id],params[:id]]) 
 @event.updated_on = Time.now 
      if  @event.update_attributes(params[:event])
       flash[:notice] ="Event was successfully updated"
       redirect_to :action=>'index'
      else
      flash[:notice] = "Unable to edit Event" 
      render :action => 'edit_event'
      end
  rescue
  flash[:notice] = 'Some thing went wrong!!'
  render :template => 'shared/error'and return  
end

end
