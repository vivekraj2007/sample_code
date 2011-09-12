class See::SeeDefaultController < ApplicationController
  #~ before_filter :get_browser_details
  before_filter :user_information 
  layout 'see'
    def see_default
    #render :text => "Welcome to see module"
    redirect_to :controller => "see/people",:action => "index"
  end  
end
