module MessagesHelper
  
  def humanize_message_type(message)
    case message
    when VoiceMessage
      'Voice'
    when WebMessage
      'Web'
    when Message
      'Text'    
    end
  end
  
  def javascript_inline(file)
    f = File.join(Rails.root, 'public', 'javascripts', "#{file}.js").sub(/\?.+$/,'') 
    javascript_tag File.read(f) if File.exists? f 
  end
  
  
  # call within the same form as a textarea[class*=message_content]  
  def character_limit(*args)
    return nil if request.format == :mobile
    options=args.extract_options!
    
   	maxchars_js = "var MAXCHARS = #{options[:max_chars].last};\n"
   	first_message_maxchars_js = "var FIRST_MESSAGE_MAXCHARS = #{options[:max_chars].first};\n"
   	
    multi_message_js = options[:max_chars].size > 1 ? 'var MULTI_MESSAGE=true;' : 'var MULTI_MESSAGE=false;'
   	
    if request.xhr?
      js  = javascript_tag(maxchars_js)
      
      js += javascript_tag(multi_message_js)
      js += javascript_tag(first_message_maxchars_js)
      
      js += javascript_include_tag 'character_limit'
      
      js += javascript_tag("
        $('form.new_message').each(function(i,form){
          update_character_limit(form);
          $(form).find('.message_content').keyup(function(){
            update_character_limit($(this).parent().parent());
          });
        });
      ")

    else
      content_for(:javascript_in_head) { 
        maxchars_js + first_message_maxchars_js + multi_message_js
      }
      javascript 'character_limit'
      js = ''
    end
  
    content_tag(:small, 
      js + "(#{content_tag(:span, options[:max_chars].last, :class => 'num_chars')} chars left)"
    ) + content_tag(:small, '', :class => 'num_infos')
  end
  
  # call as a direct child of an ancestor to a textarea[class*=message_content]
  # available options
  # * :pre_content -- will be h()'ed
  # * :content -- this _will_ get overwritten by javascript...
  # * :post_content -- if none, example_ads will be used
  # * :send -- if true, say 'Text to <shortcode>', as opposed to 'Text from <shortcode>'
  # * :razorbeak -- dynamically update it
  def phone_preview(*args)
    return nil if request.format == :mobile
    
    options = args.extract_options!
    
    #TODO: Remove keyup for phone_preview
    js = (request.xhr? ? javascript_inline('phone_preview') : '')
    
    inner_content  = content_tag :span, options[:content], :class => 'message'
    inner_content  = content_tag(:span, options[:pre_content] + (options[:inline] ? '' : '<br/>'), :class => 'pre_content') + inner_content if options[:pre_content]
    inner_content += '<br/><br/>' unless options[:inline]
    
    if options[:empty_content] then
        inner_content += content_tag(:span, options[:empty_content], :class => 'empty_content')
    end
    
    if options[:post_content] then
      inner_content += content_tag(:span, options[:post_content], :class => 'post_content')
    end
    
    if options[:header_content]
      header_content = options[:header_content]
    else
      header_content = 'Text ' + 
        (options[:send] ? 'to ' : 'from ') + GLOBALS['shortcode'].to_s
    end
    
    header_tag = content_tag(:div, header_content, :class=>'preview_header')
    
    non_scrolling_content = ''
    non_scrolling_content << options[:non_scrolling_content] if options[:non_scrolling_content]
    non_scrolling_content = content_tag(:div, non_scrolling_content, :class => 'static_text') unless non_scrolling_content.blank?
    
    content_tag(:div,
    	content_tag(:div, header_tag + inner_content, :class => 'text') + non_scrolling_content,
    	:class => 'phone_preview' + (options[:mini] ? ' mini' : '')
    ) + js
  end  
  
  def time_ago_in_words_if_recent(time)
    recent = Time.now - 1.day
    if time > recent
      time_ago_in_words(time) + ' ago'
    else
      time.to_s :standard
    end
  end
  
  # display who the message was sent to, weather it be a list or individual
  # note, this also works with ReplyS
  def sent_to(message)
    return 'Somebody' if message.nil?
    if message.phone
      membership = message.list.membership_for(message.phone)
      membership_description = membership.try(:name)
      link_to( (membership_description || message.phone), list_contact_path(message.list, message.phone))
    else
      message.list
    end
  end
  
  def joined_via(event)
     " via <strong>#{event.reference.user_friendly_opt_in_method}</strong>" unless event.reference.user_friendly_opt_in_method.nil?
  rescue NoMethodError => e
    nil # probably because reference is not an opt
  end

  
  def message_status(message)
    case message.status
    when nil
      'Sending'
    when 'error'
      'Not sent, please try again'
    else
      message.status.titleize
    end
  end

	def overage_warning
		style = @list.creator.messages_left < @list.memberships_count ? '' : 'display:none'
		content_tag :div, t(@list.creator.trial? ? :'limits.cannot_send_message_trial_notice' : :'limits.cannot_send_message_notice')+" #{link_to "Upgrade&nbsp;Now", plans_path}", :id => 'overage_warning', :style => style
	end
end
