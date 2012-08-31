class Credit < ActiveRecord::Base
  belongs_to :plan
  scope :only_current, :conditions => ['expire_at >= ?', Time.current]
end
