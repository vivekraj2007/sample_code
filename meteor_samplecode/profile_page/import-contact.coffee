Template.importContact.rendered = ->
  calcComponents()
  Session.set 'invite_friends',false

Template.importContact.gmailAccount = ->
  if Meteor.user()
    user = Meteor.users.findOne({'services.google': {$exists: true}})

Template.importContact.events
  'click .mail-clients li': (e) ->
    ele = $(e.currentTarget)
    ele.addClass("active").siblings().removeClass("active")
    ref = ele.attr "ref"
    $("#import-area").attr "class", ref

  'click #import-area .loadcontacts-button': (e) ->
    import_email = $('#import-email').text()
    google_user_id = google_user_id = current_account()?.googleOauthUser(import_email)?._id
    if google_user_id
      $('#import-area .loadcontacts-button').val('Loading...').prop 'disabled',true
      Meteor.call 'loadGoogleContacts',google_user_id,->
        $('#import-area .loadcontacts-button').val('Done')

  'click #import-area .continue-button': (e) ->
    stage = $('ul.mail-clients').find('li.active').attr('ref')
    switch stage
      when 'gmail'
        Session.set 'invite_friends',true
        addGoogleOauth()

Template.foundContacts.contacts = ->
  current_account()?.getGoogleContacts()

Template.foundContacts.events
  'click .invite-button': (e) ->
    $trigger = $(e.target).val('Processing...').prop('disabled',true)
    console.log '$trigger',$trigger
    selected_emails = []
    import_email = $('#import-email').text()
    google_user_id = current_account()?.googleOauthUser(import_email)?._id
    unless google_user_id
      $trigger.val('Invite friends').prop('disabled',false)
      return false
    $('#need-import-contacts').find('input:checked').map ->
      selected_emails.push $(@).val()

    if selected_emails.length > 0
      Meteor.call 'inviteGoogleContacts',google_user_id,selected_emails,->
        $trigger.val('Sent!')
        $.bootstrapGrowl "Cheer Up! Invite email(s) sent."
    else
      $trigger.val('Invite friends').prop('disabled',false)
      $.bootstrapGrowl "Please choose some contacts"
      return false


  'click #select-all': (e) ->
    $(e.target).closest(".scrollable-div").find('.content input[type="checkbox"]').prop( "checked", $(e.target).is(":checked"));