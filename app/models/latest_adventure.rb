class LatestAdventure < ActiveRecord::Base
  
   belongs_to :story, :class_name => "Story", :foreign_key => "source_id"
   belongs_to :photoset, :class_name => "Photoset", :foreign_key => "source_id"
   
   
def self.add_to_list(source,type,user)
          if !source.blank? and !user.blank?
              latest_adventure = LatestAdventure.find(:first, :conditions => ["user_id like ? and source_id like ? and source like ?",user,source,type])           
                  if !latest_adventure.blank?
                    latest_adventure.update_attributes!(:updated_at => Time.now)
                    else
                    latest = LatestAdventure.create!(:source_id=> source,:source => type, :user_id => user) 
                  end 
          end
end

def self.delete_from_list(source,type,user)
           if !source.blank? and !user.blank?
              latest_adventure = LatestAdventure.find(:first, :conditions => ["user_id like ? and source_id like ? and source like ?",user,source,type])           
                  if !latest_adventure.blank?
                    latest_adventure.destroy
                 end 
          end  
end  

end
