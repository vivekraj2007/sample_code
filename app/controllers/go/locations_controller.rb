class Go::LocationsController < ApplicationController
  
 before_filter :left_top_adv,:left_bottom_adv,:right_adv
 layout "go"
 
 
def index
     if !params[:id].blank?
     location = params[:id].gsub(/-/,' ')
     @location = Location.find_by_name(location)
     if @location     
       @stories = Story.find(:all, :conditions => ["(continent LIKE ? OR country LIKE ? OR state LIKE ?) AND (status =1)",@location.name,@location.name,@location.name], :order => 'updated_at DESC') 
       @photosets = Photoset.find(:all, :conditions =>["continent LIKE ? OR country LIKE ? OR state LIKE ?",@location.name,@location.name,@location.name],:order => 'updated_on DESC')
       country = Country.find(:first, :conditions =>["name LIKE ? OR continent LIKE ?","%#{@location.name}%","%#{@location.name}%"]) 
       if !country.blank?
          @poeple = User.find(:all, :conditions => ["country_id like ?",country.id], :order => 'updated_at DESC')
       else
          @poeple = []
        end
        
      story_list = Array[]     
      photo_list = Array[]   
      
               if !@stories.blank?
                  @stories.each do |story| 
                     if  !story_list.include?(story.id)
                       story_list.push(story.id)
                     end
                   end  
                   
                  if !story_list.blank?  
                     condition = "source_id in (#{story_list.join(",")}) AND source = 'story'"  
                   end 
              end
               
                if !@photosets.blank?
                  @photosets.each do |photo| 
                    if  !photo_list.include?(photo.id)
                     photo_list.push(photo.id)
                   end
                end 
                   if !photo_list.blank?  
                         if condition.blank?
                          condition = "source_id in (#{photo_list.join(",")}) AND source = 'photoset'" 
                        else
                          condition = "( "+condition+" )" 
                          condition = condition + " OR (source_id in (#{photo_list.join(",")}) AND source = 'photoset')" 
                        end     
                     end        
                   end
                   
        if condition.blank?
            @latest=[]
        else
            @latest = LatestAdventure.paginate :page => params[:page], :per_page => 6, :conditions => condition, :order => 'updated_at DESC'
          end  
           else
      end
      else
        redirect_to home_url
      end
      
end
 

  
  
  
  
end
