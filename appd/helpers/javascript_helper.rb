module JavascriptHelper


	def js_vars_with_scope(scope)
		@_js_var_scope = scope
		yield
		@_js_var_scope = nil
	end

	def js_var(key, value, scope = @_js_var_scope)
		content_for(:javascript_in_footer) { "Tatango.reg(#{ key.to_json }, #{ value.to_json }#{ ", " + scope.to_json if scope });" }
	end

	def assign_i18n_for_javasrcipt
    js_var :I18n, I18n.backend.send(:translations)[I18n.locale.to_sym][:js] rescue nil
	end
	
	
	
	

	def javascript(*files)
		@included_javascripts ||= {}
		files.each do |file|
			content_for(:head) { javascript_include_tag file } unless @included_javascripts[file]
			@included_javascripts[file] = true
		end
	end

  # fade out a dom element after a certain length of time. all options are outlined in the default options hash
  def fade_after(dom, opts = {})
    options = {
      :time => 4000,
      :fade_time => 1200,
      :to   => 0.25
    }
    options.merge!(opts)
    content_for :javascript_in_head do
      %($(document).ready(function() {
    	  setTimeout(function() {$(#{dom.to_json}).fadeTo(#{options[:fade_time]},#{options[:to]}#{', function(){$(this).hide();}' if options[:hide]});},#{options[:time]});
    	});)
  	end
	end
  
  def javascript_for_head(b)    
    javascript_string = ''
  	javascript_string << @content_for_javascript_in_head if @content_for_javascript_in_head
    javascript_string << %($(document).ready(function() {
  		#{@content_for_dom_loaded_javascript}
  	}); ) if @content_for_dom_loaded_javascript
  	
  	javascript_string << %(
  	$(window).bind("load", function() {
  	  #{@content_for_window_loaded_javascript}
  	}); ) if @content_for_window_loaded_javascript
  	
    javascript_tag javascript_string unless javascript_string.empty?
  end
  

	def javascript_for_footer
		javascript_string = ''
		javascript_string << @content_for_javascript_in_footer if @content_for_javascript_in_footer
		javascript_tag javascript_string unless javascript_string.empty?
	end

  # NOTE: we turned protect from forgery off
  # there may be places where this needs to be used if we turn it back on
  def form_authenticity_token_for_ajax
    protect_against_forgery? ? "'authenticity_token=' + encodeURIComponent('#{form_authenticity_token}')" : "''"
  end
  
	
	
end
