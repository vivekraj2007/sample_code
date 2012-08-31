class List < ActiveRecord::Base
  #
  # access
  #
  
  attr_accessible :send_replies_to_phone, :has_members_joined_email_flag, :message_volume, :bounceback, :bounceback_once

  #
  # associations
  #
  has_one :keyword, :dependent => :destroy
  
  has_many :memberships, :dependent => :destroy

  belongs_to :creator, :class_name => 'Account', :foreign_key => :created_by
  
  # FIXME: Message dependency causes crashes, do the same thing but manually
  has_many :messages #, :dependent => :nullify
  before_destroy { |list| Message.update_all("list_id = NULL", "list_id = #{list.id}") }
  
  has_many :events
  has_many :opts
  
  #
  # validations
  #
  
  validates_inclusion_of :message_volume, :in => (1..99)
  validates_length_of :bounceback, :maximum => (GLOBALS['bounceback_size']), :allow_nil => true

  # validates_presence_of :created_by, :on => :create # don't fuck up existing lists

  def init
    self.message_volume ||= 30
  end
  after_initialize :init

  def plan
    creator.plan
  end

  attr_accessor :memberships_count

  def subscribers_count
    return memberships_count
  end

  def memberships_count
    @memberships_count ||= self.memberships.count(:conditions => "opted_out_at is null")
  end

  def unread_reply_count
    # TODO: This is very slow...
    @unread_reply_count ||= Reply.count :include => :message, :conditions => ['messages.list_id = ? AND replies.read != ? AND messages.type IS NULL', self.id, true]
  end
  
  def reload_with_membership_cache
    @membership_for_phone = {}
    reload_without_membership_cache
  end
  alias_method_chain :reload, :membership_cache
  
  def membership_for(phone)
    phone_id = case phone
    when Account
      phone.phone.id # first phone is actually account
    when Phone
      phone.id
    else
      Phone[phone].id
    end
          
    @membership_for_phone ||= {}
    @membership_for_phone[phone] ||=
      memberships.first(:conditions => [ 'phone_id = ?', phone_id ])            
  end
    
  # backwards compatibility
  def membership_for_phone(phone)
    membership_for phone
  end

  def can_manage?(user)
    if membership_for(user) then
      membership_for(user).can_manage?
    end
  end

  def can_send?(user)
    m = membership_for(user) and m.can_send?
  end
  
  def is_member_only?(user)
    !membership_for(user).is_admin? if membership_for(user)
  end

  def admins
    Membership.all(:conditions => {:list_id => self.id, :is_admin => true})
  end
  
  def newbie?
      memberships_count<GLOBALS['newbie_contacts']
  end
  
  def newbie_step
     return 0 if memberships_count<2
     return 1 if messages.size<1
     2
  end

  def events
    Event.find_for_list(self)
  end

  def messages
    Message.find_for_list(self)
  end

  def send_to
    memberships.where("opted_out_at is null")
  end
  
  
    
  def to_param
    if keyword and keyword.name
      return "#{id}-#{CGI::escape to_s.gsub(' ', '_').gsub(/([^\w_-]+)/n, '')}"
    else
      return id.to_s
    end
  end

  def resolved_name
    if keyword and keyword.id
      if keyword.name_changed?
        return keyword.changes[:name].first
      else
        return keyword.name
      end
    else
      return "[Keyword Not Set]"
    end
  end

  def to_s
    keyword and keyword.name
  end
  
  #
  # statistic methods
  #
  
  def joins_within_opts(time_range)
    Opt.all(:group => 'phone_number', :conditions => [ 'list_id = ? AND opt_type = ? AND created_at BETWEEN ? AND ?', self.id, 'in', time_range.begin, time_range.end ])
  end

  def joins_within(time_range)
    Opt.count(:conditions => [ 'list_id = ? AND opt_type = ? AND created_at BETWEEN ? AND ?', self.id, 'in', time_range.begin, time_range.end ])
  end
  
  def leaves_within(time_range)
    self.opts.count :conditions => [ 'opt_type = ? AND created_at BETWEEN ? AND ?', 'out', time_range.begin, time_range.end ]
  end
  
  def messages_within(time_range)
    self.messages.just_messages.count :conditions => [ 'created_at BETWEEN ? AND ?', time_range.begin, time_range.end ]
  end

  def recipients_within(time_range)
    self.messages.just_messages.all(:conditions => [ 'created_at BETWEEN ? AND ?', time_range.begin, time_range.end ]).sum{|m|
      m.recipients_count or 0
    }
  end
  
  def replies_within(time_range)
    Reply.count :include => :message, :conditions => [ 'messages.list_id = ? AND replies.created_at BETWEEN ? AND ?', self.id, time_range.begin, time_range.end ]
  end

  def retention
    outs = Opt.count(:conditions => {:list_id => id, :opt_type => 'out'}).to_f
    rw = recipients_within(Time.at(0)..Time.zone.now)
    if rw == 0
      return 1
    end
    result = 1.to_f - outs/rw
    
    if result.nan?
      return 1
    end

    return result
  end
end
