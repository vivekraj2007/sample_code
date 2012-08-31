module SubscriptionsHelper
  def default_or_posted(object, field, default)
    params[object] and params[object][field] or default
  end
  
  def text_field_with_default(object, method, default = nil, options = {})
    text_field object, method, options.merge(:value => default_or_posted(object, method, default))
  end
  
  def select_with_default(object, method, choices, default)
    select object, method, choices, :selected => default_or_posted(object, method, default)
  end
  
end
