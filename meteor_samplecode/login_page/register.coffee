Template.register.events({
  'submit #register-form' : (e, t) ->
    e.preventDefault()
    $('#create-account').prop('disabled',true)

    console.log 'submit register '
    name = trimInput t.find('#account-username').value
    email = trimInput(t.find('#account-email').value).toLowerCase()
    password = t.find('#account-password').value
    username = name.toLowerCase()
    fullname = emailHandle(email)

    register_info =
      username: username
      fullname: fullname
      email: email
      password : password
      is_register: true

    $('.loading-animation').removeClass "hidden"
    unless validRegisterInfo(register_info,password)
      $('#create-account').prop('disabled',false)
      $('.loading-animation').removeClass "hidden"
      return false
    console.log 'username',username
    Meteor.call 'checkUsernameExist',username,(error,alreadyUsed) ->
      if !!error || alreadyUsed
        $('.loading-animation').addClass "hidden"
        $('#register .form-message').removeClass("hidden").text("Duplicated username.")
        $('#create-account').prop('disabled',false)
        return false
      if isValidPassword(password)
        Meteor.call 'createAccount', register_info, (err, result) ->
          if (err)
            $('.loading-animation').addClass "hidden"
            $('#register .form-message').removeClass "hidden"

            reason = err.reason
            if err.reason == "Email already exist."
              msgHtml = 'There is a user with this email address already. Click <a id="back-to-login" href="javascript:;">here</a> to login.'
              $('#register .form-message').html msgHtml
              $("#back-to-login").click (e) ->
                gotoLoginPage e, true
            else
              $('#register .form-message').text err.reason
          else
            $('.loading-animation').addClass "hidden"
            console.log "create new user"
            isEmail = isCorrectEmail result.email
            if not isEmail
              console.log "Invalid email address."
            else
              if result.email && result.email.length
                email = result.email
                #https://trello.com/c/B6btkuSy/1598-sign-up-bug-1
                # Only one email for a new user
                #Meteor.call 'welcome_message', email, email, result.username
                #Meteor.call 'activate_message', email, email, result.username'
                invited = false
                inviter = ""
                combine_welcome_and_active_account_email = true
                Meteor.call 'welcome_message', email, email, result.username, invited, inviter, combine_welcome_and_active_account_email
                Meteor.call('update_contact_gravatar_status', result.userId)

                $('#register').addClass("hidden")
                $('#login-box').show()
                $('#login-box .form-message').removeClass("hidden").text "Signup worked. We will activate your login soon."

            Meteor.loginWithPassword register_info.username, register_info.password, (error) ->
              Meteor.go Meteor.rootPath()
          $('#create-account').prop('disabled',false)
      else
        $('.loading-animation').addClass "hidden"
        $('#create-account').prop('disabled',false)
        $('#register .form-message').removeClass("hidden").text("Password is at least 6 characters.")

    return false

  'click #go-login': (e) ->
    gotoLoginPage e

  'keyup #account-username': (e) ->
    convertInputValueToLowerCase e.target

  'keyup #account-email': (e) ->
    convertInputValueToLowerCase e.target
})

@gotoLoginPage = (e, setEmailToUsername = false) ->
  e.preventDefault()
  $('#login-box').show()
  $('#register').addClass("hidden")
  $('#register .form-message').addClass "hidden"
  $('#register .form-message').text ""

  if setEmailToUsername
    regEmail = $("#register #account-email").val().trim()
    if regEmail != ""
      $("#login-form #login-username").val regEmail

@convertInputValueToLowerCase = (inputObj) ->
  value = inputObj.value
  if value != value.toLowerCase()
    inputObj.value = value.toLowerCase()
