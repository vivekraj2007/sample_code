class Admin::CountriesController < ApplicationController
  
  
def index
  @countries = Country.find(:all)
end
def list
  @countries = Country.find(:all)
  #render :text => @countries.size
end
def new
  @country = Country.new
end

def create
  @country = Country.new(params[:country])
  if @country.save
    @value="saved"
    redirect_to :action => 'list'
  else
    @value="not saved"
    render :action => 'new'
 end    
end

  
def edit
  @country = Country.find(params[:id])
end

def update
  @country = Country.find(params[:id])
  @country.update_attributes(params[:country])
  redirect_to :action => 'index'
end

def delete
 country.find(params[:id]).destroy
 redirect_to :action => 'index'
end

end
