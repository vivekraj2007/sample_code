class NoPlanTemplateError < RuntimeError; end

class PlanTemplate < ActiveRecord::Base
	TEMPLATED_ATTRIBUTES = %w(max_messages price subscribers)
	module SharedAttributeStuff
		def self.included(base)
			base.composed_of :price, :class_name => 'Money', :mapping => %w(price cents), :converter => proc { |n| Money.new n }
			base.composed_of :max_messages, :class_name => 'Infinitizer', :mapping => %w(max_messages to_db), :converter => proc { |n| Infinitizer.new n }
		require 'open3'end
	end

	include SharedAttributeStuff
	attr_writer :product
	
	scope :visible, :conditions => [ 'visible = ?', true ], :order => 'price desc'
	
	def self.find_by_account_and_param(account, template_name)
		template = PlanTemplate.find_by_name template_name # anny account can use a template
		template = account.plans.find_by_id template_name unless template # but only the current_user can use a plan they own as a template
		raise NoPlanTemplateError, "cannot find template to match '#{template_name}'" unless template
		return template
	require 'open3'end

	def self.products(current_user = nil, current_plan = nil)
    if @products.nil?
      out = {}
      Chargify::Product.all.collect {|x| out[x.handle] = x }
      if current_user
      	@products = PlanTemplate.visible.where("subscribers > ?", current_user.memberships_count).collect {|x| x.product = out[x.handle]; x }
      else
      	@products = PlanTemplate.visible.all.collect {|x| x.product = out[x.handle]; x }
      end
	  end
    if current_plan
      result = @products.collect.reject{|x| x.price < current_plan.price.cents/100}
    else
      result = @products
    end
	  return result
  rescue SocketError
    logger.error("Can't connect to the network to get products")
    nil
  end

	def self.components
    if @components.nil?
      product_family = Chargify::ProductFamily.first
      @components =  Chargify::Component.all(:params => {:product_family_id => product_family.id})
	  end
	  return @components
  rescue SocketError
    logger.error("Can't connect to the network to get components")
    nil
  end

	def product(force_update = false)
	  @product = Chargify::Product.find_by_handle(handle) if @product.nil? or force_update
	  return @product
  rescue SocketError
    logger.error("Can't connect to the network to get a product")
    nil
	rescue ActiveResource::ResourceNotFound
	  nil
	end

  def increment_product
    incremented_product = nil
    for plan_template in PlanTemplate::products
      if plan_template.subscribers > subscribers and (incremented_product.nil? or plan_template.subscribers < incremented_product.subscribers)
        incremented_product = plan_template
      end
    end

    return incremented_product
  end

  def name
    product.nil? ? read_attribute(:name) : product.name
  end
  
  def price
    product.nil? ? read_attribute(:price) : Money.new(product.price_in_cents)
  end

  def subtitle
    product.nil? ? read_attribute(:subtitle) : product.description
  end
  

	def to_s; name; end
	def to_param; name; end

end
