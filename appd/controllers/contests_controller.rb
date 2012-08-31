class ContestsController < ApplicationController
  layout 'internal'
  
  before_filter :login_required
  before_filter :admin_required

# GET /contests/1
  # GET /contests/1.xml
  def show
    @contest = Contest.find(params[:id])
    @keyword = @contest.keyword

    if @keyword.nil?
      @keyword = Keyword.new(:name => "")
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @contest }
    end
  end

  # PUT /contests/1
  # PUT /contests/1.xml
  def update
    @contest = Contest.find(params[:id])
    @keyword = @contest.keyword

    if @keyword.nil? and params[:keyword] and params[:keyword][:name]
      @keyword = Keyword.new(:name => params[:keyword][:name])
      if !@keyword.save
        flash[:error] = "There were errors updating your contest: " + @contest.errors.full_messages.to_sentence
        format.html { render :action => 'edit' }
        format.xml { render :xml => @contest.errors, :status => :unprocessable_entity }

        return
      end

      @contest.keyword = @keyword
    end

    if params[:contest] and params[:contest][:message]
      params[:contest][:message].gsub!(/\r\n?/,"\n")
    end

    respond_to do |format|
      if @contest.update_attributes(params[:contest]) and (params[:keyword].nil? or @contest.keyword.update_attributes(params[:keyword]))
        format.html { redirect_to(@contest, :notice => 'Contest was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @contest.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /contests/1
  # DELETE /contests/1.xml
  def destroy
    @contest = Contest.find(params[:id])
    @contest.destroy

    respond_to do |format|
      format.html { redirect_to(keywords_url) }
      format.xml  { head :ok }
    end
  end

  def select_winner
    contest = Contest.find(params[:id])

    response = contest.contest_responses.first(:group => 'phone_id', :order => 'RAND()')

    if response
      contest.update_attributes(:winner_phone_id => response.phone_id)
      
      render :text => response.phone.to_s
    else
      render :text => ""
    end
  end

  def export
    contest = Contest.find(params[:id])

    keyword_name = contest.resolved_name

    response.headers["Content-Disposition"] = "attachment; filename=\"#{keyword_name} Subscribers.csv\""
    response.headers["Content-Type"] = "text/csv"

    tz = contest.creator.tz
    
    self.response_body = Enumerator.new do |y|
      y << "\"Mobile Phone\",\"Carrier\",\"Subscribed\",\"Keyword\",\"Messages Received\"\n"
      contest.contest_responses.group(:phone_id).joins(:phone).select("phones.number, phones.carrier, contest_responses.created_at, (select count(*) from contest_responses where phone_id = phones.id and contest_id = contest_responses.contest_id) as messages_received").each{|row|
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
