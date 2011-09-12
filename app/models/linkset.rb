class Linkset < ActiveRecord::Base
  
  
  # relations
   belongs_to :story, :class_name => "Story", :foreign_key => "source_id"
   belongs_to :review, :class_name => "Review", :foreign_key => "source_id"
   belongs_to :photoset, :class_name => "Photoset", :foreign_key => "source_id"
   belongs_to :videoset, :class_name => "Videoset", :foreign_key => "source_id"
  
  def self.add_linkset(source,type,link)
     
     if !link.blank? && !source.blank?
        linksetvalues = link.split('_')   
      #if !source.blank? 
           linkset = Linkset.find(:first, :conditions => ["source_id like ? and source_type like ?",source,type])           
           if linkset
            linkset.update_attributes!(:link_type=>linksetvalues[0],:link_id => linksetvalues[1])
            else
            link_set = Linkset.create!(:source_id=>source,:source_type=>type, :link_type => linksetvalues[0] ,:link_id => linksetvalues[1]) 
          end
          
      #  end
        
     end
   
 end
 
 end
