# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper





def sort_td_class_helper(param)
  result = 'class="sortup"' if params[:sort] == param
  result = 'class="sortdown"' if params[:sort] == param + "_reverse"
  return result
end


def sort_link_helper(text, param,page)
  key = param
  key += "_reverse" if params[:sort] == param
  options = {
      :url => {:action => 'list', :params => params.merge({:sort => key, :page => page})},
      :update => 'table',
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')"
  }
  html_options = {
    :title => "Sort by this field",
    :href => url_for(:action => 'list', :params => params.merge({:sort => key, :page => page}))
  }
  link_to_remote(text, options, html_options)
end


def story_map_div(story)
html = "<div style='width:100%; overflow:hidden;'>"
html += "<div style='width:180px; float:left; overflow:hidden;'>"
html += "<div style='font-family:Arial, Helvetica, sans-serif; font-size:12px; color:#7f000a; font-weight:bold; float:left; clear:both;'>"
html += "#{ title_slice(story.title,50) }"
html += "</div>"
html += "<div style='font-family:Arial, Helvetica, sans-serif; font-size:11px; color:#000000; float:left; clear:both;'>"
html += "text text text text text"
html += "</div>"
html += "<div style='font-family:Arial, Helvetica, sans-serif; font-size:11px; color:#000000; float:left; clear:both;'>"
html += "text1 text1 text1 tex1t text1"
html += "</div>"
html += "</div>"
html += "<div style='float:left; width:60px;'>"
html += "<div style='float:left; width:60px; clear:both;'>"
html += "<img src='/images/home/edit_map.jpg'/>"
html += "</div>"
html += "<div style='float:left; width:60px; padding-top:10px; height:60px;'>"
html += "<img src='/images/home/main_image_map.jpg'/>"
html += "</div>"
html += "</div>"
html += "</div>"
html
  
  
end




 def check_caption(caption)
  if !caption.blank?
    return caption
  else
    return "There is no caption for this image"
  end  
  end




def check_friend(friend_id)
if !session[:user_id].blank?
 unless friend_id == nil
    conditions = ["((user_id LIKE ? AND friend_id LIKE ?) and accepted_at is not null) OR ((user_id LIKE ? AND friend_id LIKE ?) and accepted_at is not null)",session[:user_id],friend_id,friend_id,session[:user_id]]
    user = UserNetwork.find(:first,:conditions => conditions )
          if user
            return false
          else
            return true
          end
        end 
else
  return true
end

end  

def check_continent(continent)
  if !continent.nil?
    return continent.gsub(/\?/,'-')
  else
    return "Asia"
  end  
end

def check_country(country)
  if !country.nil? 
    #country = Country.find_by_id(country)
   # if !country.blank?
     return  country.gsub(/\?/,'-')
    #else
        #return "India"
    #end    
  else
    return "India"
  end  
end

def check_state(state)
  
  if !state.nil?
  
    return state.gsub(/\./,'-')
  else
     return "AndhraPradesh"
  end  
end

def check_location(location)
  if !location.nil?
    return location.gsub(/\?/,'-')
  else
      return "Kakinada"
  end  
end


  # method for linkset option value
  
  
  def check_login(id)
    
    if !session[:user_id].blank?
        if session[:user_id] == id
          return true        
        else
          return false
        end    
    else      
      return false
    end  
    
    
  end  
  def linkset_optionvalue(source,type)    
    if !source.blank? && !type.blank? 
       opttype=  Linkset.find(:first, :conditions => ["source_id LIKE ? AND source_type LIKE ?",source,type])
     if  !opttype.blank?
             if opttype.link_type == 'r'
               opyvalue = Review.find_by_id(opttype.link_id)       
               addreturn_value(opyvalue,'r')     
             elsif opttype.link_type == 'p'
              opyvalue = Photoset.find_by_id(opttype.link_id)       
             addreturn_value(opyvalue,'p')
             elsif opttype.link_type == 'v'
              opyvalue = Videoset.find_by_id(opttype.link_id)       
             addreturn_value(opyvalue,'v')
              else
               return " <option value="">Link this Set to....</option>"
             end    
       else 
   return " <option value="">Link this Set to....</option>"          
       end     
             
             
    else 
   return " <option value="">Link this Set to....</option>"
   end    
  end
  
  


 #method to slice the title for the given size
 
 def title_slice(title,tsize)
   unless title==nil
   if title.size > tsize || title.size == tsize
     title= title.slice(0,tsize-3)+"..."
     return title.titlecase
  else
       return title.titlecase
  end
  end   
 end  

#method to display string using to()
def title(title,tsize)
   unless title==nil
   if title.size > tsize || title.size == tsize
     title= title.slice(0,tsize-3)+"..."
     return title
  else
       return title
  end
  end   
 end  


def title_slice_withoutcap(title,tsize)
     unless title==nil
   if title.size > tsize || title.size == tsize
     title= title.slice(0,tsize-3)+"..."
     return title
  else
       return title
  end
  end   
end

def title_slice_withoutcap_div(title,tsize)
     unless title==nil
   if title.size > tsize || title.size == tsize
     title= h(title).slice(0,tsize-3)+"..."
     return h(title)
  else
       return h(title)
  end
  end   
end

def title_tcase(title)
   unless title==nil
   return title.titlecase
  end
end  

def title_gcase(title)
   unless title==nil
   title = title.gsub(/\[?'']/,' ')
   return title.titlecase
  end
end 

def user_dateformate(user_date)
  if user_date !=nil
  return user_date.strftime("%b/%d/%Y")  
  else
    return "Inactive"
 end  
end  

def map_date(content_date)
  if content_date !=nil
  return content_date.strftime("%b %d, %y")  
  else
    return "Inactive"
 end  
end  

def check_blank_condition(information)
  if !information.blank? 
    return information
  else
    return "N/A"
  end
end

def myworld_dateformat(user_date)
    if user_date !=nil
  return user_date.strftime("%a %b %d, %Y")
  #~ + " at "+user_date.strftime("%I:%M %p")
  else
  return "Unknown date format"
 end    
end

  #method to limit the charecters for the screen name.
  def profile_name(screenname)
    unless screenname==nil
     if screenname.size > 15 ||  screenname.size == 15   
    return screenname.slice(0,11)+"..."
   else
    return screenname.titlecase
  end
  end
end

def user_name(id)
  user = User.find(id)
  unless user.blank?
  name = user.screen_name
  if name.size > 15 || name.size == 15    
  return name.slice(0,11)+"..."
  else
  return name.humanize
  end    
  end   
end


# method to display default image if profile image was blank
def profile_image(id)
  unless id.blank?
  profile = Profile.find_by_user_id(id)
  if !profile.profile_image.blank?
   return url_for_file_column(profile, "profile_image","submain")
   else     
   return "/images/home/noprofile_photo.gif"
 end
end
end

#method to display the country flag
def country_flag
  unless session[:user].blank?
   if !session[:user].country.image.blank?
     return image_tag(url_for_file_column(session[:user].country, "image","main"))
      else 
        
      end
      end
end  

#method to concat city and state of the user.
def profile_home(city,state)
  if !city.blank?
  address = city.humanize
    if !state.blank?
        address << ", " 
        address << state.humanize
        end
      return address 
    end  
    end
 
 
 #method to diaply user passion 
def user_passion(passion)
   unless passion.blank?
    if passion.size > 17     
  return passion.slice(0,15)+"..."     
else
   return passion
 end   
end
end

#method to display user website
def user_website(website)
   unless website.blank?
     if website.size > 20   
  return website.slice(0,18)+"..."     
else
   return website
 end   

  
  end
end  
 
 
 def form_status(status)
   if status == "new"
     return "new_photoset"
     elsif status == "edit"
         return "edit_photoset"
end
end  

public

  # public method for linkset optional value
  
  def addreturn_value(opyvalue,type)
  if !opyvalue.blank?
     return  "<option value=\"#{type}_#{opyvalue.id}\">&nbsp;&nbsp;&nbsp;#{opyvalue.title.humanize}</option>"
  else
    return " <option value="">Link this Set to....</option>"
  end
  end

end
