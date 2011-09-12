class EmailslistController < ApplicationController
	
	def index
		@message = "yo!"
	end	

	def abc123
		sql = 'SELECT * FROM users'
		@user = User.find_by_sql(sql)
	end
end
