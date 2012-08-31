class ListsController < ApplicationController
  layout 'internal'

  before_filter :login_required
  before_filter :admin_required
  before_filter :redirect_if_missing_required

  # list overview with join feed and announcements
	def show
		@list = List.find(params[:id])

    current_user.save

    per_page = (params[:per_page] && params[:per_page].to_i <= MessagesController::MAX_MESSAGES_PER_PAGE) ? params[:per_page].to_i : MessagesController::DEFAULT_FEED_MESSAGES_PER_PAGE
    @feed = @list.events.paginate :page => params[:page], :per_page => per_page, :include => :list


    respond_to do |format|
      format.html
      format.js
      format.rss
      format.xml { render :xml => @feed.to_xml(:for => :feed) }
    end
	end

  # GET /lists/1/edit
  def edit
    @list = List.find(params[:id])
    @keyword = @list.keyword

    if @keyword.nil?
      @keyword = Keyword.new(:name => "")
    end
  end
  
  # PUT /lists/1
  # PUT /lists/1.xml
  def update
    @list = List.find(params[:id])
    @keyword = @list.keyword

    if @keyword.nil? and params[:keyword] and params[:keyword][:name]
      @keyword = Keyword.new(:name => params[:keyword][:name])
      if !@keyword.save
        flash[:error] = "There were errors updating your list: " + @list.errors.full_messages.to_sentence
        format.html { render :action => 'edit' }
        format.xml { render :xml => @list.errors, :status => :unprocessable_entity }

        return
      end

      @list.keyword = @keyword
    end
    
    if params[:list] and params[:list][:bounceback]
      params[:list][:bounceback].gsub!(/\r\n?/,"\n")
    end
    
    respond_to do |format|
      if @list.update_attributes(params[:list]) and @list.keyword.update_attributes(params[:keyword])
        flash[:notice] = 'List was successfully updated.'
        format.html { redirect_to(edit_list_path(@list)) }
        format.xml { head :ok }
      else
        flash[:error] = "There were errors updating your list: " + @list.errors.full_messages.to_sentence
        format.html { render :action => 'edit' }
        format.xml { render :xml => @list.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lists/1
  # DELETE /lists/1.xml
  def destroy
    @list = List.find(params[:id])
    @list.destroy
    flash[:notice] = t(:'flash.success.delete_list')

    if current_user.plan and current_user.plan.subscription
      subscription = current_user.plan.subscription
      for component in subscription.components
        if component.unit_name == 'list'
          component.allocated_quantity = current_user.additional_lists
          component.save
          break
        end
      end
    end
  
    respond_to do |format|
      format.html { redirect_to keywords_path }
      format.xml  { head :ok }
    end
  end
  
  def export
    list = List.find(params[:id])
    
    keyword_name = list.resolved_name

    response.headers["Content-Disposition"] = "attachment; filename=\"#{keyword_name} Subscribers.csv\""
    response.headers["Content-Type"] = "text/csv"

    tz = list.creator.tz

    self.response_body = Enumerator.new do |y|
      y << "\"Mobile Phone\",\"Carrier\",\"Status\",\"Subscribed\",\"Unsubscribed\",\"Keyword\",\"Messages Received\"\n"
      list.memberships.joins(:phone).select("phones.number, phones.carrier, memberships.created_at, memberships.opted_out_at, (select count(*) from messages where list_id = memberships.list_id and event_id is null and phone_id is null and created_at > memberships.created_at and (memberships.opted_out_at is null or created_at < memberships.opted_out_at)) as messages_received").each{|row|
        y << "\"#{PhoneNumber.new(row["number"])}\","
        y << "\"#{CARRIERS[row["carrier"]]}\","
        y << "\"#{row["opted_out_at"].nil? ? "Subscribed" : "Unsubscribed"}\","
        y << "\"#{row["created_at"].in_time_zone(tz)}\","
        y << "\"#{row["opted_out_at"] and row["opted_out_at"].in_time_zone(tz)}\","
        y << "\"#{keyword_name}\","
        y << "\"#{row["messages_received"]}\""
        y << "\n"
      }
    end

  end
  
  private
  def redirect_if_missing_required
    if current_user.name.nil? or current_user.email.nil?
      flash[:error] = t(:'flash.errors.empty_fields')
      redirect_to account_path
    end
  end
end
