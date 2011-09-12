module Myworld::PhotosHelper

def check_continent(continent)
  if !continent.blank?
    return continent
    else
      return "Asia"
      end
  
end

end
