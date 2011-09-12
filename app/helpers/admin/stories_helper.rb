module Admin::StoriesHelper

def stories_status(status)
  if status == 0
    return "Inactive"
    else
      return "Active"
      end  
end





end
