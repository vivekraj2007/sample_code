class Go::TestController < ApplicationController
  
  #caches_page :index

  before_filter :gotab_locations
  layout 'go'
  
  def index
    
    
  end


end
