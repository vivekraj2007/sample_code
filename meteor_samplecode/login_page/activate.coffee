Template.activate.rendered = ->
  
Template.activate.is_actived = ->
  return Session.equals('IS_ACTIVED', true) || Session.equals('IS_ACTIVED', false)

Template.activate.is_actived_success = ->
  return Session.equals('IS_ACTIVED', true) || false

Template.activate.events
  'click .redirect-link': (e) ->
    UserHelper.doLogout()
