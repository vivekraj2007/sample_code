class CarrierController < ApplicationController
  def create
    phone = Phone[params[:number]]

    if phone and phone.carrier == 0
      phone.update_attribute(:carrier, params[:carrier])
    end
    
    render :text => "OK #{phone.inspect} #{params[:number]} #{params[:carrier]}"
  end
end
