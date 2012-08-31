module AccountsHelper
  def edit_icon
    image_tag 'icons/pencil.gif', :class => 'edit icon'
  end
  
  def editable(field, opts = {})
    text = opts[:text] || @account.send(field).to_s
    content_tag :strong, text + edit_icon, :class => 'edit'
  end

end
