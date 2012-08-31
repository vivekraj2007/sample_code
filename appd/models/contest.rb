class Contest < ActiveRecord::Base
  has_one :keyword, :dependent => :destroy
  belongs_to :creator, :class_name => 'Account', :foreign_key => :created_by
  belongs_to :winner, :class_name => 'Phone', :foreign_key => :winner_phone_id

  has_many :contest_responses
  
  validates_length_of :message, :maximum => (GLOBALS['max_chars']), :allow_nil => true

  def subscribers_count
    return contest_responses.select("distinct(phone_id)").count
  end

  def responses_count
    return contest_responses.count
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

  before_create :set_defaults
  def set_defaults
    self.email = creator.email
    self.instant_notification = true
  end

  def entries
    if counter_reset
      contest_responses.where("created_at > ?", counter_reset).count
    else
      responses_count
    end
  end
end
