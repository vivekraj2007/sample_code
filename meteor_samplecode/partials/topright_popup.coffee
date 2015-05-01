@displayAddGoogleOauth = () ->
  displayAddGoogleOauth = false
  if Meteor.user()
    user = Meteor.users.findOne({'services.google': {$exists: true}})
    displayAddGoogleOauth = !(user && user.services.google.email)
  #FIXME: enable this code if there are a request to keep hiding popup 
  return displayAddGoogleOauth && !Session.get("HideOauth")
  # return displayAddGoogleOauth

@displayAddFbOauth = () ->
  displayAddFbOauth = false
  if Meteor.user()
    user = Meteor.users.findOne({'services.facebook': {$exists: true}})
    displayAddFbOauth = !(user && user.services.facebook.email)
  #FIXME: enable this code if there are a request to keep hiding popup 
  return displayAddFbOauth && !Session.get("HideOauth")
  # return displayAddFbOauth

Template.topright_popup.display_user_mention = ->
  UserMention.getInstance().getFoundUsers()?.length > 0

Template.topright_popup.display_register = ->
  return Meteor.user() == null

Template.topright_popup.display_add_oauth = ->
  unless SettingsHelper.isEnableOauthPopup()
    return false
  return displayAddGoogleOauth() and displayAddFbOauth()

Template.topright_popup.need_signup = ->
  return Session.get("IS_NEW_USER") && Session.equals("IS_NEW_USER", true)

Template.topright_popup.events
  'click #topright-popup .btn-close': (e) ->
    $(e.target).closest(".float-popup").hide()
   
Template.ban_popup.events
  'click #ban-popup button#prompt-ban-undo': (e) ->
    $("#ban-popup").hide()
    data_email = $('#ban-popup').find('button#prompt-ban-undo').attr("data-email")
    key = 'Banned-' + data_email
    bannedUser = Session.get(key)
    if bannedUser != null
      checkBanUser = Contacts.findOne({_id: bannedUser._id })
      console.log 'checkBanUser: ' + checkBanUser
      if checkBanUser
        # Card#583 we don't remove contact when ban it, we just update archived to true
        # So, we only update it to false when user click 'Undo delete' button
        Contacts.update({_id: bannedUser._id},{$set : {archived: false}})
      Session.set(Session.get('BanCache')[0],Session.get('BanCache')[0])
      Session.set('BanCache',null)
      Session.set(key, null)

Template.notification_center.notifications = ->
  Notifications.find({}, sort: created_time: -1)

Template.notification.events = 
  'click .btn-close': (e) ->
    @viewedBy current_account()._id
    $(e.target).hide()

Template.activity_notification.rendered = ->
  Usertag.highlightMe @firstNode, current_contact().username