class Event < ActiveRecord::Base

  has_one :message
  belongs_to :list
  belongs_to :reference, :polymorphic => true
  
  attr_accessor :tmp_options # for passing information off to the observer etc
  
  def self.event_types(*args)
    args.each do |t|
      define_method :"#{t}?" do
        self.event_type == "#{t}"
      end
      
      scope t.to_sym, where("event_type = #{t}")
    end
  end
  event_types :join, :leave, :leave_all, :complaint, :reply, :upload
  scope :joins, :conditions => { :event_type => 'join' } # namespace clash
  
  scope :find_for_list, lambda { |list|
   where(:list_id => list.id).order('created_at DESC')
  }
  
  # returns true if self can be conceptually listed with other
  # for example two replies can be listed together, if they are replies to the same message
  def lists_with?(other)
    return if other.nil?
    if other.event_type == event_type
      case event_type
      when 'reply'
        other.reference.message == reference.message
      else
        false
      end
    end
  end
  
  def self.create_from_object!(object, options = {})
    event = Event.new
    event.tmp_options = options

    case object
    when Opt
      event.event_type = options[:event_type] || event_type_from_opt(object)
      event.reference = options[:reference] || object
      event.list_id = object.list_id
    when Reply
      event.event_type = object.class.to_s.underscore
      event.reference = object
      event.list_id = object.message.list_id
    when Membership
      event.event_type = 'upload'
      event.reference = object
      event.list_id = object.list_id
    else # Message, this should be a fairly generic case, as other types may be added
      event.event_type = object.class.to_s.underscore
      event.reference = object
      event.list_id = object.list_id
    end

    event.save

    return event
  end
  
  def self.event_type_from_opt(opt)
    if opt.leave_all?
      'leave_all'
    elsif opt.leave?
      'leave'
    elsif opt.join?
      'join'
    else
      raise ArgumentError, 'Event#set_event_type_from_opt recieved an invalid Opt'
    end
  end
  
end
