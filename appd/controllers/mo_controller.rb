# networktext gateway should post to /mo (MOController#create)
class MoController < ApplicationController
  skip_before_filter :verify_authenticity_token
  
  before_filter :verify_host
  
  # this is where the tatango Gateway posts to
  def create
    handler = MO::Handler.new params[:message]
    handler.process
    render :nothing => true, :status => :accepted
  rescue MO::Handler::PreconditionError => e
    render :xml => e.to_xml, :status => :precondition_failed
  end
  
  # send an error if the user used GET instead of POST
  def show
    render :nothing => true, :status => :method_not_allowed
  end
  
  private
  
  def verify_host
    logger.debug('VERIFY HOST:' + request.remote_ip)

    return true if Rails.env != "production"

    case request.remote_ip
    when '127.0.0.1', 'localhost', /\.tatango\.com$/, '::1', '173.203.106.156', '108.166.98.87'
      true # everything is good, continue
    else
      logger.warn "UNAUTHORIZED MO Request from:" + request.remote_ip
      render :nothing => true, :status => :unauthorized
    end
  end
end
