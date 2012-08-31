class KeywordsController < ApplicationController
  layout 'internal'
  
  before_filter :login_required
  before_filter :admin_required

	def index
    @keyword_objects = []
    @keyword_objects += List.all(:conditions => ["created_by = ?", current_user.id])
    @keyword_objects += Autoresponder.all(:conditions => ["created_by = ?", current_user.id])
    @keyword_objects += Contest.all(:conditions => ["created_by = ?", current_user.id])
    @keyword_objects += Poll.all(:conditions => ["created_by = ?", current_user.id])

    @new_keyword = Keyword.new
		respond_to do |format|
			format.html
		end
	end
 
  def broadcasts
    @keyword_objects = []
    @keyword_objects += List.all(:conditions => ["created_by = ?", current_user.id])

    @new_keyword = Keyword.new
		respond_to do |format|
			format.html{ render :action => 'index' }
		end
	end

  def autoresponders
    @keyword_objects = []
    @keyword_objects += Autoresponder.all(:conditions => ["created_by = ?", current_user.id])

    @new_keyword = Keyword.new
		respond_to do |format|
			format.html{ render :action => 'index' }
		end
	end
  
  def polls
    @keyword_objects = []
    @keyword_objects += Poll.all(:conditions => ["created_by = ?", current_user.id])

    @new_keyword = Keyword.new
		respond_to do |format|
			format.html{ render :action => 'index' }
		end
	end

  def contests
    @keyword_objects = []
    @keyword_objects += Contest.all(:conditions => ["created_by = ?", current_user.id])

    @new_keyword = Keyword.new
		respond_to do |format|
			format.html{ render :action => 'index' }
		end
	end

  def test
    @keyword = Keyword.new(:name => params[:name].strip)

    respond_to do |format|
      if @keyword.valid?
        logger.error("Valid")
        format.xml  { render :xml => @keyword }
        format.js { render :json => @keyword }
      else
        logger.error("Inalid")
        format.xml { render :xml => Keyword.new }
        format.js { render :json => @keyword.errors }
      end
    end
  end

  def create
    return redirect_to(account_path) unless params[:keyword]
   
    add_query = {}
    if current_user.trial? and ((params[:keywordtype] == "list" and current_user.created_lists.size != 0) or (params[:keywordtype] == "autoresponder" and current_user.created_autoresponders.size != 0))
      flash[:error] = "Trial users may not create new keywordss."
      return redirect_to account_path
    elsif current_user.trial?
      add_query = {:first => "keyword", :s => current_user.source}
    end

    @keyword = Keyword.create(params[:keyword])

    if !@keyword.errors.empty?
      raise ActiveRecord::RecordInvalid, @keyword
    end

    if params[:keywordtype] == "list"
      @keyword_object = List.new
      begin
        params[:list][:bounceback].gsub!(/\r\n?/,"\n")
        @keyword_object.bounceback = params[:list][:bounceback]
      rescue => e
      end
    elsif params[:keywordtype] == "contest"
      @keyword_object = Contest.new
      begin
        params[:contest][:message].gsub!(/\r\n?/,"\n")
        @keyword_object.message = params[:contest][:message]
      rescue => e
      end
    elsif params[:keywordtype] == "poll"
      @keyword_object = Poll.new
      begin
        params[:poll][:message].gsub!(/\r\n?/,"\n")
        @keyword_object.message = params[:poll][:message]
      rescue => e
      end
    else
      @keyword_object = Autoresponder.new
      begin
        params[:autoresponder][:message].gsub!(/\r\n?/,"\n")
        @keyword_object.message = params[:autoresponder][:message]
      rescue => e
      end
    end
    @keyword_object.created_by = current_user.id
    if @keyword_object.save
      if @keyword_object.is_a?(List)
        @keyword.update_attribute(:list_id, @keyword_object.id)
      elsif @keyword_object.is_a?(Contest)
        @keyword.update_attribute(:contest_id, @keyword_object.id)
      elsif @keyword_object.is_a?(Poll)
        @keyword.update_attribute(:poll_id, @keyword_object.id)
      elsif @keyword_object.is_a?(Autoresponder)
        @keyword.update_attribute(:autoresponder_id, @keyword_object.id)
      end

      current_user.salesforce_update_background
      
      flash[:newkeyword] = true

      respond_to do |format|
        # wow, you cant just edit here, also change this in create.js.rjs
        format.html { redirect_to @keyword_object.is_a?(List) ? list_path(@keyword_object, add_query) : 
                                  (@keyword_object.is_a?(Contest) ? contest_path(@keyword_object, add_query) : 
                                  (@keyword_object.is_a?(Poll) ? poll_path(@keyword_object, add_query) : autoresponder_path(@keyword_object, add_query))) }
      end
    else
      raise PreconditionError
    end

  rescue PreconditionError, ActiveRecord::RecordInvalid => e
    flash.now[:error] = 'There was an error creating your keyword.'
    flash[:attempt_name] = params[:keyword][:name]
    if params[:list]
      flash[:attempt_bounceback] = params[:list][:bounceback]
    end
    if params[:autoresponder]
      flash[:attempt_message] = params[:autoresponder][:message]
    end
    if params[:contest]
      flash[:attempt_message] = params[:contest][:message]
    end
    if @keyword
      @keyword.destroy
    end
    respond_to do |format|
      format.html { redirect_to keywords_path }
    end
  end
end
