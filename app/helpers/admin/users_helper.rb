module Admin::UsersHelper

# method for user staus

def user_status(activated_date)
  if activated_date.blank?
    return "Inactive"
    else
      return "Active"
      end 
    end
    

def user_langauages(lang1,lang2,lang3)
lang = ""
    if !lang1.blank?
        lang<<lang1
        lang<<", "
    end
    if !lang2.blank?
        lang<<lang2
        lang<<", "
    end
    if !lang3.blank?
        lang<<lang3
        lang<<", "
    end
lang.chomp(", ")    
end


def user_places(pls1,pls2,pls3)
 pls = ""
    if !pls1.blank?
        pls<<pls1
        pls<<".<br/>"
    end
    if !pls2.blank?
        pls<<pls2
        pls<<". <br/>"
    end
    if !pls3.blank?
        pls<<pls3
        pls<<".<br/>"
    end
  pls.chomp(". ")    

end  

end
