require 'rss/2.0'
require 'open-uri'

module TatangoHelper


	def tabs(dom_element, opts = {})
		content_for :head do
			stylesheet_link_tag('jquery-tabs.css')
		end unless @tabs_loaded
		@tabs_loaded = true

		content_for :dom_loaded_javascript do
			%{$("#{dom_element}").tabs(#{options_for_javascript opts});}
		end
	end

	def google_maps_api_key
		case Rails.env
    when 'production' # tatango.com
      'ABQIAAAAJmQPJ5LY_2vMcAuRP4FT7RSgnWDZeT1t2752aNDcy5SYXR6-PhQfQMR1NSfHax2rmesPmFNMXrkkgw'
    when 'test' # localhost:4000
      'ABQIAAAAHBYCY-5zYgYgZ38Jam-5nxT-ZTKVLgdLz0ZRRJYP7ttYbtpFeBQ7aIZOAkFZaA-O-z7YeIsTzd9Vvw'
    else # localhost:3000
      'ABQIAAAAHBYCY-5zYgYgZ38Jam-5nxTJQa0g3IQ9GZqIMmInSLzwtGDKaBTpLwTV0s4xvUa4ig5C6-bGmrpAKg'
    end
	end

end
