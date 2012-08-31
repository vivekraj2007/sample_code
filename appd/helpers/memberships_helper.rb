module MembershipsHelper

	# a shortcut to whatever the default options is for the Add Members button and nav link
	# that way you can change this here instead of in application_helper and _action_nav and anywhere else it might need to be
	def add_members_path(list = @list)
		new_list_membership_path list
	end

	def admin_link_javascript(url)
		"$.post(#{url.to_json}, {_method: 'put'}, null, 'script')"
	end

	def make_admin_link(number)
		link_to_function('Make admin', admin_link_javascript(make_admin_list_membership_path(@list, number)))
	end

	def remove_admin_link(membership)
		'(' + link_to_function('remove admin', admin_link_javascript(remove_admin_list_membership_path(@list, membership))) + ')'
	end
end
