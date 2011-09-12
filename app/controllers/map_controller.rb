require 'rubygems'
require 'google_geocode'
class MapController < ApplicationController
  

  
  protect_from_forgery :only => [:create, :update, :destroy]
  
  
  def display1
    #~ @map = GMap.new("map_div")  
    #~ @map.control_init(:large_map => true, :map_type => true)  
     #~ @map.center_zoom_init([75.5,-42.56], 4)  
      
   #~ marker = GMarker.new([75.6, -42.467], :title => "Where Am I?", :info_window => "Hello, Greenland")  
   #~ @map.overlay_init(marker)  
    
    gg = GoogleGeocode.new "ABQIAAAAVoAlk6p9spXkKKCobYyalBRze0qnd8claLFqBbJJqRHNIHp5uBS0EvSI9Bbvn6y41ZqIP-URI-Ortg"
    loc= gg.locate('1924 E Denny Way, Seattle, WA')
    
    
    @map = GMap.new("map_div")
    @map.control_init(:small => true) #add :large_map => true to get zoom controls
    @map.center_zoom_init([loc.latitude, loc.longitude],14)
    @map.overlay_init(GMarker.new([loc.latitude, loc.longitude],:title =>"Hi", :info_bubble => loc.address))
  end
  
  def show   
    gg = GoogleGeocode.new "ABQIAAAAVoAlk6p9spXkKKCobYyalBRze0qnd8claLFqBbJJqRHNIHp5uBS0EvSI9Bbvn6y41ZqIP-URI-Ortg"
    @loc= gg.locate(params[:address])             
  end
  
  def showaddress

  end

end
