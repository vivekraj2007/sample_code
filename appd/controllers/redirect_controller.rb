class RedirectController < ApplicationController
  def catch_all
    redirects = Redirect.all

    url = '/' + params[:url]

    for redirect in redirects
      if url.match(Regexp.new("^#{redirect.pattern}$"))
        redirect_to url.gsub(Regexp.new("^#{redirect.pattern}$"), redirect.target), :status => (redirect.permanent ? 301 : 302)
        return
      end
    end

    render :file => "#{Rails.root}/app/views/404.html.erb", :layout => 'application', :status => 404
  end
end
