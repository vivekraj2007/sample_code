class Notifier < ActionMailer::Base
  class NotSendingMail < StandardError; end
  def self.method_missing(*args)
    super
  rescue NotSendingMail => e
    RAILS.logger.info("Not mailing! #{e}")
  end

  def confirmation(account)
    #SentEmail.create({:account_id => account.id, :to => account.email, :body => (render_message 'confirmation', :account => account)})
    
    @account = account

    mail(
      :to => account.email,
      :from => "Tatango <gettingstarted@tatango.com>",
      :subject => "Please confirm your email address"
    )
  end

  def welcome(account)
    #SentEmail.create({:account_id => account.id, :to => account.email, :body => (render_message 'welcome', :account => account)})
    
    @account = account

    mail(
      :to => account.email,
      :from => "Tatango <support@tatango.com>",
      :subject => "[Tatango] Welcome to Tatango!"
    )
  end
    
  def reset_password(account)
    #SentEmail.create({:account_id => account.id, :to => account.email, :body => (render_message 'reset_password', :account => account)})
    
    @account = account

    mail(
      :to => account.email,
      :from => 'Tatango <support@tatango.com>',
      :subject => '[Tatango] Reset Your Tatango Password'
    )
  end

  def trial_expired(account, list)
    #SentEmail.create({:account_id => account.id, :to => account.email, :body => (render_message 'trial_expired', :account => account, :list => list)})
    
    @account = account
    @list = list

    mail(
      :to => account.email,
      :from => 'Tatango <support@tatango.com>',
      :subject => '[Tatango] Your Tatango List Name Has Expired'
    )
  end

  def trial_one_day_left(account, list)
    #SentEmail.create({:account_id => account.id, :to => account.email, :body => (render_message 'trial_one_day_left', :account => account, :list => list)})
    
    @account = account
    @list = list

    mail(
      :to => account.email,
      :from => 'Tatango <support@tatango.com>',
      :subject => '[Tatango] Your Tatango List Name Expires in 24 Hours'
    )
  end

  def list_activity(account, list, time_range)
    #SentEmail.create({:account_id => account.id, :to => account.email, :body => (render_message 'list_activity', :account => account, :list => list, :time_range => time_range)})
    
    @account = account
    @list = list
    @time_range = time_range

    mail(
      :to => account.email,
      :from => 'Tatango <support@tatango.com>',
      :subject => "[Tatango] New Subscribers for #{list.resolved_name.upcase}"
    )
  end
  
  def autoresponder_single(autoresponder, number)
    @autoresponder = autoresponder
    @number = number

    mail(
      :to => autoresponder.email,
      :from => 'Tatango <support@tatango.com>',
      :subject => "[Tatango] New Autoresponder Response for #{autoresponder.resolved_name}"
    )
  end
  
  def autoresponder_summary(autoresponder)
    responses = autoresponder.autoresponder_responses.all(:conditions => "summarized = false")
    
    if responses.empty?
      raise NotSendingMail
    end

    numbers = responses.collect{|r| r.phone.number }

    for response in responses
      response.update_attribute(:summarized, true)
    end
    
    @autoresponder = autoresponder
    @numbers = numbers

    mail(
      :to => autoresponder.email,
      :from => 'Tatango <support@tatango.com>',
      :subject => "[Tatango] Summary of Autoresponder Responses for #{autoresponder.resolved_name}"
    )
  end
  
  def contest_single(contest, number)
    @contest = contest
    @number = number

    mail(
      :to => contest.email,
      :from => 'Tatango <support@tatango.com>',
      :subject => "[Tatango] New Contest Entry for #{contest.resolved_name}"
    )
  end
  
  def contest_summary(contest)
    responses = contest.contest_responses.all(:conditions => "summarized = false")
    
    if responses.empty?
      raise NotSendingMail
    end

    numbers = responses.collect{|r| r.phone.number }

    for response in responses
      response.update_attribute(:summarized, true)
    end
    
    @contest = contest
    @numbers = numbers

    mail(
      :to => contest.email,
      :from => 'Tatango <support@tatango.com>',
      :subject => "[Tatango] Summary of Contest Entries for #{contest.resolved_name}"
    )
  end
  
  def poll_single(poll, number)
    @poll = poll
    @number = number

    mail(
      :to => poll.email,
      :from => 'Tatango <support@tatango.com>',
      :subject => "[Tatango] New Vote for #{poll.resolved_name}"
    )
  end
  
  def poll_summary(poll)
    responses = poll.poll_responses.all(:conditions => "summarized = false")
    
    if responses.empty?
      raise NotSendingMail
    end

    numbers = responses.collect{|r| r.phone.number }

    for response in responses
      response.update_attribute(:summarized, true)
    end
    
    @poll = poll
    @numbers = numbers

    mail(
      :to => poll.email,
      :from => 'Tatango <support@tatango.com>',
      :subject => "[Tatango] Summary of Votes for #{poll.resolved_name}"
    )
  end


  def admin_notify_auto_upgrade(message_id, plan_template_id)
    mail(
      :to => 'ben+system@tatango.com',
      :from => 'Tatango <support@tatango.com>',
      :subject => "Successful auto upgrade",
      :body => "Message: #{message_id.inspect}  Plan Template: #{plan_template_id.inspect}"
    )
  end

  def admin_notify_fail_auto_upgrade(message_id)
    mail(
      :to => 'ben+system@tatango.com',
      :from => 'Tatango <support@tatango.com>',
      :subject => "Failed auto upgrade",
      :body => "Message: #{message_id.inspect}"
    )
  end
end
