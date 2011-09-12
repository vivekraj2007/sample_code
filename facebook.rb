   require 'tzinfo'
   require 'rubygems'
module Facebook

def facebook_updates
  # This script deletes all posts that are over 5 minutes old
  @indian_time= TZInfo::Timezone.get('Asia/Calcutta')

 #updating statistics and percentages
  add = Add.find(:all,:select=>"id", :conditions => ["status LIKE ?",1])
  job = Job.find(:all,:select=>"id", :conditions => ["(status = 1 AND date(expiry_date) >= '#{@indian_time.now.to_date}')"])
  sale = Sale.find(:all,:select=>"id", :conditions => ["(business_type LIKE ? AND status LIKE ? AND date(expiry_date) >= '#{@indian_time.now.to_date}')",0,1]) 
  rent = Sale.find(:all,:select=>"id", :conditions => ["(business_type LIKE ? AND status LIKE ? AND date(expiry_date) >= '#{@indian_time.now.to_date}')",1,1])
  discount = Add.find(:all,:select=>"id", :conditions => ["(discount_discription != '' AND status = 1 AND discount_expire >= '#{@indian_time.now.to_date}')"])
  event = Event.find(:all,:select=>"id", :conditions => ["status = 1 AND date(event_schedule_end) >= '#{@indian_time.now.to_date}'"])
  statistics =Statistics.find(:first)
  statistics.update_attributes(:listing_total => add.size,:job_total=>job.size,:forsale_total=>sale.size,:forrent_total=>rent.size,:discount_total=>discount.size,:event_total=>event.size)
   
  #Facebook postings

  facebook =   RFacebook::FacebookWebSession.new('13893e60528faf3c7eb1253c3bb50bca', '2f3a73ba851934437719836a9d40df42')
  @faceme = FacebookUser.find_by_id(4) #:user_id =>fbsession.session_user_id ,:infinite_session => fbsession.session_key)
  facebook.activate_with_previous_session(@faceme.infinite_session, @faceme.user_id, 0)
  
  @today_users = User.find(:all, :conditions => ["created_at LIKE ?",@indian_time.now.to_date])
  @today_feedback = Feedback.find(:first,:select=>"id,feedback,name",:conditions => ["status = 1 AND feedback_status = 1"])
  frds =  facebook.friends_get().uid_list
  if !@today_users.blank?
  notification_msg1 = "#{@today_users.size} users registered today at Inkakinada.com . To Join Inkakinada <a href='http://www.inkakinada.com/signup/'>Click Me</a>"  
  facebook.notifications_send(:notification =>notification_msg1,:to_ids => frds)
  end
  notification_msg2 = "#{@today_feedback.name} says @ Inkakinada : #{@today_feedback.feedback}  <a href='http://www.inkakinada.com/feedbacks'>See All...</a>"
  facebook.notifications_send(:notification =>notification_msg2,:to_ids => frds)
  
  @city_msg = 'Kakinada City Statistics.'
  @city_attachment = Hash['name' => 'Kakinada City Statistics ',
                                            'href' => 'http://www.inkakinada.com/', 
                                              #~ 'caption' => 'www.inkakinada.com', 
                                            'description' => "Know What's Going in Kakinada Today ...",                             
                                            'properties'  => Hash['Businesses' =>  Hash[ 'text' => "#{statistics.listing_total}", 
                                                                                                                    'href' => 'http://www.inkakinada.com/categories'
                                                                                                                  ], 
                                                                            'Jobs available' => Hash[ 'text' => "#{statistics.job_total}", 
                                                                                                                        'href' => 'http://www.inkakinada.com/classifieds/jobs'
                                                                                              ],
                                                                            'Properties for sale' => Hash[ 'text' =>"#{statistics.forsale_total}", 
                                                                                                                                'href' => 'http://www.inkakinada.com/classifieds/for_sale'
                                                                                                                              ],
                                                                           'Rent/Lease/Hire' => Hash[ 'text' =>"#{statistics.forrent_total}", 
                                                                                                                        'href' => 'http://www.inkakinada.com/classifieds/for_rent'
                                                                                              ],
                                                                          'Discounts & Offers' =>Hash[ 'text' =>"#{statistics.discount_total}", 
                                                                                                                           'href' => 'http://www.inkakinada.com/discounts'
                                                                                              ],
                                                                          'Events' => Hash[ 'text' =>"#{statistics.event_total}", 
                                                                                                        'href' => 'http://www.inkakinada.com/events'
                                                                                              ]
                                                                      ] 
                                                        
                                            ]
  
          facebook.stream_publish(:message => @city_msg, :attachment => @city_attachment.to_json)
            
            random_no = rand(23)
            if random == 0
             message_text = TwitterMessage.find(1)
            else
              message_text = TwitterMessage.find(random_no)
            end
            random_message_attachment = Hash['name' => "#{message_text.url}",
                                            'href' => "#{message_text.url}"]
            facebook.stream_publish(:message => "#{message_text.text}",:attachment => random_message_attachment.to_json)
           
           
#facebook postings end


 
end

end

