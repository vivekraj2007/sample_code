class Message < ActiveRecord::Base
  belongs_to :list
  belongs_to :phone
  belongs_to :event
  
  has_many :replies

  attr_accessible :content, :schedule, :schedule_at

  #validates_length_of :content, :within => 1..(160 - Message.footer), :if => Proc.new { |m| m.text? }
  validates_format_of :content, :with => /\A[\x20-\x7F\r\n\s]+\Z/, :message => 'contains characters that cannot be sent in a text message.', :if=>Proc.new {|m| m.text? and !m.content.empty?}
  
  validates_each :content do |record,attr,value|
    next unless record.text?
    if value.size < 1
      record.errors.add attr, "is empty."
    end
    if MT.to_gsm0338(record.with_footer).size > 160
      record.errors.add attr, "is too long."
    end

    GLOBALS['blacklisted_words'].each {|word|
      record.errors.add attr, 'contains a blacklisted word.' if value and value.to_s.match /#{word}/i
    }

    if record.new_record?
      Message.where("created_at > ? and list_id = ? and event_id is null and phone_id is null", 2.minutes.ago, record.list.id).each{|m|
        if m.content == record.content
          record.errors.add :base, "Message has already been sent." 
        end
      }
      
      if record.schedule
        if record.schedule_at.nil?
          record.errors.add :base, "Message must have a valid scheduled date."
        elsif record.schedule_at < Time.now
          record.errors.add :base, "Message must be scheduled for the future."
        end
      end
    end
  end
  
  validates_presence_of :list_id, :message => "That was not a valid list."
    
  # takes an optional options argument
  # * :within
  # * :limit
	# * :since
  # Example:
  #   Message.most_recent(:within => 30.minutes)
  scope :most_recent, lambda { |*args|
    options = args.extract_options!
    conds = { :order => 'created_at DESC' }

		since = if options[:within] then
			options[:within].ago
		elsif options[:since]
			options[:since]
		end
		
    conds.merge!({:conditions => ['created_at > ?', since ]}) if since
    conds.merge!({:limit => options[:limit]}) if options[:limit]
    conds
  }  
    
  # required argument: +phone_number+
  scope :find_by_phone_number, lambda { |phone_number|
    phone = Phone.find_by_number(phone_number, :include => :lists)
    { :conditions => [ 'phone_id = ? OR (phone_id IS NULL AND list_id IN (?))', phone.id, phone.lists.collect(&:id) ] }
  }
  
  scope :find_for_list, lambda { |list|
    { :conditions => { :list_id => list.id }, :order => 'created_at DESC' }
  }
  
  scope :just_messages,  :conditions => 'type IS NULL'
  scope :just_text_messages, :conditions => 'type IS NULL'
  scope :to_a_list, :conditions => 'phone_id IS NULL'
  scope :event_messages, :conditions => "type = 'EventMessage'"
  
  scope :directly_to_list, lambda { |list|
    { :conditions => {:list_id => list } }
  }
  
  scope :find_by_account, lambda { |account|
    list_ids = account.created_lists.collect{|l| l.id}
    { :conditions => ["list_id in (?)", list_ids] }
  }

  before_save :clean_content
  def clean_content
    if self.content and self.content_changed?
      self.content.gsub!(/\r\n?/,"\n")
      self.content = self.content.strip

      begin
        self.content = self.content.gsub("{DTE}", list.creator.tz.now.strftime("%m/%d"))
        
        self.content.gsub!(/{D[0-9][0-9]}/) {|match|
          (list.creator.tz.now + match.match(/[0-9]+/).to_s.to_i.days).strftime("%m/%d")
        }
        
        self.content.gsub!(/\t/, " ")
      rescue => e
      end
    end
  end

  def self.send_message(message_id)
    begin # rescue all exceptions reaised from within this spawn
      message = Message.find(message_id)

      if message.schedule and message.list and message.list.creator and message.list.creator.expired?
        message.update_attribute(:status, "cancelled")
        return
      end

      message.update_attribute(:status, "sending")

      if message.to_sms.size > 160
        raise "Message too long"
      end

      MT.send(message.to_sms, message.recipients, [], message.id)
      message.recipients_count = message.recipients.size
      message.status = 'sent'
      message.save
      if message.phone_id.nil?
        message.list.send_to.joins("left join phones on phone_id = phones.id").update_all("reply_message_id = #{message_id}, autoresponded = false")
      else
        message.phone.update_attribute(:autoresponded, true)
      end
    rescue => exception # rescue all exceptions thrown within this spawn and tell us about them
      message.update_attribute(:status => 'error')
      
      message_info  = "Message info: <br/>\n"
      message_info << "id: #{message.id}<br/>\n"
      message_info << "Content: #{message.content}<br/>\n"
      message_info << "#{message.inspect.gsub('<','&lt;').gsub('>','&gt;')}\n"
      
      message.logger.error "Sparrow Exception:" + message_info
      message.logger.error exception
      message.logger.error exception.backtrace

    end
  end

  class SendMessageJob < Struct.new(:message_id)
    def perform
      Message.send_message(message_id)
    end
  end
  def self.send_message_background(message_id)
    message = Message.find(message_id)
    delayed_job = nil
    if message.schedule and message.schedule_at
      delayed_job = Delayed::Job.enqueue(SendMessageJob.new(message_id), :priority => 1, :run_at => message.schedule_at)
      message.status = 'scheduled'
    else
      delayed_job = Delayed::Job.enqueue(SendMessageJob.new(message_id), :priority => 1)
    end
    message.delayed_job_id = delayed_job.id
    message.save
  end

  # most Messages send a message when created
  after_create :trigger_send_message
  def trigger_send_message
    logger.error("message observer: after_create(#{content})")
    return if sent? # message already sent, don't send again
    
    if phone_id
      Message.send_message(id)
    else
      Message.send_message_background(id)
    end
  end
  
  
  # Pass in a List, Account, or Phone and I'll generate an appropriate message.
  def self.create_from(obj, *args)
      m = Message.new
      if obj.is_a? Membership then
         m.phone = obj.phone
         m.list = obj.list 
      end
      if obj.is_a? Reply then
         m.phone = obj.phone
         m.list = obj.message.list
      end
      if obj.is_a? List then
         m.list = obj
      end

      m
  end
  

  GUESSABLE_BASE = 18 # DO NOT CHANGE THIS, if you do, all public message page urls will change
  def self.from_guessable_string(s)
    public_message.find s.to_s.to_i(GUESSABLE_BASE)
  end
  
  def self.to_guessable_string(n)
    n.to_s(GUESSABLE_BASE).upcase if n
  end
  
  def to_guessable_string
    self.class.to_guessable_string self.id
  end
  
  scope :before, lambda { |date|
    { :conditions => ['created_at < ?', date] }
  }
  
  scope :since, lambda { |since|
    { :conditions => ['created_at > ?', since] }
  }
  
  
  def sending?
    status == 'sending'
  end
  
  def sent?
    status == 'sent'
  end

  def scheduled?
    status == 'scheduled'
  end

  def cancelled?
    status == 'cancelled'
  end
  
  def error?
    status == 'error'
  end
  
  def announcing?
    status == 'announcing'
  end
  
  def recording?
    status == 'recording'
  end
  
  def building?
    status == 'building'
  end

  def text?
    self[:type].nil?
  end

  def event?
    self[:type] == 'EventMessage'
  end

  def voice?
    self[:type] == 'VoiceMessage'
  end
  
  def web_message?
    self[:type] == 'WebMessage'
  end
  
  def event_type
    nil
  end

  
  def sent_to
    phone || list
  end
  
  def tag_array
    tags.collect(&:to_s)
  end

  
  # iterate over each recipient and yield a Phone
  #
  # if the Message has a phone set, just yield that Phone.
  # Otherwise, yield each member of the list
  #
  # TODO: when we have the ability to inactivate memberships, only yield those that are active
  #
  # QUESTION: should the single recipient version send if the membership is not active (we should be able to find the membership if the list is set, and it should be)
  # ANSWER: I think so, since single recipient ones are more direct stuff, rather than "updates" or "notices".
  def each_recipient
    if self.phone
      yield self.phone
    elsif self.list
      self.list.send_to.each do |m|
        yield m.phone # if m.active?
      end
    end
  end

  def recipients
    if self.phone
      return [self.phone.number]
    elsif self.list
      return self.list.send_to.joins("left join phones on phones.id = phone_id").select("phones.number").collect{|m| m["number"] }
    end
    []
  end
  
  def header
     list.to_s
  end
 
  def with_footer
    content + Message.footer
  end

  def self.footer
    "\n\nTo opt-out reply STOP"
  end

  def branding
		''
  end
  
  def to_s
    content
  end

  def self.message_number_indicator(n, total)
    total > 1 ? "(#{n}/#{total}):" : ''
  end

  # This is the biggest it can be excluding the header and branding. Just message body.
  def message_max_size(number_of_messages = 1)
    size = GLOBALS['max_chars']
    
    # I removed this because we're summing in the injection below, so we were calcing for 1 header in the first, 2 in the second, and 3 in the 2nd one post-injection...
    # TODO: more testing on the message lengths
    size -= Message.footer.size
    size -= number_of_messages * self.class.message_number_indicator(number_of_messages, number_of_messages).size
  end
  
  # if a message is to be sent, this is what MessageObserver sends
  def to_sms
    @to_sms_cache ||= begin
      	self.with_footer
    end
  end

  def unsubscribes
    next_message = Message.first(:conditions => ["list_id = ? and created_at > ? and phone_id is null", list.id, created_at], :order => 'created_at asc')
    next_time = Time.now
    if next_message
      next_time = next_message.created_at
    end

    return Opt.count(:conditions => ["list_id = ? and opt_type = 'out' and created_at > ? and created_at < ?", list.id, created_at, next_time])    
  end

  # Returns an array indicating the limit for how many characters can fit.
  # For example, max_chars_array.first is the number of characters that can fit in one message.
  # max_chars_array[1] is the number of characters that can fit in two messages.
  #
  # Example:
  #   max_chars_array(:num_messages => 2) # => [98, 145]
  def max_chars_array(options = {})
    num_messages = options[:num_messages] || GLOBALS['max_messages']
    
    max_chars_for_each_message = (1..num_messages).collect{|n| self.message_max_size(n)}
    max_chars_for_all_messages = max_chars_for_each_message.inject([]){|sums, e| sums << e + (sums.last||0) }
  end

  def memberships_count
    return list.memberships.where('memberships.created_at < ? and (opted_out_at is null or ? < opted_out_at)', self.created_at, self.created_at).count
  end

  def carrier_counts
    count = {}

    list.memberships.group("carrier").joins("left join phones on phone_id = phones.id").where('memberships.created_at < ? and (opted_out_at is null or ? < opted_out_at)', self.created_at, self.created_at).select("carrier, count(carrier)").each{|row|
      count[row["carrier"]] = row["count(carrier)"]
    }

    return count
  end

  def message_autoupgrade(message_id, plan_template_id)
    begin
      Message.find(message_id).list.creator.plan.upgrade(PlanTemplate.find(plan_template_id).handle)
      Notifier.admin_notify_auto_upgrade(message_id, plan_template_id).deliver
    rescue => e
      Notifier.admin_notify_fail_auto_upgrade(message_id).deliver
    end
  end
  handle_asynchronously :message_autoupgrade

end
