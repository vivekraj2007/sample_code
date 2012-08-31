class Phone < ActiveRecord::Base

  attr_accessible :phone_number, :carrier
  has_many :memberships
  has_many :messages
  has_many :lists, :through => :memberships

  belongs_to :reply_message, :foreign_key => :reply_message_id, :class_name => 'Message'
  
  validates_numericality_of :number
  validates_length_of :number, :is => 10
  validates_uniqueness_of :number
  
  composed_of :phone_number, :class_name => 'PhoneNumber', :mapping => %w(number number)
  validate :require_valid_number
  def require_valid_number
    unless phone_number.valid?
      errors.add(:number, 'is invalid')
    end
  end
  
  
  # THIS FUNCTION SENDS A MESSAGE
  # unless called with options[:silent]
  #
  # options are
  #   * :silent -- do not add to feed or send message
  #   * :sender -- record the origin of this opt-out request
  def leave_list(list, options = {})
    membership = list.membership_for self
    if membership
      TatangoLogger.moLog.log("MT:" + self.to_s + " - Opt out of #{list}.") if defined? TatangoLogger
      TatangoLogger.optLog.log("PhoneModel Opt-Out:" + self.to_s + " - " + ((list.keyword and list.keyword.name) or "Expired List")) if defined? TatangoLogger
      
      membership.update_attribute(:opted_out_at, Time.now)
      
      opt = Opt.create_from_phone_number_and_membership :out, self, membership, :opt_out_method => options[:sender], :list => list
      event = Event.create_from_object!(opt, :message_options => { :sender => options[:sender] || self.number }) unless options[:silent]
      EventMessage.create_from_event!(event) unless options[:event_type] and options[:event_type] != 'leave_all'
    end
  end
  
  # THIS FUNCTION SENDS A MESSAGE
  # unless called with options[:silent]
  #
  # creates an Event (event type leave_all) for each List left
  #
  # options are
  #   * :silent -- do not add to feed or send message
  #   * :sender -- record the origin of this opt-out requestS <- required I think
  def leave_all_lists(options = {})
    
    # Opt.create \
    #   :phone_number => self.number,
    #   :opt_type => 'out',
    #   :opt_out_method => options[:sender]
    # 
    transaction do # the transaction is an attempt to make all the OptS and MessageS associated with this opt-out sequential
      memberships.opted_in.not_admin.each do |membership|
        membership.update_attribute(:opted_out_at, Time.now)
    
        opt = Opt.create_from_phone_number_and_membership :out, self, membership, :opt_out_method => options[:sender]
        event = Event.create_from_object! opt, :event_type => 'leave_all' unless options[:silent]
      end
    end
      
    MT.send("You have been removed from every list and will no longer receive msgs or chrgs. Need help? Visit www.tatango.com or e-mail support@tatango.com",
      self.number, self.carrier)
  end
  
  def to_s
    phone_number.to_s
  end

  def area
    phone_number.to_a[0]
  end

  def prefix
    phone_number.to_a[1]
  end

  def suffix
    phone_number.to_a[2]
  end

  # returns the PhoneNumber#to_d
  #
  # this is used for situations when we are showing the phone number for the current_user
  def to_s
    phone_number.to_s
  end

  def name
    self.to_s
  end
  
  def phone
    self # sometimes code expects a membership or account but gets a phone
  end

  def carrier_name
    CARRIERS[carrier]
  end
  
  # creates a new Phone (if needed) and transfers lists / infos to the new number before destroying the old one
  #
  # this method should be refactored...
  def change_number_to(new_number)
    if PhoneNumber.new(new_number) == phone_number
      errors[:base] <<  'cannot change number to itself'
      raise ActiveRecord::RecordInvalid, self
    end
    
    transaction do
      new_phone = Phone.create! :phone_number => PhoneNumber.new(new_number)
      new_phone.save!
      
      # complicated steps to figure out which membership to keep if there are duplicates
      old_memberships = Membership.find_all_by_phone_id self.id
      new_memberships = Membership.find_all_by_phone_id new_phone.id

      old_memberships.each do |old_membership|
        # find memberships that are to the same list
        if new_membership = new_memberships.find {|m| m.list_id == old_membership.list_id }
          both_memberships = [ new_membership, old_membership ]
          # if only one is an admin choose it, otherwise pick latest updated
          admin = both_memberships.select {|m| m.is_admin? }
          to_keep = if admin.size == 1
            admin.first
          else
            both_memberships.max {|a, b| a.updated_at <=> b.updated_at }
          end
          to_delete = both_memberships.find {|m| m != to_keep }
          to_delete.destroy
        end
      end
    
      
      Membership.update_all "phone_id = #{new_phone.id}", "phone_id = #{self.id}"
      Message.update_all "phone_id = #{new_phone.id}", "phone_id = #{self.id}"
      Reply.update_all "phone_id = #{new_phone.id}", "phone_id = #{self.id}"
      
      self.destroy
    end
  end
  
  class << self
    # find a phone number. Accepts any form of phone number you could think of
    #
    # Warning: this caches, so be sure to reload
    def [](phone)
      @@phone_cache ||= {}
      number = case phone
      when PhoneNumber, Phone
        phone.number
      else
        PhoneNumber.parse phone
      end
      # logger.error "Phone[#{phone.inspect}]: #{"(cache hit: #{@@phone_cache[number].inspect})" if @@phone_cache[number]} result should be: #{find_by_number(number).inspect}"
      @@phone_cache[number] ||= find_by_number number
    end
  end
end
