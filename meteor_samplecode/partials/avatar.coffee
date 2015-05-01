# Template uses Contact model to show user avatar
Template.avatar.helpers
  'has_avatar': ->
    if @avatar?.mini
      @avatar_src = @avatar.mini
    else if @gphoto_base64
      @avatar_src = "data:image/jpeg;base64,#{@gphoto_base64}"
    else if @gravatar_exist
      @avatar_src = Gravatar.imageUrl(@emails[0], {d: 404})
    else
      return false
    return true

  'get_username': ->
    render_user_name @, '?'

  'initial_name': ->
    initialName render_user_name @, '?'

  'get_bgcolor': ->
    @bgcolor || UserHelper.getDefaultUserBgColor()
