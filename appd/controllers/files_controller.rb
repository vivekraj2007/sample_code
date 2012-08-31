class FilesController < ApplicationController
  FILES = {"beginner" => "Beginner's Guide to SMS Marketing.pdf"}
  def download
    if FILES.has_key?(params[:file])
      if params[:account_id]
        Thread.new(current_user) do |account_id|
          account = Account.find(account_id)

          if account
            account.salesforce_downloaded_guide
          end
        end
      elsif current_user
        Thread.new(current_user) do |account|
          account.salesforce_downloaded_guide
        end
      end

      send_file File.join("public/files", FILES[params[:file]])
    else
      render :file => "#{Rails.root}/app/views/404.html.erb", :layout => 'application', :status => 404
    end
  end
end
