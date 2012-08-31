class ContestResponse < ActiveRecord::Base
  belongs_to :contest
  belongs_to :phone

  def check_first_subscriber
    begin
      contest.creator.check_first_subscriber(phone)
    rescue => e
    end
  end
  after_save :check_first_subscriber
end
