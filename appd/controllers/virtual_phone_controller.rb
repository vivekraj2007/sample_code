class VirtualPhoneController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [ :create ]
  
  def index
  end

  def check_entire_queue
    
    @phones = []
    put_back = []
    
    Sparrow.new do |sparrow|
      while obj = sparrow.get(:queue => 'system') do
        # use array intersection to uniquely add phone numbers to this array
        @phones |= [obj[:phone]]
        put_back << obj.merge(:queue => 'system')
      end

      # while obj = sparrow.get(:queue => 'bender') do
      #   # use array intersection to uniquely add phone numbers to this array
      #   @phones |= [obj[:phone]]
      #   put_back << obj.merge(:queue => 'bender')
      # end

      while obj = sparrow.get
        @phones |= [obj[:phone]]
        put_back << obj
      end
      
      put_back.each do |obj|
        sparrow.send obj
      end
    end

    render :update do |page|
      page << '$("#phones_in_queue").empty();'
      @phones.each do |p|
        page << %Q{$('#phones_in_queue').append('<li><a href="#" onclick="add_phone_number(' + #{p.to_s.to_json} + ');$(this).parent().remove();return false">' + #{PhoneNumber.new(p).to_s.to_json} + '</a></li>');}
      end
    end
  end
  
  def clear_entire_queue    
    Sparrow.new do |sparrow|
      while obj = sparrow.get(:queue => 'system') do
        # throw them away
      end

      # while obj = sparrow.get(:queue => 'bender') do
      #   # throw them away
      # end

      while obj = sparrow.get
        # throw them away
      end
    end
    render :nothing => true
  end

  def show
    raise "VIRTUAL PHONE IS NOT AVAILABLE IN PRODUCTION" if Rails.env == 'production'
    
    return check_entire_queue if params[:id] == 'queue'
    return clear_entire_queue if params[:id] == 'clear_entire_queue'
    
    @phone = PhoneNumber.new(params[:id])
    # xml = Builder::XmlMarkup.new

    not_for_us = []
    @for_us = []

    Sparrow.new do |sparrow|
      while obj = sparrow.get(:queue => 'system') do
        logger.debug("GOT THIS SYSTEM MESSAGE: #{obj[:phone]} #{obj[:phone] == @phone.number ? ' <- me ' : ' '*7} #{obj.inspect}")
        if obj[:phone] == @phone.number
          @for_us << obj
        else
          not_for_us << obj.merge(:queue => 'system')
        end
      end

      # while obj = sparrow.get(:queue => 'bender') do
      #   logger.debug("GOT THIS BENDER MESSAGE: #{obj[:phone]} #{obj[:phone] == @phone.number ? ' <- me ' : ' '*7} #{obj.inspect}")
      #   if obj[:phone] == @phone.number
      #     @for_us << obj
      #   else
      #     not_for_us << obj.merge(:queue => 'bender')
      #   end
      # end

      while obj = sparrow.get
        logger.debug("GOT THIS MESSAGE: #{obj[:phone]} #{obj[:phone] == @phone.number ? ' <- me ' : ' '*7} #{obj.inspect}")
        if obj[:phone] == @phone.number
          @for_us << obj
        else
          not_for_us << obj
        end
      end
      
      not_for_us.each do |obj|
        sparrow.send obj
      end
    end

    respond_to do |wants|
       wants.xml { render :xml => xml }
       wants.js
    end
  rescue SparrowError
    render :nothing => true, :status => :service_unavailable # or 504
  end

  def create
    @phone = PhoneNumber.new(params[:phone])
    
    respond_to do |wants|
      wants.js
    end
  end
end
