Template.passwordRecovery.helpers({
  resetPassword : (t) ->
    Session.get('resetPassword')
  resetEmail: ->
    Session.get('resetEmail')
})

Template.passwordRecovery.events({
  'submit #recovery-form' : (e, t) ->
    removeBootstrapGrowl()
    e.preventDefault()
    email = trimInput(t.find('#recovery-email').value)
    if (isCorrectEmail(email))
      Session.set('loading', true)
      Accounts.forgotPassword({email: email}, (err) ->
        if (err)
          $.bootstrapGrowl(err.toString(), {type: 'error'})
        else
          $("#recovery-form .forgot-password").addClass "email-sent"
      )
      Session.set('loading', false)
     else
       $.bootstrapGrowl('Please enter an email adress', {type: 'error'})
    return false

  'submit #new-password' : (e, t) ->
    removeBootstrapGrowl()
    e.preventDefault()
    pw = t.find('#new-password-password').value
    if (pw && isValidPassword(pw))
      Session.set('loading', true)
      Accounts.resetPassword(Session.get('resetPassword'), pw, (err) ->
        if (err)
          $.bootstrapGrowl('Password Reset Error & Sorry')
        else
          Session.set('resetPassword', '')
          Meteor.go Meteor.loginPath()
      )
      Session.set('loading', false)
    return false
})
