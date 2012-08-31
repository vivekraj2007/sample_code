# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def render_title
    return @page_title + ' | ' + GLOBALS['company_name'] if @page_title
    
    if controller.controller_name == 'tatango'
      if controller.action_name != 'index' then
        title = controller.action_name.titleize
      else
        title = GLOBALS['company_slogan']
      end
    else
      title = controller.controller_name.titleize
    end
   title += ' | ' + GLOBALS['company_name']
    return title
  end
  
  def title(page_title)
    @page_title = page_title
  end

	def render_meta
		('<meta name="description" content="'+
		(@meta_desc ? @meta_desc : 'Text message marketing with Tatango makes it easy to create and send text message campaigns from your computer. Try it free!')+
		'"/>'+
    "\n"+
    '<meta name="keywords" content="'+
    (@meta_key ? @meta_key : '')+
    '"/>').html_safe
	end

	def meta(description)
		@meta_desc = description
	end

  def meta_key(key)
    @meta_key = key
  end

  def noindex
    @noindex = true
  end

	def show_tabs?
		@hide_tabs ? false : true
	end

	def render_body_class
		"#{@body_class}"
	end
	
	def body_class(arg)
		@body_class ||= ''
		@body_class << ' '
		@body_class << arg
	end

  
  def icon(name, options = {})
    image_tag "icons/#{name}.png", options.reverse_merge({ :class => 'icon' })
  end
  
  def clearer_tag
    '<br class="c" />'
  end
  
  
  def is_external_controller?
    ['tatango', 'help', 'signup', 'sms_marketing_resources', 'sms_marketing_tools'].include?(controller.controller_name)
  end 
  
  def logged_in_and_not_external_controller?
    logged_in? and not is_external_controller?
  end
  
  ###############
  #
  # Huge bloated section devoted to setting the class 'current' for the correct menu items
  # maybe this should be moved to a helper object
  #
  
  # tells us what tab to make 'current'
  # takes a url or :lists
  def current_tab(url)
    @current_tab = case url
    when :lists
      keywords_path
    else
      url
    end
  end
  
  # tells us what action to make 'current'
  # takes a url or :send_message
  def current_action(url)
    @current_action = case url
    when :send_message
      new_list_message_path(@list)
		when :add_members
			add_members_path
    else
      url
    end
  end
  
  # tells us what action to make 'current'
  def current_subaction(url)
    @current_subaction = url
  end
  
  def is_login_page?
    controller.controller_name == 'sessions'
  end

  def is_send_message_page?
    controller.action_name == 'new' and ['voices', 'web_messages', 'messages'].include? controller.controller_name
  end
  
  def current_tab_menu_item?(url)
    current_page?(url) or @current_tab == url
  end
  
  def current_menu_item? url, current
    if current.nil? # if the current page was not specified, use the current_page helper
      current_page?(url) 
    else
      current == url
    end
  end
  
  def tab_menu_item(string, url = {}, options = {})
    options.merge_dom_class!('active') if current_tab_menu_item?(url)
    content_tag :li, link_to(content_tag(:span, string), url), options
  end
  
  def menu_add_class! options, url
    if @_submenu
      options.merge_dom_class!('current-submenu') if current_menu_item? url, @current_subaction
    else
      options.merge_dom_class!('active') if current_menu_item? url, @current_action
    end
  end
  
  def menu_item(string, url = {}, options = {}, &block)
    menu_add_class! options, url
    content = link_to(content_tag(:span, string), url)
    content += submenu_content &block if block_given?
    content = content_tag(:li, content, options)
    return block_given? ? concat(content) : content
  end
  
  # set a global state
  def submenu_content(&block)
    @_submenu = true
    content = content_tag :ul, capture(&block), :class => 'submenu'
    @_submenu = false
    return content
  end
  
  def render_action_nav
    render :partial => 'lists/action_nav', :locals => {:list => @list}
  end
  
  def ajaxify_will_paginate(options = {})
    content_for :dom_loaded_javascript, "jQuery.ajaxify_will_paginate(#{options.to_json});" unless request.format == :mobile
  end
  
  def custom_will_paginate(collection, options = {})
    defaults = { :outer_window => 0, :inner_window => 2, :prev_label => "&laquo; Previous", :next_label => "Next &raquo;" }
    will_paginate collection, defaults.merge(options)
  end
  
  def feed_pagination(collection, options = {})
    next_link = link_to "Older &raquo;", { :page => collection.next_page } if collection.next_page
    prev_link = link_to "&laquo; Newer", { :page => collection.previous_page } if collection.previous_page
    
    content = (prev_link ? prev_link : '') + (next_link ? next_link : '')
    
    content_tag :div,
      content,
      :class => 'pagination', :id => 'feed_pagination'
  end
end
