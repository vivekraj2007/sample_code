Template.activities.helpers
  latest_activities: ->
    Activities.find({}, {sort: {timestamp: -1}})
  contact: ->
    Contacts.findOne({account_id: @account_id, type: 'me'})

Template.activities.rendered = ->
  $(@find('#activity-settings-in-app')).prop('checked', current_account()?.showNotification?())
  $(@find('#activity-settings-emails')).prop('checked', !isMuted())

Template.activities.events
  'click .activity-settings': (e) ->
    $(".notification-area").toggleClass "show-settings"

  'click a.undo': (e)->
    topic_id = $(e.currentTarget).closest('li.activity').data('topicid')
    if $(e.currentTarget).hasClass('delete-space')
      TopicsHelper.unarchiveTopic(topic_id)
    else if $(e.currentTarget).hasClass('merge-space')
      console.log 'undo merge'
      TopicsHelper.undoMergedTopic(topic_id)
    else
      console.log 'something wrong with undo'

  'click #activity-settings-in-app': (e)->
    checked = $(e.currentTarget).is(':checked')
    if checked
      current_account().enableNotification()
    else
      current_account().disableNotification()

  'click #activity-settings-emails': (e) ->
    checked = $(e.currentTarget).is(':checked')
    if checked
      resume()
    else
      muted()