# a general exception that actions can use for cleaner flow
#
# NOTE: added on 2008-06-23, a lot of code does not use this,
# feel free to convert
class PreconditionError < RuntimeError
  def message
    to_s.underscore.humanize
  end
end

class BlacklistedException < PreconditionError; end
class PermissionError < PreconditionError; end
class InvalidPhoneNumber < PreconditionError; end
class BadParameters < PreconditionError; end

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  include AuthenticatedSystem

  before_filter :set_user_time_zone


def render_optional_error_file(status_code)
		 status = interpret_status(status_code)
		 path = "#{Rails.root}/app/views/#{status[0,3]}.html.erb" #TODO: fix for other formats
		p path
		if File.exist?(path)
			render :file => path, :status => status, :layout=> 'application'
		else
			head status
		end
end

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => '7b0eacaa187eca7adc3a9a6a7936a1e5'

  private
  def set_user_time_zone
    Time.zone = current_user.tz rescue nil
  end
  

	def tatango_office_required
		case request.remote_ip
		when '127.0.0.1', '63.229.10.168'
		  return true
		end

		raise PermissionError
	end
  
  def admin_required
    if request.cookies["__utma"] and request.cookies["__utma"].split(".").size > 1
      utma_id = request.cookies["__utma"].split(".")[1].to_i

      if request.cookies["__utmz"]
        traffic_cookie = TrafficCookie.first(:conditions => ["utma_id = ?", utma_id], :order => "created_at desc")

        if traffic_cookie.nil? or traffic_cookie.utmz != request.cookies["__utmz"]
          TrafficCookie.create(:utma_id => utma_id, :utmz => request.cookies["__utmz"])
        end
      end
    
      if current_user and !(current_user.utmas.split(",").include?(utma_id.to_s))
        current_user.update_attribute(:utmas, (current_user.utmas.split(",") << utma_id.to_s).join(","))
      end
    end

    if current_user and request.cookies["__utmz"] and !request.cookies["__utmz"].empty? and current_user.source_cookie.nil?
      current_user.update_attribute(:source_cookie, request.cookies["__utmz"])
    end

    if current_user and (current_user.delinquent? or current_user.expired? or current_user.canceled?)
      if current_user.delinquent?
        redirect_to(edit_plan_url(:cc=>'update', :protocol => (request.remote_ip=='127.0.0.1' or !Rails.env.production?) ? 'http' : 'https'))
      elsif current_user.canceled?
        redirect_to(edit_plan_url(:protocol => (request.remote_ip=='127.0.0.1' or !Rails.env.production?) ? 'http' : 'https'))
      else
        redirect_to(new_plan_url)
      end
    elsif current_user and current_user.has_active_plan? and current_user.zip.nil?
      redirect_to(edit_zip_account_url(:protocol => (request.remote_ip=='127.0.0.1' or !Rails.env.production?) ? 'http' : 'https'))
    elsif @list then
      admin_required_no_redirect
    end
  end

  def admin_required_no_redirect
    if @list.creator.id != current_user.id
      @list = nil
      redirect_to account_path
    end
  end

  def find_list
    @list = List.find params[:list_id] || params[:id] unless %w(default all last home).include?(params[:id])
  end
  
  # use this in a before_filter if you like
  def no_cache
    response.headers["Last-Modified"] = Time.now.httpdate
    response.headers["Expires"] = 0
    # HTTP 1.0
    response.headers["Pragma"] = "no-cache"
    # HTTP 1.1 'pre-check=0, post-check=0' (IE specific)
    response.headers["Cache-Control"] = 'no-store, no-cache, must-revalidate, max-age=0, pre-check=0, post-check=0'
    
    # content_for :head do
    #   '<meta http-equiv="Pragma" content="no-cache" /> '
    # end
  end
  

	def blacklisted_user_redirect
		session[:user_id] = nil
		cookies[:auth_token] = nil
		flash[:error] = I18n.t(:'flash.errors.account_suspended')
		redirect_to '/login'
	end
  
  def ensure_secure
    if !request.ssl? and Rails.env.production? and request.env['HTTP_X_FORWARDED_PROTO']
      params[:protocol] = "https://"
      redirect_to params
    end
  end

#  rescue_from ActionController::RoutingError, :with => :render_404
#  rescue_from ActiveRecord::RecordNotFound, :with => :render_404
#  rescue_from Exception, :with => :render_500 if Rails.env.production?
  
  def render_404(e)
    render :template => "404", :layout => (current_user ? 'internal' : 'application'), :status => 404
  end

  def render_500(e)
    logger.error e
    ExceptionNotifier::Notifier.background_exception_notification(e)
    render :template => "500", :layout => (current_user ? 'internal' : 'application'), :status => 500
  end
end
