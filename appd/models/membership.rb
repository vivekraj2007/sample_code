class Membership < ActiveRecord::Base
  belongs_to :list
  belongs_to :phone
  
  validates_uniqueness_of :list_id, :scope => :phone_id, :message => "already contains that member."
  
  validates_presence_of :list_id, :phone_id
  
  scope :not_null,   where([ 'list_id IS NOT NULL AND phone_id IS NOT NULL' ])
  scope :sendable,   joins("inner join lists on memberships.list_id = lists.id left join keywords on lists.id = keywords.list_id").where([ 'is_admin  = ? and keywords.id is not null', true ])
  scope :manageable,   joins("inner join lists on memberships.list_id = lists.id left join keywords on lists.id = keywords.list_id").where([ 'is_admin  = ? and keywords.id is not null', true ])
  scope :not_admin,  where([ 'is_admin != ?', true ])
  scope :opted_in,  where([ 'opted_out_at is null' ])
  scope :sorted, order('memberships.description ASC')

  def notify_salesforce
    list.creator.salesforce_add_subscriber
  end
  after_save :notify_salesforce

  def check_first_subscriber
    list.creator.check_first_subscriber(phone)
  end
  after_save :check_first_subscriber

  def to_s
    list.to_s
  end
  
  def phone_number # for to_xml
    phone
  end

  def self.find_all_by_list_and_full_or_private_or_partial_phone(list, search)
    if Phone[search]        
      memberships_by_phone = all(:conditions => ['phones.number = ? AND memberships.list_id = ?', PhoneNumber.parse(search), list.id ], :include => :phone)
      memberships_by_phone
    else        
      memberships_by_partial_phone = all :conditions => [ 'phones.number LIKE ? AND memberships.list_id = ?', "%#{search}%", list.id], :include => :phone
      memberships_by_partial_phone unless memberships_by_partial_phone.empty?
    end
  end

  def self.build_from_list_and_phone_number(list, phone_number)
    m = Membership.new :opt_in_method => 'ListName'
    m.list = list
    m.opt_in_id = list.id
    raise ActiveRecord::RecordNotFound, 'list does not exist' unless m.list
    p = Phone.find_or_create_by_number(PhoneNumber.parse(phone_number))
    # possible bug here if phone does not validate, because find_or_create does not raise
    m.phone = p
    return m
  end
  
  def self.build(list, membership_params, options = {})
    if membership_params[:phone_id] then
      phone = Phone.find membership_params[:phone_id]
    else
      prototype = Membership.find membership_params[:membership_prototype_id]
      phone = prototype.phone
    end
    
    membership = Membership.new
    membership.opt_in_method = options[:opt_in_method] || 'tatango list manager'
    
    membership.list = list
    membership.phone = phone
    
    membership.description = prototype.description if prototype
    
    [:comments, :can_manage, :can_send].each do |attribute|
      membership.send("#{attribute}=", membership_params[attribute]) if membership_params[attribute]
    end
    return membership
  end
  
  def name
    if phone
      phone.name
    else
      ""
    end
  end
  
  def name=(arg)
    self.description = arg
  end


  def membership_prototype_id=(membership_id)
    p = Membership.find(membership_id)
    
    update_attribute :phone_id, p.phone_id
    update_attribute :description, p.description
    p.reload
  end

  def can_send=(foo)
    update_attribute :is_admin, foo
  end
  
  def can_manage=(foo)
    update_attribute :is_admin, foo
  end
  
  def can_send?
    is_admin?
  end
  
  def can_manage?
    is_admin?
  end

  def messages_received
    if opted_out_at.nil?
      list.messages.count(:conditions => ["created_at > ? and event_id is null and phone_id is null", created_at])
    else
      list.messages.count(:conditions => ["created_at > ? and created_at < ? and event_id is null and phone_id is null", created_at, opted_out_at])
    end
  end
  
  # for debugging
  def inspect
    attributes_as_nice_array = Array.new
    attributes_as_nice_array << "id: #{self.id}"
    attributes_as_nice_array << "phone: #{self.phone.to_s rescue 'does not exist'}"
    attributes_as_nice_array << "list: #<List id: #{self.list_id} name: #{self.list.name rescue 'does not exist'}>"
    attributes_as_nice_array << "is_admin: #{self.is_admin.inspect}"
    [ :description, :comments, :opt_in_method, :opt_in_id, :created_at, :updated_at ].each do |attribute|
      attributes_as_nice_array << "#{attribute}: #{attribute_for_inspect(attribute)}" if read_attribute(attribute)
    end
    
    "#<#{self.class} #{attributes_as_nice_array.join ', '}>"
  end 
end
