Template.login.rendered = ->
  Meteor.call 'usernameAndEmail', (error, result) ->
    if error
      console.log error
    else
      data = _.uniq result
      data = _.map result, (c) -> { value: c, name: c}
      $('input#login-username').typeahead('destroy').typeahead
        name: 'name_or_email',
        local: data,
        limit: 10

Template.login.events
  'submit #login-form': (e, t) ->
    console.log "login-form submit triggerd!=============================================="
    e.preventDefault()
    _login = trimInput(t.find('#login-username').value).toLowerCase()
    password = t.find('#login-password').value

    $('.loading-animation').removeClass "hidden"
    return false unless validLoginInfo(_login,password)

    Meteor.loginWithPassword(_login, password, (err) ->
      Knotable.initParticipators()
      if (err)
        if err.error == 403
          if err.reason == "User not found"
            $('#login-box').hide()
            $('#register').removeClass("hidden")
            #$('#register .message').removeClass "hidden"
            #$('#register .message').text "Signup / Create a user"
            if isCorrectEmail(_login)
             $('#register #account-email').val _login
             $('#register #account-username').val('').focus()
            else
             $('#register #account-username').val _login
             $('#register #account-email').val('').focus()
            $('#register #account-password').val password
          else
            $('#login-box .form-message').removeClass "hidden"
            $('#login-box .form-message').text "The password you entered is incorrect."
      else
        unless UserHelper.isActived()
          $('#login-box .form-message').removeClass "hidden"
          $('#login-box .form-message').text "That's the right password. But this account wasn't yet activated by the Knotable crew. Ping someone!"
        # console.log 'login success!   ' + new Date()
        else
          Meteor.go Meteor.rootPath()
      $('.loading-animation').addClass "hidden"

    )
    return false

  'click #register-button': (e) ->
    #console.log "register-button clicked!"
    $('#login-box .form-message').addClass "hidden"
    e.preventDefault()
    $('#login-box').hide()
    $('#register').removeClass("hidden")
  'keypress input#login-username': (e) ->
     $('#login-box .form-message').addClass "hidden"
     if e.which == 13
       e.stopPropagation()
       $("input#login-password").focus()
       false

  'keyup #login-username': (e) ->
     e.target.value = e.target.value.toLowerCase().trim()
