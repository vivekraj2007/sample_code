@loadSocialMedia = (ref) ->
  contentDiv = $('#social-media-popup .nav-content div[ref="' + ref + '"]')
  li = $('#social-media-popup .nav-tab li[ref="' + ref + '"]')
  if(contentDiv.find('.section').html() == '')
    #Loading content here
    contentDiv.find('.section').html(ref + " content")
  li.addClass('selected').siblings().removeClass('selected')
  contentDiv.addClass('selected').siblings().removeClass('selected')

@is_create_topic = ->
  # at profile page should create new topic
  Session.get('new_topic_via_mailgun') || window.location.pathname == '/profile'

@contact_profile = ->
  if Meteor.userId() || isVisitor()
    profile_id = Session.get 'profile_id'
    if profile_id
      _contact = Contacts.findOne profile_id
    else if profile_email = Session.get('profile_email')
      _contact = Contacts.findOne emails: profile_email

    _contact ||= KFake.contact
    _contact

Template.profile_info.is_my_profile = ->
  viewingProfile = contact_profile()
  currentContact = current_contact()
  if viewingProfile && currentContact
    return viewingProfile._id == currentContact._id
  return false

Template.profile_info.editable = ->
  viewingProfile = contact_profile()
  currentContact = current_contact()
  if !viewingProfile || !currentContact || viewingProfile._id != currentContact._id
    return 'disabled'
  return ''

Template.profile_info.is_editable = ->
  viewingProfile = contact_profile()
  currentContact = current_contact()
  if !viewingProfile || !currentContact || viewingProfile._id != currentContact._id
    return false
  return true

Template.profile_info.is_my_contact = ->  
  account = UserAccounts.findOne({user_ids: Meteor.userId()})
  currentContact = current_contact()
  contact = Contacts.findOne({account_id : account._id, emails: currentContact.emails}) || Contacts.findOne({account_id : account._id, fullname: currentContact.fullname})
  if contact
    return true
  return false 

Template.profile_info.has_notes = ->
  !contact_profile().isFake && Topics.findOne({ profile_id: Session.get('profile_id') })

Template.profile_info.cards = ->
  _current_profile = contact_profile()
  return [] if _current_profile.isFake
  _topic = Topics.findOne profile_id: _current_profile._id
  profile_notes = Knotes.find({topic_id: _topic._id},{ sort: { timestamp: -1 } }).fetch()

Template.profile.current_profile = ->
  contact_profile()



Template.profile_info.contact_email = ->
  emails = contact_profile().emails
  if emails
    return emails.join()
  else
    return ''

Template.profile_info.contact_emails = ->
  contact_profile().emails || []

Template.profile_info.contact_gmail_user = ->
  contact = contact_profile()
  if contact?.type is 'me'
    user = Meteor.users.findOne({'services.google': {$exists: true}})
    # user?.services.google.email

Template.profile_info.contact_facebook = ->
  contact = contact_profile()
  if contact?.type is 'me'
    user = Meteor.users.findOne({'services.facebook': {$exists: true}})
    user?.services.facebook.email

Template.profile_info.contact_phone = ->
  contact_profile().phone || ''
Template.profile_info.contact_website = ->
  contact_profile().website
Template.profile_info.contact_facebook_link = ->
  contact = contact_profile()
  facebook_link = contact.facebook_link
  if !facebook_link && contact?.type is 'me'
    user = Meteor.users.findOne({'services.facebook': {$exists: true}})
    facebook_link = user?.services.facebook.link
  facebook_link

Template.profile_info.contact_twitter_link = ->
  contact_profile().twitter_link
Template.profile_info.contact_linkedin_link = ->
  contact_profile().linkedin_link

Template.profile.rendered = ->
  $("#big-container").addClass "profile-page"
  calcComponents()
  hideContextMenu()
  contact = contact_profile()
  document.title = contact?.nickname || contact?.fullname

Template.profile_info.rendered = ->
  contact_profile()?.refreshBelongs?()

Template.profile_info.realName = ->
  contact = contact_profile()
  contact.nickname || contact.fullname if contact

Template.profile_info.showUsername = ->
  contact = contact_profile()
  !contact.isFake && (contact.isBelongsToUser() || contact.type == 'me')

Template.profile_info.userName = ->
  contact = contact_profile()
  if contact
    return if contact.getUserName? then contact.getUserName() else contact.fullname

Template.profile_info.mini = ->
  _contact = contact_profile()
  _contact.avatar.mini if _contact.avatar && _contact.avatar.mini

Template.profile_info.avatar = ->
  _contact = contact_profile()
  _contact.avatar.path if _contact.avatar && _contact.avatar.path  

Template.profile_info.gphoto_base64 = ->
  contact_profile()?.gphoto_base64

#deprecated
Template.profile_info.contact_avatar = ->
  contact = contact_profile()
  Gravatar.imageUrl(contact.emails[0], {d: 404}) if contact

#deprecated
Template.profile_info.gravatar_exist = ->
  contact = contact_profile()
  contact.gravatar_exist if contact

Template.profile_info.initialName = ->
  contact = contact_profile()
  initialName(contact.fullname) if contact

Template.profile_info.bgcolor = ->
  bgcolor = 'bgcolor3'
  contact = contact_profile()
  if contact && contact.bgcolor
    bgcolor = contact.bgcolor
  return bgcolor

Template.profile_info.helpers
  my_username: ->
    _display_contact = contact_profile()
    _display_contact && _display_contact.type == 'me' && _display_contact.username

Template.profile_info.events({
  'click .add-email': (event) ->
    if $(event.currentTarget).closest('.control-group').find('.edit-item').length > 0
      return

    $newEmail = $("<div class='edit-item'><div class='edit-area1'><textarea class='new-email'></textarea>&nbsp;<input type='button' value='Save' class='my-btn small-btn save-new-email'> &nbsp;<input type='button' value='Cancel' class='my-btn small-btn cancel-new-email'></div><br /></div>")
    $newEmail.find('.save-new-email').click((e) ->
      email = $(this).parent().find('.new-email').val()

      if (!isCorrectEmail(email))
        $.bootstrapGrowl('Invalid email address!', {type: 'error'})
        return

      currentContact = current_contact()
      emailContacts = Contacts.find({account_id: currentContact.account_id, emails: email, type: 'other'}, {fields: {_id: true}}).fetch()
      console.log 'Add email to contact of contact_id:' + currentContact._id
      Contacts.update({_id: currentContact._id}, {$addToSet : {emails : email}}, (err, count) ->
        if err
          console.log err
        else
          _.each emailContacts, (c) ->
            Contacts.remove({_id: c._id})
        )
      $(this).closest('.edit-item').remove()
    )

    $newEmail.find('.cancel-new-email').click((e) ->
      $(this).closest('.edit-item').remove()
    )
    $newEmail.insertAfter(event.currentTarget)

  'click .add-google-oauth': (event) ->
    addGoogleOauth()

  'click .remove-google-oauth': (event) ->
    oauth_user_id = $(event.target).data('userid')
    if !!oauth_user_id
      Meteor.call 'remove_google_oauth', oauth_user_id, (err, result) ->
        if err
          console.log err
        console.log "remove goole oauth"



  'click .add-facebook-oauth': (event) ->
    addFBOauth()

  'click .remove-facebook-oauth': (event) ->
    Meteor.call 'remove_facebook_oauth', Meteor.userId(), (err, result) ->
      if err
        console.log err
#    setTimeout ->
#      UserHelper.doLogout()
#    ,1000

  'click .delete-account': (event) ->
    $(".delete_account_popup").lightbox_me
      centered: true

  'click .remove-email': (event) ->
    emailNeedRemove = $(event.currentTarget).attr('data-email')
    return true unless emailNeedRemove
    removeBootstrapGrowl()
    contact = contact_profile()
    if contact.emails && contact.emails.length > 1
      console.log 'removed-email:' + emailNeedRemove
      Meteor.call 'remove_contact_email', contact._id, emailNeedRemove
      Knotable.removeParticipator(emailNeedRemove)
    else
      $.bootstrapGrowl('You must have at least an email', {type: 'error'})


  'click .change-password': (event) ->
    removeBootstrapGrowl()
    $("#old-password").focus()
    $('.change-password-form')[0].reset()
    $(".change_password_popup").lightbox_me
      centered: true
  
  'click .add-contact': (event) ->
    account = UserAccounts.findOne({user_ids: Meteor.userId()})
    currentContact = current_contact()
    Meteor.call 'add_contact', account._id, currentContact.fullname, currentContact.emails, (error, result) ->
      KnotableStatus.addNewContact result
      Session.set('NEW_CONTACT_ID', result)
      Session.set('NEW_CONTACT_EMAIL', email)


  'keydown, blur textarea.editable-profile': (event) ->
    return if event.type == "keydown" && (event.which != 13 && event.keyCode != 13)
    event.preventDefault()
    $editor = $(event.currentTarget)
    return if $editor.attr('changing') == '1'
    orig_value = $editor.attr('data-orig')
    new_value = $editor.val()
    attr_name = $editor.attr('name')
    if $editor.val() == orig_value && event.type == "keydown"
      switch attr_name
        when 'contact-name'
          $('#contact-phone').focus()
        when 'contact-phone'
          $('#contact-website').focus()
        when 'contact-website'
          $('#contact-twitter-link').focus()
        when 'contact-twitter-link'
          $('#contact-facebook-link').focus()
        when 'contact-facebook-link'
          $('#contact-linkedin-link').focus()
        when 'contact-linkedin-link'
          $('#contact-name').focus()
      return false
    else if new_value == orig_value
      return false
    if attr_name == 'contact-name'
      reg1 = new RegExp('"',"g")
      reg2 = new RegExp("'","g")
      new_value = new_value.replace(reg1, "")
      new_value = new_value.replace(reg2, "")
    $editor.attr('changing','1')
    current_contact = contact_profile()
    if current_contact.type == 'me'&&attr_name == 'contact-name'
      Meteor.call 'update_contacts_name_byEmails', current_contact.emails ,new_value
      current_contact.updateProfile attr_name,new_value
    else
      current_contact.updateProfile attr_name,new_value
    showTopRightNotificationPopup 'update-profile-popup', 'Profile updated', 5000
    #update browser title
    document.title = current_contact.nickname || current_contact.fullname


    if event.type == "keydown"
      switch attr_name
        when 'contact-name'
          $('#contact-phone').focus()
        when 'contact-phone'
          $('#contact-website').focus()
        when 'contact-website'
          $('#contact-twitter-link').focus()
        when 'contact-twitter-link'
          $('#contact-facebook-link').focus()
        when 'contact-facebook-link'
          $('#contact-linkedin-link').focus()
        when 'contact-linkedin-link'
          $('#contact-name').focus()
    $editor.attr('changing','0')
    $editor.prop('disabled',false)

  'click .talk': (e) ->
    return redirectToLoginPage() if !Meteor.userId()
    return false if contact_profile().isFake

    $(e.currentTarget).prop('disabled',true)
    if $("#compose-popup").is(':visible')
      hideCompose()
    else
      popupCompose()
    $(e.currentTarget).prop('disabled',false)

  'click img.profile_avatar': (e) ->
    if !Template.profile_info.is_editable()
      return

    $( ".upload-avatar").unbind( "change" );
    photoPopup = $('#avatar_popup', $(e.currentTarget).closest '.user-info')
    photoPopupHtml = photoPopup.html()

    openLightboxAlert photoPopupHtml, () ->

      $('.change-avatar').click (e) ->
        $('.upload-avatar').click()
      $('.delete-avatar').click (e) ->
        _contact = contact_profile()
        Meteor.call 'delete_contact_avatar', _contact._id
        closeLightboxAlert()
        $('#avatar_large').attr("src","")
        $('.cancel-avatar, .save-avatar').hide()
      $('.cancel-avatar').click (e) ->
        closeLightboxAlert()
        $('#avatar_large').attr("src", contact_profile().avatar.path || "" )
        $('.cancel-avatar, .save-avatar').hide()

      $('.upload-avatar').change (e) ->
        MediaHelper.showPreview 'upload_avatar','avatar_large', ->
          # Lightbox kills all event listeners. Hack to workaround
          $('img.profile_avatar').click()
          $('.cancel-avatar, .save-avatar').show()
          #card#1533
          $('div.photo_shadow_box').css({'background-color':'white'})

      $('.save-avatar').click (e) ->
        # if(Contacts.update({_id: currentContact._id}, {$addToSet : {emails : email}}))
        console.log("saving")
        MediaHelper.uploadFiles 'upload_avatar', (data, name) ->
          console.log " file name after upload" + name
          console.log " file name after upload" + data
          _contact = contact_profile()

          MediaHelper.createThumbnail 'upload_avatar', 192, 192, (thumb_data, thumb_name) ->
            console.log data
            console.log name
            Meteor.call 'uploadFile', thumb_name, thumb_data, (e, file_id) ->
            #thumb_url = 'file/' + file_id
            #thumb_url = Meteor.absoluteUrl(thumb_url)
            #console.log(thumb_url)

              MediaHelper.createThumbnail 'upload_avatar', 640, 640, (big_thumb_data, big_thumb_name)  ->
                #url = 'file/' + file_id
                #url = Meteor.absoluteUrl(url)
                #console.log(url)

                console.log "updating contact avatar: profilepage"
                Meteor.call 'update_contact_avatar', _contact._id, big_thumb_data, thumb_data
                $('.cancel-avatar, .save-avatar').hide()
                closeLightboxAlert()
    


        # $('.cancel-avatar, .save-avatar').hide()
  'load img.profile_avatar': (e) ->
      MediaHelper.updateThumbPosition $(e.target)

  'click span.member-initials': (e) ->
    if !Template.profile_info.is_editable()
      return
    
    $( ".upload-avatar").unbind( "change" );
    photoPopup = $(e.currentTarget).next('#avatar_popup')
    photoPopupHtml = photoPopup.html()

    openLightboxAlert photoPopupHtml, () ->

      $('.change-avatar').click (e) ->
        $('.upload-avatar').click()

      $('.cancel-avatar').click (e) ->
        closeLightboxAlert()
        $('#avatar_large').attr("src", contact_profile().avatar.path || "" )
        $('.cancel-avatar, .save-avatar').hide()

      $('.upload-avatar').change (e) ->
        MediaHelper.showPreview 'upload_avatar','avatar_large', ->
          # Lightbox kills all event listeners. Hack to workaround
          $('span#profile_member_initials').click()
          $('.cancel-avatar, .save-avatar').show()

      $('.save-avatar').click (e) ->
        # if(Contacts.update({_id: currentContact._id}, {$addToSet : {emails : email}}))
        console.log("saving")
        MediaHelper.uploadFiles 'upload_avatar', (data, name) ->
          console.log " file name after upload" + name
          console.log " file name after upload" + data
          _contact = contact_profile()

          MediaHelper.createThumbnail 'upload_avatar', 192, 192, (thumb_data, thumb_name) ->
            console.log data
            console.log name
            Meteor.call 'uploadFile', thumb_name, thumb_data, (e, file_id) ->
            #thumb_url = 'file/' + file_id
            #thumb_url = Meteor.absoluteUrl(thumb_url)
            #console.log(thumb_url)

              MediaHelper.createThumbnail 'upload_avatar', 640, 640, (big_thumb_data, big_thumb_name)  ->
                #url = 'file/' + file_id
                #url = Meteor.absoluteUrl(url)
                #console.log(url)

                console.log "updating contact avatar: profilepage"
                Meteor.call 'update_contact_avatar', _contact._id, big_thumb_data, thumb_data
                $('.cancel-avatar, .save-avatar').hide()
                closeLightboxAlert()
  'click .show-social-media': (e) ->
    ref= $(e.target).attr('ref')
    loadSocialMedia ref
    $('#social-media-popup').lightbox_me
      centered: true
})

Template.social_media_popup.events
  'click .btn-close': (e) ->
    $(e.target).trigger "close"

  'click #social-media-popup .nav-tab a': (e) ->
    ref = $(e.target).parent().attr('ref')
    loadSocialMedia ref

Template.change_password_popup.rendered = ->
  initpwdFilter = Session.get('initpwdFilter')
  if initpwdFilter
    Session.set('initpwdFilter', false)
    $("#old-password").focus()
    $('.change-password-form')[0].reset()
    $(".change_password_popup").lightbox_me
      centered: true

Template.change_password_popup.events
  'click .btn-close': (e) ->
    removeBootstrapGrowl()
    $(e.target).trigger "close"
    $('.change_password_popup').trigger 'close'

  'click .change_password_btn': (e) ->
    removeBootstrapGrowl()
    oldPassword = $('#old-password').val()
    newPassword = $('#new-password').val()
    Accounts.changePassword(oldPassword, newPassword, (error)->
      if error
        $.bootstrapGrowl('Old password is incorrect.', {type:'error',ele:$("#change_password_popup"),offset:{from:'bottom'},allow_dismiss: false,delay:0})
        console.log error
      else
        $('.change_password_popup').trigger 'close'
    )


Template.delete_account_popup.events
  'click .btn-close': (e) ->
    removeBootstrapGrowl()
    $(e.target).trigger "close"
    $('.delete_accoutn_popup').trigger 'close'

  'click .btn-delete': (e) ->
      Meteor.call 'delete_user_account', Meteor.userId(), (err, result) ->
       if err
         console.log err
      UserHelper.doLogout()
      removeBootstrapGrowl()
      $(e.target).trigger "close"
      $('.delete_accoutn_popup').trigger 'close'

  'click .btn-cancel': (e) ->
    removeBootstrapGrowl()
    $(e.target).trigger "close"
    $('.delete_accoutn_popup').trigger 'close'

Template.import_gmail_popup.events
  'click .ok_btn': (e) ->
    Meteor.call 'load_mails', Meteor.userId(), true # load contacts
    Meteor.call 'load_mails', Meteor.userId() # load mails
    setTimeout ->
      window.location = Meteor.rootPath() + "profile/" + Session.get('profile_id')
    ,1000
  'click .cancel_btn': (e) ->
    setTimeout ->
      window.location = Meteor.rootPath() + "profile/" + Session.get('profile_id')
    ,1000


#---------------------------#

Template.group.rendered = ->
  calcComponents()

Template.group.events
  'click .group_profile .btn-delete': (e) ->
    pid=$(e.currentTarget).parent('.group_profile').attr("data-id")
    user = UserAccounts.findOne({user_ids: Meteor.userId()})
    deleting_contact=Contacts.findOne({ _id:pid , account_id : user._id })
    deleting_contact.removeGroup(Session.get('selected_group')) if deleting_contact

  'click .icon.new_group_profile':(e) ->
      if Session.get('selected_group')
        marginSize = 150
        windowHeight = $(window).height()
        maxHeight = windowHeight - marginSize
        $("#add-user-to-group-popup div.contacts").css('max-height', maxHeight + 'px')
        $("#add-user-to-group-popup").lightbox_me
          centered: true

  'click p':(e)->
      pid=$(e.currentTarget).parents('.group_profile').attr("data-id")
      Session.set 'profile_id',pid
      Meteor.go Meteor.profilePath({ contact_id: pid })

  'click img.profile_avatar':(e)->
      pid=$(e.currentTarget).parents('.group_profile').attr("data-id")
      Session.set 'profile_id',pid
      Meteor.go Meteor.profilePath({ contact_id: pid })




Template.group.gname = ->
  g_name= ContactGroups.findOne(Session.get('selected_group'),{ name: 1, _id:0 })
  if g_name
    return g_name.name

Template.group.contacts = ->
  groupId = Session.get('selected_group')
  unless groupId
    return false

  my_users = Meteor.users.find().fetch()
  my_emails = _.map my_users, (user) ->
    user.services?.google?.email || user.emails?[0].address
  user = UserAccounts.findOne({user_ids: Meteor.userId()})
  if user
    members = Contacts.find({
      group_ids: groupId
    }).fetch()
    members = _.filter members, (c) ->
      isCurrentUser = false
      _.each my_emails, (email) ->
        if email in c.emails
          isCurrentUser = true
      !isCurrentUser
    #Card 682: keep order of contact in session
    allContactsSorted = sortContactsList(members)
    filterContacts = filterArchivedContact(allContactsSorted)
  else
    guestEmail = Session.get('signup_email')
    Contacts.find({emails: {$nin: [guestEmail]}}) # Guest use

Template.group.avatar = ->
  this.avatar.path if this.avatar && this.avatar.path

Template.group.mini = ->
  this.avatar.mini if this.avatar && this.avatar.mini

Template.group.gphoto_base64 = ->
  this?.gphoto_base64

#deprecated
Template.group.contact_avatar = ->
  Gravatar.imageUrl(this.emails[0], {d: 404}) if this

#deprecated
Template.group.gravatar_exist = ->
  this.gravatar_exist if this

Template.group.initialName = ->
  initialName(this.fullname) if this



Template.group.realName = ->
  this.nickname || this.fullname if this

Template.group.contact_emails = ->
  this.emails || []

Template.group.contact_phone = ->
  this.phone || ''

Template.group.contact_website = ->
  this.website

Template.group.contact_facebook_link = ->
  facebook_link = this.facebook_link
  if !facebook_link && this?.type is 'me'
    user = Meteor.users.findOne({'services.facebook': {$exists: true}})
    facebook_link = user?.services.facebook.link
  facebook_link

Template.group.contact_twitter_link = ->
  this.twitter_link

Template.group.contact_linkedin_link = ->
  this.linkedin_link
Template.group.profile_id = ->
  this._id

#---------------------------#


