require 'geonames'
#require 'google_geocode'
require "mechanize"

class Country < ActiveRecord::Base
  
   belongs_to :user
   
   #has_one :photoset
  # has_one :videoset
  # belongs_to :story
    
  file_column :image, :magick => {
   :versions => {:main => "16x16!"}  
  }
  
 
 
 # method to find latitude and longitude fro the given address in edit profile. 
  def self.get_lat_longt(address)
      gg = GoogleGeocode.new "ABQIAAAALHXVqR3ivZP4lPuASHGUbRRxI6gS_yiE9yY2PwSnUHXXLgJkihRW61pIbuWHVb-9kU-NwqDke2W2iw"
      locations = gg.locate(address)
            if !locations.latitude.blank? && !locations.longitude.blank?
            return locations
            else
            return nil
            end
       rescue GoogleGeocode::AddressError
      return nil
 end
 
 
 
 
 
 
 
 
# method to find latitude and longitude fro the given address. 
  def self.get_alt_longt(address,country)
      country = Country.find(country)
      address = address+", "+country.name
      gg = GoogleGeocode.new "ABQIAAAALHXVqR3ivZP4lPuASHGUbRRxI6gS_yiE9yY2PwSnUHXXLgJkihRW61pIbuWHVb-9kU-NwqDke2W2iw"
      locations = gg.locate(address)
            if !locations.latitude.blank? && !locations.longitude.blank?
            return locations
            else
            return nil
            end
       rescue GoogleGeocode::AddressError
      return nil
 end   
 
 
 #Method for zipcode validation
def self.zip(id,zipcode)
          country = Country.find(id)
          agent = WWW::Mechanize.new
          agent.user_agent_alias = 'Mac FireFox'
          page = agent.get("http://www.geonames.org/postalcode-search.html")
          form = page.forms[1]
          form.q = zipcode
          form.country = country.country_code
          @page = agent.submit(form)
          country = (@page/"table.restable/tr[2]/td[4]").inner_text
          zipcode = (@page/"table.restable/tr[2]/td[3]").inner_text
          state = (@page/"table.restable/tr[2]/td[5]").inner_text
          city = (@page/"table.restable/tr[2]/td[2]").inner_text
           if city.blank? || state.blank?
             zipcode = nil
             state = nil
             country = nil
                return country,state,zipcode
             else
                  return country,state,zipcode
            end
     
  end
 
 def self.composite_address(country_place)
      address=""
      if !country_place[2].blank?
        address<<country_place[2]
        address<<", "
      end
      if !country_place[4].blank?        
        address<<country_place[4]
        address<<", "
      end
      if !country_place[3].blank?        
        address<<country_place[3]
        address<<", "
      end     
      if !country_place[5].blank?        
        address<<country_place[5]
         address<<", "
      end
    address.chomp(", ")     
  end
 
 
 
  
  
 
def self.get_address_state(lat,longt,type)
    begin
     places_nearby = Geonames::WebService.find_nearby_place_name lat,longt  
     country_subdivision = Geonames::WebService.country_subdivision lat,longt    
     if places_nearby.empty?
            return nil  
     else     
           country_name = Location.find(:first,:conditions => ["name like ?",places_nearby[0].country_name])
             if country_name.blank?
                 return nil  
            else    
              continent = get_continent(country_name) 
              return places_nearby[0].latitude,
              places_nearby[0].longitude,
              places_nearby[0].name.gsub(/#{"\304\201"}/u, 'a').gsub(/[.]/,''), #place location
              country_name.name.gsub(/[.]/,''),    # country name
              country_subdivision.admin_name_1.gsub(/#{"\304\201"}/u, 'a').gsub(/[.]/,''), #state
              continent.gsub(/[.]/,'') # continent
         end
       end
       rescue Exception => e
       #~ flash[:notice] = e
       end
end  
  
  def self.get_continent(country)  
    if country.parent_id == 0
      return country.name
    else
    country =  Location.find(country.parent_id)
    get_continent(country) 
    end      
  end  
  
  
end
