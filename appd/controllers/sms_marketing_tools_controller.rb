require 'open3'

class SmsMarketingToolsController < ApplicationController
  def sms_qr_code_image
    keyword = params[:keyword][0..14] rescue ""
    shortcode = params[:shortcode][0..4] rescue ""
    qr = "http://chart.apis.google.com/chart?chs=275x295&cht=qr&chl=smsto%3A#{URI.escape(shortcode)}%3A#{URI.escape(keyword)}&choe=UTF-8"

    bottom_text = "Scan or text #{keyword} to #{shortcode}."

    img = Magick::Image.read(qr).first
    gc = Magick::Draw.new
    gc.font_family = 'helvetica'
    gc.pointsize = 12
    gc.annotate(img, 50, 50, 35, 265, bottom_text){
      self.fill = "black"
    }
    
    gc.font_family = 'helvetica'
    gc.pointsize = 10
    gc.annotate(img, 50, 50, 35, 280, "Msg&Data rates may apply.\nOpt-out, text STOP. T&C, text HELP."){
      self.fill = "black"
    }

    if params[:disposition] == 'attachment'
      response.headers['Content-Disposition'] = 'attachment; filename="qrcode-tatango.png"'
    end
    render :text => img.to_blob, :content_type => 'image/png'
  end

  def flyer_generator_download
    FlyerGeneratorDownload.create({:reward => params[:reward], :shortcode => params[:shortcode], :organization => params[:organization], :message => params[:message], :keyword => params[:keyword], :volume => params[:volume], :account_id => (current_user.nil? ? nil : current_user.id)})

    fp = open("lib/templates/flyer.html", "r")
    template = fp.read
    fp.close

    template.gsub!("ROOTURL","#{Dir.pwd}/app/assets")
    template.gsub!("MESSAGE",(params[:message] or ""))
    template.gsub!("REWARD",(params[:reward] or ""))
    template.gsub!("KEYWORD",(params[:keyword] or "").upcase)
    template.gsub!("SHORTCODE",(params[:shortcode] or ""))
    template.gsub!("ORGANIZATION",(params[:organization] or ""))
    if params[:volume] and params[:volume].size > 0
      template.gsub!("VOLUME",params[:volume])
    else
      template.gsub!(/<!-- X -->.*<!-- Y -->/,'')
    end

    stdin, stdout, stderr = Open3.popen3("vendor/wkhtmltopdf-amd64 --margin-bottom 5mm --margin-left 5mm --margin-right 5mm --margin-top 5mm --page-size Letter --zoom 3 - -")
    stdin.puts template
    stdin.close
    result = stdout.read
    stdout.close

    render :text => result, :content_type => "application/pdf", :x_sendfile=>true
  end
end
