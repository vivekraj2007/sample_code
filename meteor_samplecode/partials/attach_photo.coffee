@afterUploadFileStatus = (status, index) ->
    if status and index
      thumbBoxStatus = $("#thumb-box-status-" + index)
      if status == "fail"
        thumbBoxStatus.addClass("failed-upload")
      else
        thumbBoxStatus.addClass("success-upload")
      thumbBoxStatus.append("Upload " + status)

@beforeComposeUploadFile = (parent, name, index) ->
    fileExtention = FileHelper.fileExtention(name)
    isPhoto = FileHelper.isGraphic(name)
    attach_button = parent.find(".upload-photo-btn-container")
    $("<div class='thumb-box' id='thumb-box-" + index + "'><p id='thumb-box-status-" + index + "'></p><div class='thumb thumb-loading'><img src='/images/_close.png' class='delete_file_ico' style='top:0px;right:0px;margin-right:0px;margin-top:0px;display:none'/><img class='loading' src='/images/loading.gif' style='display:block'></div><div class='file-name'>" + getShortFileName(name) + "</div></div>").insertBefore(attach_button)

@afterComposeUploadFile = (parent, name, fileId, index, fileUrl) ->
    fileExtention = FileHelper.fileExtention(name)
    isPhoto = FileHelper.isGraphic(name)
    attach_button = parent.find(".upload-photo-btn-container")
    parent.append("<input type='hidden' name='file_ids' value='" + fileId + "' index='" + index + "'>")
    file_ids = parent.find("input[name='file_ids']").map(()-> return $(this).val())
    #console.log file_ids
    thumbBox = $("#thumb-box-" + index)
    if isPhoto
      embedlyFileUrl = EmbedlyHelper.embedlyPhotoUrl fileUrl, 79, 61
      thumbBox.find("img.loading").attr("src", embedlyFileUrl)
      thumbBox.find("img.loading").removeClass("loading")
    else
      thumbBox.find("img.loading").remove()
      thumbBox.find("div.thumb").append("<div class='file " + fileExtention + "' title='" + name + "'>&nbsp;</div>")
    thumbBox.find("div.thumb-loading").removeClass("thumb-loading")
    thumbBox.find(".delete_file_ico").show()
    thumbBox.find(".delete_file_ico").click () ->
      $(this).closest('.thumb-box').remove()
      parent.find("input[name='file_ids'][index='" + index + "']").remove()
      setContactListHeight()
      file_ids = parent.find("input[name='file_ids']").map(()-> return $(this).val())
      #console.log file_ids

#     index = Math.floor((Math.random()*10000000))
#     thumbBox = HtmlHelper.getThumbBox(index, getShortFileName(name)).insertBefore attach_button
#     Meteor.call 'uploadFile', name, data, (e, fileId) ->
#       parent.append("<input type='hidden' name='file_ids' value='" + fileId + "' index='" + index + "'>")
#       file_ids = parent.find("input[name='file_ids']").map(()-> return $(this).val())
#       #console.log file_ids
#       if isPhoto
#         fileUrl = Meteor.absoluteUrl 'file/' + fileId
#         embedlyFileUrl = EmbedlyHelper.embedlyPhotoUrl fileUrl, 79, 61
#         thumbBox.find("img.loading").attr("src", embedlyFileUrl).removeClass "loading"
#       else
#         thumbBox.find("img.loading").remove()
#         thumbBox.find("div.thumb").append("<div class='file " + fileExtention + "' title='" + name + "'>&nbsp;</div>")
#       thumbBox.find("div.thumb-loading").removeClass("thumb-loading")
#       thumbBox.find(".delete_file_ico").show().click ->
#         thumbBox.remove()
#         parent.find("input[name='file_ids'][index='" + index + "']").remove()
#         setContactListHeight()
#         file_ids = parent.find("input[name='file_ids']").map(()-> return $(this).val())
#         #console.log file_ids
      
#       setContactListHeight()
#       callback()
        
#   fileReader[method](blob) 


Template.attach_photo.bucket = ->
  Meteor.settings.public.aws?.bucket

Template.attach_photo.events
  #'click .fa-picture-o': (e) ->
  #  $(".upload-photo-btn-large").trigger( "click" );
  # 'change input.upload-photo-btn-large': (e) ->
  #   uploadFileToThread(e)

Template.attach_photo.rendered = ->
  file_container = this
  $fileList = $(file_container.find("input[name='AWSAccessKeyId']")).closest('.file-list')
  # set S3 credentials for this file container
  Meteor.call 'requestCredentials', (err, credentials)->
    if err
      console.log "\n\nS3.requestCredentials: ", err
    else
      try
        if $fileList.find("input[name='AWSAccessKeyId']").length > 0
          $fileList.find("input[name='AWSAccessKeyId']").val(credentials.s3_key)
          $fileList.find("input[name='policy']").val(credentials.s3_policy)
          $fileList.find("input[name='signature']").val(credentials.s3_signature)
      catch error
        console.log error

  # init: upload file to S3 with jquery file upload 
  $(this.find('.file_upload_s3')).fileupload({
    forceIframeTransport: true,    # VERY IMPORTANT.  you will get 405 Method Not Allowed if you don't add this.
    autoUpload: true,
    add: (event, data) ->
      console.info 'upload add: ', data
      file = data.files[0]
      index = Math.floor((Math.random()*10000000))
      data.index = index
      parent = $(event.target).closest(".files_holder")
      beforeComposeUploadFile(parent, file.name, index)
      file_id = Files.insert {name: file.name, account_id: current_account()?._id, type: file.type, size: file.size}, (err, id) ->
        console.log 'Added fileId:' + id
        if Knotable.isNewTopic()
            subject = $('.thread_subject').val()
            body = $("div#message-textarea").html()
            toEmails = Knotable.getParticipators()
            composingTopicId = Session.get('ComposingTopicId')
            $fileInputs = $(event.target).closest(".files_holder").find "input[name='file_ids']"
            file_ids = $fileInputs.map(()-> return $(this).val())
            saveTopicDraft subject, body, $.makeArray(file_ids), composingTopicId

      file_key = S3_generate_unique_key(file_id, file.name)
      console.log 'File key:' + file_key
      $(file_container.find("input[name=key]")).val(file_key)
      $(file_container.find("input[name=Content-Type]")).val(file.type)
      $(file_container.find("input[name=success_action_redirect]")).val(window.location.href)
      data.file_id = file_id
      data.submit();
    send: (event, data) ->
      console.log 'sending data'
      
    fail: (event, data) ->
      console.log 'fail: ', data
      afterUploadFileStatus("fail", data.index) if data.index

    done: (event, data) ->
      parent = $(event.target).closest(".files_holder")
      fileURL = data.url+S3_generate_unique_key(data.file_id,data.files[0].name)
      afterComposeUploadFile(parent, data.files[0].name, data.file_id, data.index, fileURL)
      afterUploadFileStatus(data.textStatus, data.index)
      Files.update(data.file_id, {$set: {s3_url: fileURL}})
  });
