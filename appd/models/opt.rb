class Opt < ActiveRecord::Base
  belongs_to :list
  
  serialize :data
  scope :outs, :conditions => [ %(opt_type = 'out') ]
  scope :ins, :conditions => [ %(opt_type = 'in') ]
  
  def self.create_from_phone_number_and_membership(type, phone, membership, options = {})
    options[:opt_in_method] ||= membership.opt_in_method rescue nil
    options[:opt_in_id] ||= membership.opt_in_id rescue nil
    
    options[:list] ||= membership.list rescue nil
    
    list_id = options[:list].id rescue nil
    keyword_name = options[:list].name rescue nil
    list_creator = options[:list].creator.phone.number rescue nil
    
    self.create \
        :opt_type => type.to_s,
        :phone_number => (phone.number rescue phone),
        :list_id => list_id,
        :keyword_name => keyword_name,
        :list_creator => list_creator,
        :opt_in_method => options[:opt_in_method],
        :opt_in_id => options[:opt_in_id],
        :opt_out_method => options[:opt_out_method]
    
  end
  
  
  def user_friendly_opt_in_method
    case opt_in_method
		when 'TatangoUpload'
			'Contact Importer'
    when 'ListName', 'StaticListName'
      if opt_in_id == -1
        "Name #{list.name}"
      else
        list = List.find_by_id(opt_in_id)
        "List#{' ' + list.to_s if list}"
      end
    when 'Creator'
      'List Creator'
    when 'PublicPage'
      'List Profile'
    when 'Widget'
      'Custom Integration'
    when 'PhoneInvite'
      'Text Invite'
    when 'FlashWidget'
      # this was the generic type, uncomment if there is another opt_in_method that can use this bit of excellence
      # opt_in_method.underscore.titleize
      'Flash Widget'
    else
      nil
    end
  end
  
  def in?
    opt_type == 'in'
  end
  alias_method :join?, :in?
  
  def out?
    opt_type == 'out'
  end
  alias_method :leave?, :out?
  
  def leave_all?
    opt_type == 'out' and opt_out_method == 'STOP ALL'
  end
  
end
