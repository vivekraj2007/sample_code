class Reply < ActiveRecord::Base
  # attr_accessible not needed because controller does not mass-update (MO::Handler does though)
  
  belongs_to :phone
  belongs_to :message, :counter_cache => true
  
  scope :unread, :conditions => { :read => false }
  
  def name
    m = Membership.find_by_list_id_and_phone_id(list.id, phone.id) rescue nil
    if m.present? and m.description
      m.description
    else
      ''
    end
  end

  def from
    begin
      m=Membership.find_by_list_id_and_phone_id(list.id,phone.id)

	  m.phone.to_s
    rescue NoMethodError, RuntimeError # RuntimeError is when you call nil.id
      phone.to_s
    end
  end

  def membership
    Membership.find_by_list_id_and_phone_id(list.id,phone.id)
  end
  
  def send_to_phone?
    message.list.send_replies_to_phone? if message and message.list
  end
  
  def list
    message.list
  end
  
end
