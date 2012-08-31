class JavascriptsController < ApplicationController
  before_filter :login_required, :only => [:list_vars]
    
  
  def dynamic_login
  end
  
  def list_vars
    @list_path = list_path(@list)
  end
  
end
