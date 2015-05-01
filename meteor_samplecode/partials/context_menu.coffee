window.safari_trigger = false
@context_menu = (e,item,menu)->
  e.preventDefault()
  e.stopPropagation()
  hideContextMenu()
  item.addClass('right-clicked').siblings('li').removeClass('right-clicked')

  $context_menu_source = $(".context-menu-source-container.#{menu}")
  if $context_menu_source.length
    showHideUnarchivedLink item, $context_menu_source, menu
    $context_menu_source.show().position
      my: "right top"
      at: "right-1 top+3"
      of: item

    # profile page
    # if item.hasClass('contact')
    #   localStorage.profile_email = item.data('email')
    #   Session.set 'profile_id' = item.data('id')
@showHideUnarchivedLink= ($item, $context_menu_source, menu) ->

  user_id = Meteor.userId()
  archived = $item.attr('archived')
  merged_top_id = $item.attr('merged-topic-id')

  if menu == 'people'
    if archived && (archived == 'true' || archived == true)
      $context_menu_source.find('li[data-menu="unarchive"]').show()
      $context_menu_source.find('li[data-menu="ban"]').hide()
    else
      $context_menu_source.find('li[data-menu="unarchive"]').hide()
      $context_menu_source.find('li[data-menu="ban"]').show()
  if menu == 'topic'
    if archived && archived == 'true'
      $context_menu_source.find('li[data-menu="unarchive"]').show()
      $context_menu_source.find('li[data-menu="delete"]').hide()
    else
      $context_menu_source.find('li[data-menu="unarchive"]').hide()
      $context_menu_source.find('li[data-menu="delete"]').show()
    if merged_top_id
      $context_menu_source.find('li[data-menu="undomerge"]').show()
    else
      $context_menu_source.find('li[data-menu="undomerge"]').hide()

@contactMenuAction = (event,trigger,command) ->
  $menu_trigger = $('#people-sortable').find('.right-clicked')
  $(event.currentTarget).fadeOut('fast')
  switch command
    when 'ban'
      if !Meteor.userId()
        redirectToLoginPage()
        return false
      dataid = $menu_trigger.attr('data-id')
      data_email = $menu_trigger.attr('data-email')

      $("#people-box").find("li[data-id='" + dataid + "']").hide()
      $menu_trigger.hide()

      $('#ban-popup >div>span').html($menu_trigger.attr("title"))
      $('#ban-popup').find('button#prompt-ban-undo').attr("data-email", data_email)

      banned = Contacts.findOne({ emails: data_email })
      key = 'Banned-' + data_email
      Session.set key, banned

      key = "ORDER_CONTACT_ID_" + dataid

      Session.set 'BanCache', [key,Session.get(key)]
      Session.set key, null

      Meteor.call 'ban_contact', dataid, (e,r) ->
        if e
          console.error 'e',e
        Deps.afterFlush(->
          showTopRightPopup $('#ban-popup'), 5000
        )

      Meteor.go Meteor.rootPath()
    when 'profile'
      set_profile $menu_trigger
      $menu_trigger.trigger('click')

      Meteor.go Meteor.profilePath({ contact_id: Session.get('profile_id') })

    when 'unarchive'
      if !Meteor.userId()
        redirectToLoginPage()
        return false
      dataid = $menu_trigger.attr('data-id')
      Meteor.call 'unarchive_contact', dataid, (e,r) ->
        if e
          console.error 'e',e
    else
      console.log "can't hold us"
@shareMenuAction = (event,trigger,command) ->
  $menu_trigger = $('#right-menu-people').find('.clicked')
  $(event.currentTarget).fadeOut('fast')
  switch command
    when 'profile'
      set_profile($menu_trigger)
      $menu_trigger.trigger('click')
      if (subject = current_subject()) && !subject.isFake
        Meteor.go Meteor.profileFromThreadPath({ contact_id: Session.get('profile_id'),from_thread: subject._id })
      else
        Meteor.go Meteor.profilePath({ contact_id: Session.get('profile_id') })
    when 'remove'
      if !Meteor.userId()
        redirectToLoginPage()
        return false
      if !$menu_trigger.hasClass('me_contact')
        userEmail = $menu_trigger.data('email')
        window.removeThreadUser = userEmail
        topicId = Session.get('subject_id')
        current_subject()?.removeContact userEmail
        Deps.flush()
        showRemoveThreadUserPopup(topicId, userEmail)
    else
      console.log "can't hold us"

topicdelete = []
@topicMenuAction = (event,trigger,command) ->
  $menu_trigger = $('#topics-sortable').find('li.right-clicked')
  $(event.currentTarget).fadeOut('fast')
  switch command
    when 'delete'
      if !Meteor.userId()
        redirectToLoginPage()
        return false
      dataid = $menu_trigger.attr('data-id')
      TopicsHelper.deleteTopic dataid
      return

      ###
      if confirm('Are you sure to delete this topic ?')

      ###
    when 'unarchive'
      if !Meteor.userId()
        redirectToLoginPage()
        return false
      hideRightMenu()
      dataid = $menu_trigger.attr('data-id')
      TopicsHelper.unarchiveTopic dataid

    # undo merge action
    when 'undomerge'
      if !Meteor.userId()
        redirectToLoginPage()
        return false
      TopicsHelper.undoMergedTopic $menu_trigger.attr('data-id')
      return

    else
      console.log "can't hold us"

@groupMenuAction=(event,trigger,command) ->
  $menu_trigger = $('#people-sortable').find('li.right-clicked')
  $(event.currentTarget).fadeOut('fast')

  switch command
    when 'delete'
      if !Meteor.userId()
        redirectToLoginPage()
        return false
      dataid = $menu_trigger.attr('data-id')
      GroupHelper.deleteGroup dataid
      return
    when 'profile'
      $menu_trigger.siblings().removeClass('selected')
      $menu_trigger.addClass('selected')

      if !Session.set('selected_group')
        Session.set('selected_group', $menu_trigger.data('id'))
      Meteor.go Meteor.groupPath({ group_id: $menu_trigger.data('id') })
      ContactsHelper.toggleSubGroup()


@hideContextMenu = ->
  $('.context-menu-source-container').hide()
  $(".right-clicked").removeClass("right-clicked")

@toggle_dropdown = (e, context) ->
  ele  = $(e.currentTarget)
  e.preventDefault()
  e.stopPropagation()

  dropdown = $('.context-menu-source-container.' + ele.attr('dropdown'), context)

  if(ele.hasClass("active"))
    ele.removeClass("active")
    dropdown.hide()
  else
    ele.addClass("active").siblings(".toggle-dropdown").removeClass('active')
    dropdown.removeClass "show-settings"
    dropdown.siblings(".user-menu-dropdown").hide()
    dropdown.show().position({
      my: 'right+14 top+17',
      at: 'right bottom',
      of: ele
    })
  false

@hidden_gear_menu = (e) ->
  $(".user-menu .gear").removeClass("active")
  context_menu_source = $('.context-menu-source-container.gear-menu')
  $(context_menu_source).hide()

@addGoogleOauth = () ->
  $("#addOauthPopup").hide()
  $("#addOauthPopupProgress").show()
  Session.set('user_id', Meteor.userId()) # link google account with register account
  profileId = Session.get('profile_id')
  Meteor.loginWithGoogle({
    requestPermissions: ["https://mail.google.com/", # imap
                         "https://www.googleapis.com/auth/userinfo.profile", # profile
                         "https://www.googleapis.com/auth/userinfo.email", # email
                         "https://www.google.com/m8/feeds/" # contacts
                       ]
    requestOfflineToken: true # Currently(Meteor 0.6.5) only supported with Google.
    forceApprovalPrompt: true # Currently(Meteor 0.6.5) only supported with Google.
  }, (err) ->
    Knotable.initParticipators()
    $("#addOauthPopup").show()
    $("#addOauthPopupProgress").hide()
    if err
      removeBootstrapGrowl()
      if(typeof(err.reason)!="undefined")
        $.bootstrapGrowl(err.reason)
    else
      updateAccounts()
      $(".import_gmail_popup").lightbox_me
        centered: true
      # Meteor.call 'load_mails', Meteor.userId(), true # load contacts
      # Meteor.call 'load_mails', Meteor.userId() # load mails
      #setTimeout ->
        #window.location = Meteor.rootPath() + "profile/" + profileId
      #,1000

  )

@addFBOauth = () ->
  Session.set('user_id', Meteor.userId()) # link facebook account with register account
  profileId = Session.get('profile_id')
  Meteor.loginWithFacebook({
    requestPermissions: ['email']
    requestOfflineToken: true
    forceApprovalPrompt: true
  }, (err) ->
    Knotable.initParticipators()
    if err
      removeBootstrapGrowl()
      if(typeof(err.reason)!="undefined")
        $.bootstrapGrowl(err.reason)
    else
      updateAccounts()
      setTimeout ->
        window.location = Meteor.rootPath() + "profile/" + profileId
      ,1000
  )


$(document).click (event) ->
  $('.privacy-check-list').hide()
  hidden_gear_menu(event)

Template.people_context_menu.events
  'click .context-menu-source-container': (e) ->
    e.stopPropagation()
    e.preventDefault()
    $commander = $(e.target)
    contactMenuAction e,$commander,$commander.attr('data-menu')

  'mouseleave .context-menu-source-container': (e) ->
    hideContextMenu()

Template.share_context_menu.events
  'click .context-menu-source-container': (e) ->
    e.stopPropagation()
    e.preventDefault()
    $commander = $(e.target)
    shareMenuAction e,$commander,$commander.attr('data-menu')

  'mouseleave .context-menu-source-container': (e) ->
    $('.clicked').removeClass('clicked')
    hideContextMenu()

Template.topic_context_menu.events
  'click .context-menu-source-container': (e) ->
    e.stopPropagation()
    e.preventDefault()
    $commander = $(e.target)
    topicMenuAction e,$commander,$commander.attr('data-menu')

  'mouseleave .context-menu-source-container': (e) ->
    hideContextMenu()

Template.group_context_menu.events

  'mouseleave .context-menu-source-container': (e) ->
    hideContextMenu()

  'click .context-menu-source-container': (e) ->
    e.stopPropagation()
    e.preventDefault()
    $commander = $(e.target)
    groupMenuAction e,$commander,$commander.attr('data-menu')




Template.gear_menu_context_menu.avatar = ->
  current_contact().avatar.mini if current_contact().avatar && current_contact().avatar.mini

Template.gear_menu_context_menu.gphoto_base64 = ->
  current_contact()?.gphoto_base64

#deprecated
Template.gear_menu_context_menu.gravatar_exist = ->
  current_contact()?.gravatar_exist

#deprecated
Template.gear_menu_context_menu.gavatar_path = ->
  Gravatar.imageUrl(current_contact()?.emails[0], {s: 34})

Template.gear_menu_context_menu.initialName = ->
  name = if Meteor.user()? then current_contact().fullname else null
  initialName name

Template.gear_menu_context_menu.fullname = ->
  if Meteor.user()
    return current_contact().fullname
  else
    # change for card #1042
    'Guest'
    # name = Session.get('signup_username')
    # if name
    #   name = name.charAt(0).toUpperCase() + name.slice(1)
    #   return name
    # else return ''

Template.gear_menu_context_menu.bgcolor = ->
  UserHelper.getCurrentUserBgColor()

Template.gear_menu_context_menu.user_is_muted = ->
  isMuted()

Template.gear_menu_context_menu.rendered = ->
  $(".user-menu .user-name, .user-menu .avatar, .user-menu .no-avatar-m").on 'click', (e) ->
    if !isVisitor()
      set_current_profile()
    else
      set_visitor_profile()
    Session.set('standalone_knotes')
    Meteor.go '/'
    # Meteor.go Meteor.profilePath({ contact_id: Session.get('profile_id') })

  $(".user-menu .user-name, .user-menu .avatar, .user-menu .no-avatar-m").on 'touchstart', (e) ->
    set_current_profile()
    Meteor.go Meteor.profilePath({ contact_id: Session.get('profile_id') })

  $(".user-menu .user-name, .user-menu .avatar, .user-menu .no-avatar-m").on 'hover', (e) ->
    $(this).css('cursor', 'pointer');

Template.gear_menu_context_menu.events({

 # 'click .gear-menu .manage-profile': (e) ->
  #  if !isVisitor()
   #   set_current_profile()
    #else
     # set_visitor_profile()
      #Meteor.go Meteor.profilePath({ contact_id: Session.get('profile_id') })

  'click .gear-menu .manage-avatar': (e) ->
    set_current_profile()
    Meteor.go Meteor.profileAvatarPath({ contact_id: Session.get('profile_id') })

  'click .gear-menu .logout': (e) ->
    e.preventDefault()
    e.stopPropagation()
    UserHelper.doLogout()

  'click .gear-menu .edit-profile': (e) ->
    set_current_profile()
    hideContextMenu()
    Meteor.go Meteor.profilePath({ contact_id: Session.get('profile_id') })

  'click .gear-menu .themes li': (e) ->
    ref = $(e.currentTarget).attr "ref"
    Session.set 'theme', ref
    return if($("body").hasClass(ref))
    $("body").removeClass (index, css) ->
     (css.match(/theme[-a-z]+/g) or []).join " "
    $("body").addClass ref

  'click .gear-menu .import-contact': (e) ->
    ref = 'gmail'
    li = $(e.target).closest('.mail-client')
    if(li.length > 0)
      ref = li.attr("ref")
    Meteor.go Meteor.importContactPath({ mail: ref })

  'click .user-menu .muted': (e) ->
    $(".thread-button .button-thumb").css({"left":"0px"})
    $(".thread-button .button-thumb").text("0")
    setTimeout ->
      muted()
    , 1000


  'click .user-menu .resume': (e) ->
    $(".thread-button .button-thumb").css({"left":"12px"})
    $(".thread-button .button-thumb").text("1")
    setTimeout ->
      resume()
    ,1000

  'click .toggle-dropdown': (e) ->
    context = $(e.target).closest('.user-menu').parent()
    toggle_dropdown(e, context)


  'click .user-menu .share-icon': (e) ->
      # switchToRightMenu()
      toggleRightMenu()

  'click .user-menu .search-icon': (e) ->
    $(".user-menu-dropdown").hide()
    $(".user-menu .toggle-dropdown").removeClass('active')
    $(".user-menu").addClass("on-search")
    $(".user-menu .search-input input").val("").focus()

  'blur .user-menu .search-input input': (e) ->
    $(".user-menu").removeClass("on-search")
    $('.search-result').hide()

  'keyup .user-menu .search-input input': (e) ->
    e.preventDefault();
    e.stopPropagation();

    input_control = $(e.target)
    if e.keyCode is 27
      input_control.blur()
    else
      if($.trim(input_control.val()) == "")
        $('.search-result').hide()
      else
        $('.search-result').show().position({
          my: 'right top+17',
          at: 'right bottom',
          of: input_control
        })

  'mouseleave .context-menu-source-container': (e) ->
    $('.gear-menu').hide()
    $(".user-menu .gear").removeClass("active")

  'mouseleave .context-menu-source': (e) ->
    setTimeout (->
      hideContextMenu();
    ), 1000

  'load img.avatar': (e) ->
    MediaHelper.updateThumbPosition $(e.target)
})
