Template.user_mention.users = ->
  UserMention.getInstance().getFoundUsers()

Template.user_mention_item.rendered = ->
  node = $ @firstNode
  unless node.hasClass 'selected'
    return
  parent = node.parent()
  parentHeight = parent.height()
  scrollTop = parent.scrollTop()
  posTop = node.position().top
  height = node.outerHeight()
  if posTop < 0
    parent.animate scrollTop: scrollTop - parentHeight + height, 200
    return
  if posTop + height > parentHeight
    parent.animate scrollTop: scrollTop + posTop, 200

Template.user_mention_item.events
  'click .mention-item': (e) ->
    @selectAs true
    UserMention.getInstance().applySelected()
