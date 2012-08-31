class EventMessage < Message
  attr_accessor :already_optin

  attr_accessible :list_id, :phone

  def to_sms
    to_s.rstrip
  end
  
  def self.create_from_event!(event, options = {})
    raise ArgumentError, "EventMessage.create_from_event needs an Opt, but event.reference is not an Opt, it is a #{event.reference.class}." unless event.reference.is_a? Opt
    
    options.reverse_merge! event.tmp_options[:message_options] if event.tmp_options and event.tmp_options[:message_options]
    options.merge! :event => event
    options.merge! :event_type => event.event_type
    
    case event.event_type
    when 'join'
      create_join_message_from_opt!(event.reference, options)
    when 'leave'
      create_leave_message_from_opt!(event.reference, options)
    else
      raise ArgumentError, "EventMessage.create_from_event expects a leave or join event, but got a #{event.event_type.inspect} event."
    end
  end
  
  def self.create_join_message_from_opt!(opt, options = {})
    if opt.list and opt.list.bounceback and !opt.list.bounceback.empty?
      resolved_bounceback = opt.list.bounceback

      if options.has_key?(:already_optin) and options[:already_optin]
        resolved_bounceback = "You can not receive the welcome message more than once."
      end

      begin
        Time.zone = opt.list.creator.time_zone
      rescue => e
      end

      begin
        resolved_bounceback = resolved_bounceback.gsub(/{DTE}/i, opt.list.creator.tz.now.strftime("%m/%d"))
        
        resolved_bounceback.gsub!(/{D[0-9][0-9]}/i) {|match|
          (opt.list.creator.tz.now + match.match(/[0-9]+/).to_s.to_i.days).strftime("%m/%d")
        }
        
      rescue => e
      end

      self.create_message_from_opt! opt, GLOBALS['join_message'] + "\n\n" + resolved_bounceback + "\n\n" + opt.list.message_volume.to_s + GLOBALS['join_message_footer'], options
    else
      self.create_message_from_opt! opt, GLOBALS['join_message'] + "\n\n" + opt.list.message_volume.to_s + GLOBALS['join_message_footer'], options
    end
  end


  def self.create_leave_message_from_opt!(opt, options = {})
    #create_message_from_opt! opt, "You have left #{opt.list.to_s}. Reply STOP ALL to leave all lists. List text messaging by Tatango.com.", options
    create_message_from_opt! opt, "You have been removed from every list and will no longer receive msgs or chrgs. Need help? Visit www.tatango.com or e-mail support@tatango.com", options
  end
  
  def self.create_message_from_opt!(opt, content, options = {})
    list = opt.list # calls on list should expect that it migth be nil
        
    phone = Phone[opt.phone_number]
    raise RuntimeError, "Phone for opt does not exist" unless phone

    create_options = {
      :list_id => opt.list_id,
      :phone => phone, # can we expect this phone to exist?
      :sender => opt.phone_number,
      :content => content,
    }.merge(options || {})

    event_message = EventMessage.new
    event_message.list_id = opt.list_id
    event_message.phone = phone
    event_message.sender = opt.phone_number
    event_message.content = content
    event_message.save        

  end

end
