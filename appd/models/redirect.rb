class Redirect < ActiveRecord::Base
  default_scope :order => "threading ASC"

  before_save :update_threading
  def update_threading
    if threading.nil?
      threading = Redirect.maximum('threading')+1
    end
  end
end
