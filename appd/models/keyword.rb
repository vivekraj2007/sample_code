class Keyword < ActiveRecord::Base
  belongs_to :list
  belongs_to :autoresponder
  belongs_to :contest
  belongs_to :poll

  attr_accessible :name

  validates_uniqueness_of :name, :case_sensitive => false, :allow_nil => true
  validates_length_of :name, :in => 2..15, :allow_nil => true
  validates_format_of :name, :with => /^[\w]+$/, :message => 'can only be alphanumeric characters', :allow_nil => true
  
  validate :blacklisted_and_reserved_names
  def blacklisted_and_reserved_names
    if name and GLOBALS['blacklisted_names'].include?(name.downcase)
      return errors[:name] << "is reserved"
    elsif name and GLOBALS['reserved_names'].include?(name.downcase)
      return errors[:name] <<  "is reserved for #{GLOBALS['company_name']}"
    elsif name
      MasterAutoresponder.all.each{|ma|
        if name =~ /#{ma.name}/i
          return errors[:name] << "is reserved"
        end
      }

      if name =~ /stop.*/i
        return errors[:name] << "is reserved"
      end
    end
  end
  
  def upcase_name
    if self.name
      self.name = self.name.upcase
    end
  end
  before_save :upcase_name

  def check_trial_keyword
    begin
      account = (list or autoresponder or contest or poll).creator
      if account.trial? and account.trial_keyword_name.nil? and (account.created_keywords.order("created_at asc").empty? or account.created_keywords.order("created_at asc").first.id == id)
        account.trial_keyword_name = name.upcase
        account.save
      end
    rescue => e
      puts "#{e}"
    end
  end
  before_save :check_trial_keyword

  def set_mailchimp_listname
    $gibbon.list_update_member(:id => GLOBALS['mailchimp_lists']['trial'], :email_address => (list or autoresponder or contest or poll).creator.email, :merge_vars => {'LISTNAME' => name.upcase})
    $gibbon.list_update_member(:id => GLOBALS['mailchimp_lists']['follow_up'], :email_address => (list or autoresponder or contest or poll).creator.email, :merge_vars => {'LISTNAME' => name.upcase})
  end
  handle_asynchronously :set_mailchimp_listname
  after_save :set_mailchimp_listname

  def resolved_name
    self.name.upcase rescue "Expired List Name"
  end
end
