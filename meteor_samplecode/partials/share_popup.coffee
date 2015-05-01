Template.share_popup.contacts = ->
  Contacts.find
    type: 'other'
  .fetch()

Template.share_popup.helpers
  contact_avatar: ()->
    render_avatar(@)

Template.share_popup.events
  'click .media': (e) ->
    $(e.currentTarget).toggleClass('selected')

  'click #btn-close': ->
    $('#share-popup').trigger 'close'

  'click #submit_share': ->
    $share_popup = $('#share-popup')
    share_subject = $('#share_subject').val()
    share_contacts = $share_popup.find('a.selected')
    if share_contacts.length <= 0
      alert 'You must select some contacts to share'
      return false

    share_contacts = _.map share_contacts,(c) ->
      $(c).attr('data-id')
    Meteor.call 'share_subject',$('#share_type').val(),share_subject,share_contacts,(e,r) ->
      if e
        console.log e

    $share_popup.trigger 'close'