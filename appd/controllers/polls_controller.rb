class PollsController < ApplicationController
  layout 'internal'
  
  before_filter :login_required
  before_filter :admin_required

# GET /polls/1
  # GET /polls/1.xml
  def show
    @poll = Poll.find(params[:id])
    @keyword = @poll.keyword

    if @keyword.nil?
      @keyword = Keyword.new(:name => "")
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @poll }
    end
  end

  # PUT /polls/1
  # PUT /polls/1.xml
  def update
    @poll = Poll.find(params[:id])
    @keyword = @poll.keyword

    if @keyword.nil? and params[:keyword] and params[:keyword][:name]
      @keyword = Keyword.new(:name => params[:keyword][:name])
      if !@keyword.save
        flash[:error] = "There were errors updating your poll: " + @poll.errors.full_messages.to_sentence
        format.html { render :action => 'edit' }
        format.xml { render :xml => @poll.errors, :status => :unprocessable_entity }

        return
      end

      @poll.keyword = @keyword
    end

    if params[:poll] and params[:poll][:message]
      params[:poll][:message].gsub!(/\r\n?/,"\n")
    end

    respond_to do |format|
      if @poll.update_attributes(params[:poll]) and (params[:keyword].nil? or @poll.keyword.update_attributes(params[:keyword]))
        format.html { redirect_to(@poll, :notice => 'Poll was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @poll.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /polls/1
  # DELETE /polls/1.xml
  def destroy
    @poll = Poll.find(params[:id])
    @poll.destroy

    respond_to do |format|
      format.html { redirect_to(keywords_url) }
      format.xml  { head :ok }
    end
  end

  def export
    poll = Poll.find(params[:id])

    keyword_name = poll.resolved_name

    response.headers["Content-Disposition"] = "attachment; filename=\"#{keyword_name} Subscribers.csv\""
    response.headers["Content-Type"] = "text/csv"

    tz = poll.creator.tz
    
    self.response_body = Enumerator.new do |y|
      y << "\"Mobile Phone\",\"Carrier\",\"Subscribed\",\"Keyword\",\"Messages Received\"\n"
      poll.poll_responses.group(:phone_id).joins(:phone).select("phones.number, phones.carrier, poll_responses.created_at, (select count(*) from poll_responses where phone_id = phones.id and poll_id = poll_responses.poll_id) as messages_received").each{|row|
        y << "\"#{PhoneNumber.new(row["number"])}\","
        y << "\"#{CARRIERS[row["carrier"]]}\","
        y << "\"#{row["created_at"].in_time_zone(tz)}\","
        y << "\"#{keyword_name}\","
        y << "\"#{row["messages_received"]}\""
        y << "\n"
      }
    end
  end
end
