class CmxForwardsController < ApplicationController
  def index
    CmxForward.create(:params => params.to_json, :body => request.body.read)

    render :text => ""
  end

  def create
    CmxForward.create(:params => params.to_json, :body => request.body.read)

    render :text => ""
  end
end
