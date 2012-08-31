class PollResponse < ActiveRecord::Base
  belongs_to :poll
  belongs_to :phone

  def check_first_subscriber
    begin
      poll.creator.check_first_subscriber(phone)
    rescue => e
    end
  end
  after_save :check_first_subscriber
end
