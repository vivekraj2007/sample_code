class QuestionsController < ApplicationController
  layout 'static'

  # GET /questions
  # GET /questions.xml
  def index
    redirect_to 'http://tatango.zendesk.com/', :status => :moved_permanently
  end

  # GET /questions/1
  # GET /questions/1.xml
  def show
    redirect_to 'http://tatango.zendesk.com/', :status => :moved_permanently
  end

  def contact
    redirect_to('http://tatango.zendesk.com/anonymous_requests/new', :status => :moved_permanently) if params[:select_question].nil?
  end
end
