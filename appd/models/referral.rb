# so far, this is really the referrals table
class Referral < ActiveRecord::Base
  belongs_to :account
  belongs_to :referred_by, :foreign_key => 'ref_by_id', :class_name => 'Account'
  
  def referred?; !!referred_by; end
  
  def do_referral!(code)
    # changed on 2010-01-15, new referrals should override old referrals because
    # now you can refer people until they have payed
    # return false if referred?
    self.referred_by = Account.find_by_referral_code(code)
    self.referred_at = Time.current
  end
end
