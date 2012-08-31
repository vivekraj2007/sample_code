class AutorespondersController < ApplicationController
  layout 'internal'
  
  before_filter :login_required
  before_filter :admin_required

# GET /autoresponders/1
  # GET /autoresponders/1.xml
  def show
    @autoresponder = Autoresponder.find(params[:id])
    @keyword = @autoresponder.keyword

    if @keyword.nil?
      @keyword = Keyword.new(:name => "")
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @autoresponder }
    end
  end

  # PUT /autoresponders/1
  # PUT /autoresponders/1.xml
  def update
    @autoresponder = Autoresponder.find(params[:id])
    @keyword = @autoresponder.keyword

    if @keyword.nil? and params[:keyword] and params[:keyword][:name]
      @keyword = Keyword.new(:name => params[:keyword][:name])
      if !@keyword.save
        flash[:error] = "There were errors updating your autoresponder: " + @autoresponder.errors.full_messages.to_sentence
        format.html { render :action => 'edit' }
        format.xml { render :xml => @autoresponder.errors, :status => :unprocessable_entity }

        return
      end

      @autoresponder.keyword = @keyword
    end

    if params[:autoresponder] and params[:autoresponder][:message]
      params[:autoresponder][:message].gsub!(/\r\n?/,"\n")
    end

    respond_to do |format|
      if @autoresponder.update_attributes(params[:autoresponder]) and (params[:keyword].nil? or @autoresponder.keyword.update_attributes(params[:keyword]))
        format.html { redirect_to(@autoresponder, :notice => 'Autoresponder was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @autoresponder.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /autoresponders/1
  # DELETE /autoresponders/1.xml
  def destroy
    @autoresponder = Autoresponder.find(params[:id])
    @autoresponder.destroy

    respond_to do |format|
      format.html { redirect_to(keywords_url) }
      format.xml  { head :ok }
    end
  end

  def random_response
    autoresponder = Autoresponder.find(params[:id])
    
    render :json => autoresponder.autoresponder_responses.first(:group => 'phone_id', :order => 'RAND()').to_json({:include => {:phone => {:methods => :to_s}}})
  end

  def export
    autoresponder = Autoresponder.find(params[:id])

    keyword_name = autoresponder.resolved_name

    response.headers["Content-Disposition"] = "attachment; filename=\"#{keyword_name} Subscribers.csv\""
    response.headers["Content-Type"] = "text/csv"

    tz = autoresponder.creator.tz
    
    self.response_body = Enumerator.new do |y|
      y << "\"Mobile Phone\",\"Carrier\",\"Subscribed\",\"Keyword\",\"Messages Received\"\n"
      autoresponder.autoresponder_responses.group(:phone_id).joins(:phone).select("phones.number, phones.carrier, autoresponder_responses.created_at, (select count(*) from autoresponder_responses where phone_id = phones.id and autoresponder_id = autoresponder_responses.autoresponder_id) as messages_received").each{|row|
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
