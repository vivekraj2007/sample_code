require 'will_paginate'

class MembershipsController < ApplicationController
  layout 'internal'
	
	class AlreadyInList  < PreconditionError; end
	class AlreadyInvited  < PreconditionError; end
	class InvalidPhone    < PreconditionError; end
  before_filter :login_required
  before_filter :find_list, :admin_required
  
  # GET /memberships
  # GET /memberships.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => get_json}
    end
  end

  def show
    @membership = Membership.find params[:id]

    respond_to do |format|
      format.html
      format.js
      format.xml  { render :xml => @membership }
    end
  end

  # DELETE /memberships/1
  # DELETE /memberships/1.xml
  def destroy
    @membership = Membership.find(params[:id])
    
    @list = @membership.list
    @phone = @membership.phone
    
    @membership.update_attribute(:opted_out_at, Time.now) # TODO: test that this actually works now
    
    opt_out_method = 'tatango admin'
      
    Opt.create_from_phone_number_and_membership :out, @phone, @membership, :opt_out_method => opt_out_method, :list => @list
  
    flash[:notice] = "Subscriber was successfully removed from this list."
    respond_to do |format|
      format.html { redirect_back_or_default list_memberships_path(@list) }
      format.js
      format.xml  { head :ok }
    end
  end

  def make_admin
    phone_number = PhoneNumber.new(params[:number1] + params[:number2] + params[:number3])

    if phone_number.valid?
      phone = Phone[phone_number.to_s]
      
      if phone.nil?
        phone = Phone.create(:phone_number => phone_number)
      end

      membership = @list.membership_for(phone)
      
      if membership.nil?
        m = Membership.new
        m.list = @list
        m.phone = phone
        m.is_admin = true
        m.save
      else
        membership.update_attributes(:is_admin => true)
      end
    else
      flash[:error] = "That phone number is invalid."
    end

    redirect_to edit_list_path(@list)
  end

  def remove_admin
    @membership = @list.memberships.find(params[:id])
    @membership.update_attribute :is_admin, false
    
    redirect_to edit_list_path(@list)
  end

  private

  def get_json
    offset = params[:iDisplayStart].to_i
    limit = params[:iDisplayLength].to_i
    query = @list.memberships.joins("left join phones on phone_id = phones.id").offset(offset).limit(limit)

    if params[:sSearch] and !params[:sSearch].empty?
      query = query.where("number like ?", "%#{params[:sSearch].gsub(/[^0-9]/, "")}%")
    end

    i = 0
    while params.has_key?("iSortCol_#{i}".to_sym)
      sort = case params["iSortCol_#{i}".to_sym]
        when "0" then "number"
        when "1" then "carrier"
        when "2" then "memberships.created_at"
        when "3" then "memberships.opted_out_at"
        else nil
      end

      if sort
        if !params.has_key?("sSortDir_#{i}") or params["sSortDir_#{i}"] != "asc"
          query = query.order("#{sort} desc")
        else
          query = query.order("#{sort} asc")
        end
      end
      
      i += 1
    end
    
    aaData = query.collect{|membership|
      [ 
        membership.name,
        membership.phone ? membership.phone.carrier_name : "",
        membership.created_at ? membership.created_at.strftime("%m/%d/%Y %I:%M%P") : "",
        membership.opted_out_at ? membership.opted_out_at.strftime("%m/%d/%Y %I:%M%P") : "",
        url_for([@list, membership])
      ]
    }

    result = {
      sEcho: params[:sEcho],
      iTotalRecords: @list.memberships.count,
      iTotalDisplayRecords: @list.memberships.count,
      aaData: aaData
    }

    return result
  end
end
