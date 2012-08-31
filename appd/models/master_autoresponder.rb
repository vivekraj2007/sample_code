class MasterAutoresponder < ActiveRecord::Base
  has_many :autoresponder_responses

  validates_uniqueness_of :name
  validates_presence_of :name
  validates_presence_of :response
end
