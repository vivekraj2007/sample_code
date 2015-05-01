Template.likers.likers = ->
  @

Template.likers.gphoto_base64 = ->
  contact = Contacts.findOne({emails: @emails[0]})
  contact.gphoto_base64 if contact

Template.likers.gravatar_exist = ->
  contact = Contacts.findOne({emails: @emails[0]})
  contact.gravatar_exist if contact

Template.likers.initialName = ->
  initialName @fullname

Template.likers.bgcolor = ->
  UserHelper.getBgColorByEmail(@emails[0])

Template.likers.helpers
  liker_gavatar: ->
    Gravatar.imageUrl(@emails[0], {d: 404})

  too_more: ->
    @.length > 10