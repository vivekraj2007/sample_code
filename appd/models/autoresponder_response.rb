class AutoresponderResponse < ActiveRecord::Base
  belongs_to :autoresponder
  belongs_to :phone
  
  def check_first_subscriber
    begin
      autoresponder.creator.check_first_subscriber(phone)
    rescue => e
    end
  end
  after_save :check_first_subscriber
end
