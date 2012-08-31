module ListsHelper

	# returns a hash with list_idS as keys and membership_countS as values
	# for each of this list 
	# display number of members in parens
	def member_count(list)
		pluralize list.memberships_count, 'subscriber'
	end

	def unread_replies(list)
		content_tag :div, link_to(pluralize(list.unread_reply_count, 'new reply')+'!', list_messages_path(list)), :class => 'unread_replies'
	end

	# this is the complicated logic that allows you to click on the list change menu
	# and stay in the same action, but be in your new list
	def change_list_menu_list_link(list, current)
		# link_text = list.to_s + ' <span class="count">(' + member_count(list) + ')</span>'
		link_text = list.to_s

		path = begin
			# if this request was not a get request, we'll just go to list overview
			# also, if its the current list, we'll go back to overview
			if request.get? and !current
				h = request.parameters.symbolize_keys

				# we don't want any id's, if its a list id, then we replace it below, otherwise its an id of some resource of a list, and we don't want to go there
				h.delete(:id)

				# figure out which parameter to inject
				list_id_key = h[:list_id] ? :list_id : :id
				h.merge!({list_id_key => list.to_param})
				url_for h
			end
		rescue # if something went wrong (like could not generate route), we'll just use list overview
			nil
		end

		# this goes here and not in rescue block because of conditions
		path = list_path(list) if path.nil?

		content_tag :li, link_to(link_text, path), :class => (current ? 'current' : nil)
	end

	def replace_list_id_with_default(path)
		if path.match %r{/lists/[-\w]+(.*)}
			'/lists/default' + $1
		end
	end

end
