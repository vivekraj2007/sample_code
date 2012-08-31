require 'will_paginate'

class MessagesController < ApplicationController
  layout 'internal'

  before_filter :login_required
  before_filter :find_list, :admin_required
  
  DEFAULT_MESSAGES_PER_PAGE = 20
  DEFAULT_FEED_MESSAGES_PER_PAGE = 9
  MAX_MESSAGES_PER_PAGE = 200
  
  # GET /messages
  # GET /messages.xml
  def index
    per_page = (params[:per_page] && params[:per_page].to_i <= MAX_MESSAGES_PER_PAGE) ? params[:per_page].to_i : DEFAULT_MESSAGES_PER_PAGE
    @messages = @list.messages.just_messages.paginate :page => params[:page], :per_page => per_page, :include => [:list, :phone]
    respond_to do |format|
      format.html
      format.js
      format.xml  { render :xml => @messages }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    @message = Message.find(params[:id])

    respond_to do |format|
      format.html { render :action => 'show.html.erb' }
      format.xml  { render :xml => @message }
    end
  end

  # GET /messages/new
  # GET /messages/new.xml
  # NOTE: do not mass-assign, messages does not use attr_accessible
  def new
    if params[:membership_id] then
      @obj = Membership.find(params[:membership_id])
    elsif params[:reply_id] then
      @obj = Reply.find(params[:reply_id])
    else
      @obj = List.find(params[:list_id])
    end

    @message = Message.create_from(@obj)
    
    if params[:content] then
      @message.content = params[:content]
    elsif flash[:message_content]
      @message.content = flash[:message_content]
    end
        
    respond_to do |format|
      format.html
      format.xml  { render :xml => @message }
      format.js
    end
  end

  # message gets sent by message_observer
  # NOTE: do not mass-assign, messages does not use attr_accessible
  #
  # a lot of this logic should be moved to a controller_helper maybe?
  # as it is duplicated in voices and web_messages
  def create
    raise BadParameters, 'Please specify a message parameter hash.' unless params[:message]

  	raise PermissionError, 'Your trial has expired, and you can no longer send text messages.' unless @list.creator.has_active_plan? or @list.creator.trial?

    @message = Message.new(params[:message])
    @message.sender = request.remote_ip

    @message.adfree = params[:message][:adfree]

    @message.list_id = params[:list_id]

    if params[:schedule] == "true"
      @message.schedule = true
      begin
        schedule_time = DateTime.strptime("#{params[:scheduled_day]} #{params[:scheduled_hour]}:#{params[:scheduled_minute]} #{params[:scheduled_ampm]}", "%m/%d/%Y %l:%M %P")
        @message.schedule_at = current_user.tz.local(schedule_time.year, schedule_time.month, schedule_time.day, schedule_time.hour, schedule_time.minute)
      rescue => e
        @message.schedule_at = nil
      end
    end

    respond_to do |format|
      if @message.save
        flash[:message_sent] = true
        format.html { 
          if params[:message_type] == 'test'
            flash[:notice] = 'Your message has been sent.'
            redirect_to new_list_message_path(params[:list_id])
          else
            redirect_to list_messages_path(params[:list_id]) 
          end
        }
      else
        format.html { render :action => "new" }
      end
    end
  rescue PermissionError => e
    respond_to do |format|
      format.html { 
        flash[:error] = e.to_xml
        render :action => "new"        
      } # maybe we'll make this nicer?
    end
  end

  def cancel
    @message = Message.find(params[:id])

    if @message.delayed_job_id
      delayed_job = Delayed::Job.find(@message.delayed_job_id)
      if delayed_job and delayed_job.locked_at.nil?
        delayed_job.destroy
        @message.status = 'cancelled'
        @message.save
      end
    end

    respond_to do |format|
      format.html { redirect_to list_messages_path(@message.list) }
      format.xml  { render :xml => @message }
    end
  end

end
