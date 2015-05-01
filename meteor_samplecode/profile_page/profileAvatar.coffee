@contact_profile = ->
  if Meteor.userId() || isVisitor()
    profile_id = Session.get 'profile_id'
    if profile_id
      _contact = Contacts.findOne profile_id
    else if profile_email = Session.get('profile_email')
      _contact = Contacts.findOne emails: profile_email

    _contact ||= KFake.contact
    _contact

@savePhotoFile = (fileInput) ->
  contact = contact_profile()
  file = fileInput.files[0]
  isPhoto = FileHelper.isImage(file.name, file.type)

  fileReader = new FileReader()
  fileReader.onload = (readyFile) ->
    attach_button = $(fileInput).closest(".upload-photo-btn-container")
    data = new Uint8Array(file)
    index = Math.floor((Math.random()*10000000))
    $("<div class='thumb-box' id='thumb-box-" + index + "'><div class='thumb thumb-loading'><img src='/images/ban.jpg' class='delete_file_ico' style='top:0px;right:0px;margin-right:0px;margin-top:0px;display:none'/><img class='loading' src='/images/loading.gif' style='display:block'></div><div class='file-name'>" + getShortFileName(name) + "</div></div>").insertBefore(attach_button)

    Meteor.call 'uploadFile', file.name, data, (e, fileId) ->
      Meteor.call 'update_contact_photo', contact._id, fileId
      thumbBox = $("#thumb-box-" + index)
  fileReader.readAsArrayBuffer(file)

@changeActiveAvatar = (path, mini) ->
  contact = contact_profile()
  console.log "updating contact avatar: avatarpage" 
  Meteor.call 'update_contact_avatar', contact._id, path, mini

@embedlyUrl = (fileId, width=79, height=61) ->
  fileUrl = Meteor.absoluteUrl 'file/' + fileId
  embedlyFileUrl = EmbedlyHelper.embedlyPhotoUrl fileUrl, width, height

Template.profileAvatar.rendered = ->
  $("#big-container").addClass "profile-page"
  calcComponents()

Template.profile_avatars.contact_name = ->
  contact = contact_profile()
  contact.fullname if contact

Template.profile_photo_upload.photo = ->
  contact = contact_profile()
  embedlyUrl contact.account_photo

Template.profile_photo_upload.helpers
  is_checked: ->
    contact = contact_profile()
    contact.avatar && contact.avatar.path == (embedlyUrl contact.account_photo)

Template.profile_avatars.helpers
  my_username: ->
    _display_contact = contact_profile()
    _display_contact && _display_contact.type == 'me' && _display_contact.username

Template.profile_gravatars.helpers
  gravatars: ->
    _contact = contact_profile()
    _gravatars = []
    for email in _contact.emails
      _gravatar = Gravatar.imageUrl(email, {d: 404})
      _is_checked = _contact.avatar && _contact.avatar.path == _gravatar
      _gravatars.push { path: _gravatar, email: email, is_checked: _is_checked }
    _gravatars

Template.profile_photo_upload.events({
  'change .upload-photo-btn': (ev) ->
    file = ev.target
    MAX_SIZE_PER_FILE = 10 * 1024 * 1024
    if file.size > MAX_SIZE_PER_FILE
      alert 'File [' + file.name + '] is too big and will not be added. Limitation is 10MB.'
      return ''
    savePhotoFile file
  'change input[name="profile_avatar"]': (ev) ->
    _contactPhoto = contact_profile().account_photo
    changeActiveAvatar(embedlyUrl(_contactPhoto), embedlyUrl(_contactPhoto, 34, 34))
})

Template.profile_gravatars.events({
  'change input[name="profile_avatar"]': (ev) ->
    changeActiveAvatar(Gravatar.imageUrl(ev.target.value, {d: 404}), Gravatar.imageUrl(ev.target.value, {s: 34}))
})