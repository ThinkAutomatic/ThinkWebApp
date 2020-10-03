$(document).on 'pagecreate', ->
  urlToThinkAutomatic = '/api/'

  socket = null
  setTimeout (->
    if (getCookie('accessToken'))
      socket = new WebSocket("wss://socket.thinkautomatic.io?token=" + getCookie('accessToken'));
      socket.onmessage = (evt) ->
        parsedData = JSON.parse(evt.data)
        if parsedData
          if parsedData['sceneChange']
            $("div[data-tab='room-" + (parsedData['sceneChange']['roomId']).toString() + "'] input[type='radio']").prop('checked',false)
            $('#radio-scene-' + (parsedData['sceneChange']['sceneId']).toString()).prop('checked', true)
            $('.sceneChoice').checkboxradio('refresh')
          else if parsedData['deviceStatusChange']
            if parsedData['deviceStatusChange']['isOnline']
              $('[data-span-deviceId=' + (parsedData['deviceStatusChange']['deviceId']).toString() + ']').removeClass('clr-grey')
            else
              $('[data-span-deviceId=' + (parsedData['deviceStatusChange']['deviceId']).toString() + ']').addClass('clr-grey')
          else if parsedData['newDevices']
            new $.nd2Toast({ ttl: 8000, message : "New device(s) discovered", action : { title : "show", link : "/devices/discover", color: "lime" } });
  ), 100

  jQuery["taPost"] = (path, data, callback) ->
    if $.isFunction(data)
      callback = data
      data = undefined

    return $.ajax({url: urlToThinkAutomatic + path, type: "POST", contentType:"application/json", data: JSON.stringify(data), success: callback})

  jQuery["taDelete"] = (path, callback) ->
    return $.ajax({url: urlToThinkAutomatic + path, type: "DELETE", contentType:"application/json", success: callback})

  jQuery["taGet"] = (path, data, callback) ->
    if $.isFunction(data)
      callback = data
      data = undefined

    return $.ajax({url: urlToThinkAutomatic + path, type: "GET", contentType:"application/json", data: JSON.stringify(data), success: callback})

  isValid = (attrib) ->
    typeof attrib isnt 'undefined' and attrib isnt false and attrib != null

  fixedEncodeURI = (str) ->
    return encodeURI(str).replace('[', /%5B/g).replace(']', /%5D/g).replace('#', '%23')

  trimTrailingChars = (s, charToTrim) -> 
    regExp = new RegExp(charToTrim + '+$');
    result = s.replace(regExp, '');
    return result;

  getCookie = (name) ->
    value = '; ' + document.cookie.replace(/%20/g, ' ')
    parts = value.split('; ' + name + '=')
    if (parts.length == 2) 
      return parts.pop().split(';').shift()
    else 
      return undefined

  camelCaseToSpaced = (stringValue) ->
    result = stringValue.replace(/([A-Z]+)/g, " $1").replace(/([A-Z][a-z])/g, " $1")
    return result.charAt(0).toUpperCase() + result.slice(1);

  launchFullscreen = (element) ->
    if element.requestFullscreen
      element.requestFullscreen()
    else if element.mozRequestFullScreen
      element.mozRequestFullScreen()
    else if element.webkitRequestFullscreen
      element.webkitRequestFullscreen()
    else if element.msRequestFullscreen
      element.msRequestFullscreen()
  
  exitFullscreen = () ->
    if document.exitFullscreen
      document.exitFullscreen()
    else if document.mozCancelFullScreen
      document.mozCancelFullScreen()
    else if document.webkitExitFullscreen
      document.webkitExitFullscreen()

  alertDialog = (title, text) ->
    params = {}
    params['message'] = text
    params['ttl'] = 5000
    new $.nd2Toast(params);

  errorCheck = (data) ->
    if data && isValid(data['error'] && data['error']['message'])
      alertDialog('Error', data['error']['message'])
      return false
    else
      return true

  confirmDialog = (title, text, yesCallback, noCallback) ->
    if confirm(text)
      if yesCallback
        yesCallback()
    else if noCallback
      noCallback()

  timeZone = () ->
    zoneVal = -(new Date().getTimezoneOffset() / 60)
    if zoneVal < 0
      zoneVal = -1 * zoneVal
      return '-' + zoneVal.toString().padStart(2, '0')
    else
      return '+' + zoneVal.toString().padStart(2, '0')

  padNum = (n) ->
    if (n < 10)
      return '0' + n.toString()
    else
      return n.toString()

  dateTimeFromStr = (datetimeStr) ->
    arr = (datetimeStr + '+00').split(/[- :\+]/)
    return new Date(parseInt(arr[0]), parseInt(arr[1])-1, parseInt(arr[2]), parseInt(arr[3]), parseInt(arr[4]), parseInt(arr[5]))

  convertToLocalTime = (datetimeStr) ->
    dt = dateTimeFromStr(datetimeStr)
    dt.setHours(dt.getHours() - (new Date().getTimezoneOffset() / 60));
    return dt.getFullYear().toString() + '-' + padNum(dt.getMonth() + 1) + '-' + padNum(dt.getDate()) + ' ' + padNum(dt.getHours()) + ':' + padNum(dt.getMinutes()) + timeZone()

  convertToISOTimeFormat = (datetimeStr) ->
    dt = dateTimeFromStr(datetimeStr)
    return dt.toISOString()

  $('.dtPicker').appendDtpicker({'closeOnSelected': true, 'futureOnly': true, 'autodateOnStart': true})

  $('.shareKey').click ->
#    alert((new Date()).toString())
#    alert((new Date('2016-04-28 19:02:00+00')).toString())
#    alert((new Date()) > (new Date('2016-04-28 19:02:00+00')))
    $('#keyPopupTitle').text('New Home Key')
    $('#deleteKey').hide()
    $('#editKeyName').val('')
    $('#dtPickerStart').val('')
    $('#dtPickerEnd').val('')
    $('#editKeyPopupDialog').removeAttr('data-homeKeyId')
    $('#editKeyPopupDialog').removeAttr('data-token')
    $('#editKeyPopupDialog').popup('open')

  $('.editHomeKey').click ->
    $.mobile.loading('show')
    $('#keyPopupTitle').text('Edit Home Key')
    $('#deleteKey').show()
    $.taGet 'homeKeys/' + $(this).attr('data-homeKeyId'), (response) ->    
      $.mobile.loading('hide')
      if response == null
        alertDialog('', 'Unable to access key')
      else
        $('#editKeyPopupDialog').attr('data-homeKeyId', response['homeKeyId'])
        $('#editKeyPopupDialog').attr('data-token', response['token'])
        if response['name']
          $('#editKeyPopupDialog').attr('data-keyName', response['name'])
        else
          $('#editKeyPopupDialog').attr('data-keyName', 'key: ' + response['homeKeyId'].toString())
        $('#editKeyName').val(response['name'])
        $('#dtPickerStart').val('')
        $('#dtPickerEnd').val('')
        if response['validStart']
          $('#dtPickerStart').val(convertToLocalTime(response['validStart']))
        if response['expiration']
          $('#dtPickerEnd').val(convertToLocalTime(response['expiration']))
        $('#editKeyPopupDialog').popup('open')

  $('#deleteKey').click (event) ->
    confirmDialog('Confirm', 'Delete ' + $('#editKeyPopupDialog').attr('data-keyName') + '? Cannot be undone.'
      ->
        $.mobile.loading('show')
        $.taDelete 'homeKeys/' + $('#editKeyPopupDialog').attr('data-homeKeyId'), (response) ->
          window.location.href = '/homes/keys'
          return true
      ->
        return false
    )

  submitKey = (cb) ->
    postData = {}
    postData['name'] = $('#editKeyName').val()
    postData['homeId'] = parseInt(getCookie('homeId'))
    if $('#dtPickerStart').val()
      postData['validStart'] = convertToISOTimeFormat($('#dtPickerStart').val().toString())
    if $('#dtPickerEnd').val()
      postData['expiration'] = convertToISOTimeFormat($('#dtPickerEnd').val().toString())
    if $('#editKeyPopupDialog').attr('data-homeKeyId')
      path = 'homeKeys/' + $('#editKeyPopupDialog').attr('data-homeKeyId')
    else
      path = 'homeKeys'
    $.taPost path, postData, cb

  $('.editKeyForm').submit ->
    $.mobile.loading('show')
    submitKey((response)->
      $.mobile.loading('hide')
      if errorCheck(response)
        window.location.href = '/homes/keys'
        setTimeout (->
          window.location.reload()
        ), 100
        return true
      else
        return false
    )

  $('#editKeyShare').click ->
    $.mobile.loading('show')
    submitKey((response)->
      $.mobile.loading('hide')
      if isValid(response['error'] && response['error']['message'])
        alertDialog('Error', response['error']['message'])
      else
        $('#editKeyPopupDialog').popup('close')
        setTimeout (->
          $('#shareKeyPopupTitle').text('Share ' + response['homeName'] + ' Key')
          $('#keyLink').text('https://app.thinkautomatic.io/homes?homeId=' + response['homeId'].toString() + '&homeKey=' + response['keyToken'])
          $('#shareKeyPopupDialog').popup('open')
        ), 100
    ) 

  $('#copyLinkToClipboard').click ->
    $('#keyLink').focus()
    $('#keyLink').select()
    try
      $('#keyLink').setSelectionRange(0, $('#keyLink').value.length)

    result = document.execCommand('copy')
    if result
      $('#copyLinkToClipboard').text('Link copied')
    else
      $('#copyLinkToClipboard').text('Unable to copy link')

  $('#shareKeyPopupDialog').on 'popupafterclose', () -> 
    $.mobile.loading('show')
    window.location.reload()

  $('#editKeyPopupDialog').on 'popupafterclose', () -> 
    $('.dtPicker').each ->
      $(this).handleDtpicker('hide');

  sendPhraseCommand = (phraseElem) ->
    postData = {}
    postData['phrase'] = $('.nd2Tabs-active').attr('data-roomName') + ' ' + phraseElem.val()
    phraseElem.val('')
    $.mobile.loading('show')
    $.taPost 'commands/' + getCookie('homeId').toString() + '/phrase', postData, (response) ->
      if response && response['message']
        $.mobile.loading('hide')
        params = {}
        params['message'] = response['message']
        params['action'] = {}
        params['action']['title'] = 'Refresh'
        params['action']['fn'] = ->
          $.mobile.loading('show')
          window.location.href = '/'
          return true          
        params['action']['color'] = 'lime'
        params['ttl'] = 10000
        new $.nd2Toast(params);
      else if errorCheck(response)
        $.mobile.loading('show')
        window.location.href = '/'
        return true

  $('.phraseVal').click ->
    if $(this).val() != ''
      sendPhraseCommand($(this))

  $('.phraseVal').blur ->
    if $(this).val() != ''
      sendPhraseCommand($(this))

  $('#roomTabs').click (event, ui) ->
    postData = {}
    roomId = $('.nd2Tabs-active').attr('data-roomId')
    postData['roomId'] = roomId
    $.post '/rooms/select', postData, (response) ->
      $('.showDevices').attr('href', '#room-' + roomId + '-device-panel')
      if roomId == '0'
        setTimeout (->
          $('.showDevices').trigger('click')
        ), 100

  $('#testButton').click ->
    launchFullscreen(document.documentElement)

  $('.homeChoice').click ->
    $.mobile.loading('show')
    window.location.href = '/?homeId=' + $(this).attr('data-homeId')
    return true

  $('.sceneChoice').click (event) ->
    $.taPost 'scenes/' + $(this).attr('data-sceneId') + '/select', {}, (response) ->
      errorCheck(response)
      return false

  $('.assocDevicePopup').click (event) ->
    $('#assocDeviceSubmit').attr('data-directUrl', $(this).attr('data-directUrl'))
    roomIdSelected = '0'
    if getCookie('roomId') && !($(this).attr('data-isHub') == 'true') && ($("#assocDeviceRoomSelect option[value='" + getCookie('roomId') + "']").length > 0)
      roomIdSelected = getCookie('roomId')
    $('#assocDeviceRoomSelect').val(roomIdSelected).change()    
    $('#assocDevicePopupTitle').text($(this).attr('data-deviceName'))
    $('#assocDevicePopupDialog').popup('open')

  $('#assocDeviceSubmit').click (event) ->
    linkPath = '/devices/link?directUrl=' + $(this).attr('data-directUrl')
    roomIdSelected = $('#assocDeviceRoomSelect').find('option:selected').val()
    if roomIdSelected != '0'
      linkPath += '&roomId=' + roomIdSelected.toString()

    $.mobile.loading('show')
    window.location.href = linkPath
    return true

  $('.cancelSelectDeviceType').click (event) ->
    $('#deviceTypesDiv').hide()

  $('#linkDeviceSubmit').click (event) ->
    postData = {}
    linkPath = ''
    linkMessage = ''
    $.mobile.loading('show')
    roomIdSelected = $('#linkDeviceRoomSelect').find('option:selected').val()
    if roomIdSelected == '0'
      linkMessage = 'Link command sent for current home'
      linkPath = 'homes/' + getCookie('homeId').toString() + '/link'
    else
      linkMessage = 'Link command sent for ' + $('#linkDeviceRoomSelect').find('option:selected').text()
      linkPath = 'rooms/' + roomIdSelected.toString() + '/link'

    if $('#linkDeviceName').attr('data-name')
      postData['name'] = $('#linkDeviceName').attr('data-name')
    if $('#deviceTypesDiv').is(":visible")
      postData['deviceTypeUuid'] = $('#selectDeviceTypeSelect option:selected').val()

      $.taGet 'deviceTypes/' + postData['deviceTypeUuid'], (dtResponse) ->    
        $.mobile.loading('hide')
        if dtResponse != null
          if dtResponse['preLinkInstructions']
            alert(dtResponse['preLinkInstructions'])

          $.mobile.loading('show')
          $.taPost linkPath, postData, (response) ->
            $.mobile.loading('hide')
            if !dtResponse['postLinkInstructions']
              alertDialog('', linkMessage)
            else
              if response['linkCode']
                alert(dtResponse['postLinkInstructions'].replace('{linkCode}', response['linkCode'].toString()) + '   Link code: ' + response['linkCode'].toString());
              else
                alert(dtResponse['postLinkInstructions'])
        else
          alertDialog('Error', 'Unable to find device type information.')
    else
      $.mobile.loading('show')
      $.taPost linkPath, postData, (response) ->
        $.mobile.loading('hide')
        alertDialog('', linkMessage)
   
  $('#deviceTypeSearchSubmit').click (event) ->
    params = {}
    $.mobile.loading('show')
    params['filter'] = $('#deviceTypeSearch').val()
    $.taGet 'deviceTypes/search', params, (response) ->    
      $.mobile.loading('hide')
      if response == null
        alertDialog('', 'No matching device types found')
      else
        $('#selectDeviceTypeSelect').find('option').remove()
        $('#deviceTypesDiv').show()
        selectedOne = null
        $.each(response, (index, value) ->
          $('#selectDeviceTypeSelect').append('<option value=' + value['deviceTypeUuid'] + '>' + value['name'] + ' [' + value['ownerUserName'] + ']</option>');
          if selectedOne == null
            selectedOne = value['deviceTypeUuid']
        )
        $('#selectDeviceTypeSelect').val(selectedOne).change()

  $('#linkDeviceType').click (event) ->
    $('#linkDevicePopupDialog').attr('data-reload', 'false')
    $('#linkDevicePopupDialog').popup('close')
    setTimeout (->
      $('#selectDeviceTypePopupDialog').popup('open')
    ), 100

  $('#linkDeviceName').click (event) ->
    $('#deleteObject').hide()
    $('#linkDevicePopupDialog').attr('data-reload', 'false')
    $('#linkDevicePopupDialog').popup('close')
    setTimeout (->
      editObject('Device Name', null, 'Name for new device(s)', 'true')
    ), 100

  sendSlideEvents = (slider) ->
    postData = {}
    postData[slider.attr('data-actionName')] = slider.val().toString();
    if (slider.attr('data-sliding').toString() == 'true') && (slider.attr('data-lastVal') == slider.val().toString())
      setTimeout (->
        sendSlideEvents(slider)
      ), 100
      return
    slider.attr('data-lastVal',slider.val().toString())

    $.taPost 'commands/' + slider.attr('data-deviceId').toString(), postData, (response) ->
      if slider.attr('data-sliding').toString() == 'true'
        setTimeout (->
          sendSlideEvents(slider)
        ), 100
      else
        $.taPost 'devices/' + slider.attr('data-deviceId').toString(), postData, (response) ->
          errorCheck(response)
          return

  $('#deviceTypeSelectSubmit').click (event) ->
    if $('#deviceTypesDiv').is(":visible")
      cache = $('#linkDeviceType').children()
      $('#linkDeviceType').empty()
      $('#linkDeviceType').text($('#selectDeviceTypeSelect option:selected').text()).append(cache)
    $('#selectDeviceTypePopupDialog').popup('close')

  $('#selectDeviceTypePopupDialog').on 'popupafterclose', () -> 
    $('#linkDevicePopupDialog').popup('open')

  $('#linkDevicePopupDialog').on 'popupafterclose', () -> 
    if $('#linkDevicePopupDialog').attr('data-reload') == 'true'
      $.mobile.loading('show')
      window.location.reload()
    else
      $('#linkDevicePopupDialog').attr('data-reload', 'true')

  $('#devicePopupDialog').on 'popupafterclose', () -> 
    if $('#devicePopupDialog').attr('data-reload') == 'true' # || true
      $.mobile.loading('show')
      window.location.reload()

  $('#deviceRoomSelect').change () ->
    if $(this).attr('data-initializing') == 'true'
      $(this).removeAttr('data-initializing')
      return false
    else
      optionSelected = $(this).find('option:selected')
      deviceId = $(this).attr('data-DeviceId').toString()
      confirmDialog('Confirm', 'Move ' + $(this).attr('data-DeviceName') + ' to ' + optionSelected.text() + '?'
        ->
          postData = {}
          postData['roomId'] = parseInt(optionSelected.val())
          $.mobile.loading('show')
          $.taPost 'devices/' + deviceId, postData, (response) ->
            if errorCheck(response)
              window.location.href = '/'
              return true
            else
              return false
        ->
          return false
      )

  $('.linkDevicePopup').click (event) ->
    if $(this).attr('data-roomId')
      $('#linkDeviceRoomSelect').val($(this).attr('data-roomId')).change()
    $('#linkDevicePopupDialog').popup('open')

  handleStep = (element, direction) ->
    parentElem = element.parent() 
    valueElem = parentElem.find('.buttonValue')
    buttonValue = parseInt(valueElem.text())
    stepValue = parseInt(parentElem.attr('data-rangeStep'))
    if direction == 'plus' && (buttonValue + stepValue <= parseInt(parentElem.attr('data-rangeHigh')))
      buttonValue += stepValue
    else if direction == 'minus' && (buttonValue - stepValue >= parseInt(parentElem.attr('data-rangeLow')))
      buttonValue -= stepValue

    valueElem.text(buttonValue.toString())

    postData = {}
    postData[parentElem.attr('data-actionName')] = buttonValue.toString()

    $.taPost 'devices/' + parentElem.attr('data-deviceId').toString(), postData, (response) ->
      errorCheck(response)

  $(document).on 'click','.buttonPlus', (event) ->
    handleStep($(this), 'plus')

  $(document).on 'click','.buttonMinus', (event) ->
    handleStep($(this), 'minus')

  $(document).on 'change','.modeSelect', (event) ->
    postData = {}
    postData[$(this).attr('data-modeName')] = $(this).find('option:selected').val()
    $.mobile.loading('show')
    $.taPost 'devices/' + $(this).attr('data-deviceId').toString(), postData, (response) ->
      errorCheck(response)
      setTimeout (->
        window.location.reload()
      ), 100

  checkMode = (device, modes, actionType) ->
    result = true
    if modes
      $.each modes, (modeName, modeValues) -> 
        if device[modeName] && actionType['modes'] && actionType['modes'][modeName]
          if 0 > $.inArray(device[modeName], actionType['modes'][modeName])
            result = false
    return result

  $('.device').click (event) ->
    $('[data-role=panel]').panel('close')
    cache = $('#devicePopupTitle').children()
    $('#devicePopupTitle').text('Loading...')
    $('#devicePopupSettingControls').empty()
    $('#devicePopupControls').empty()
    $('#devicePopupEmpty').hide()
    $('#deviceDirectUrlDiv').hide()
    $('#devicePopupSettings').hide()
    $('#devicePopupDialog').popup('open')

    deviceId = $(this).attr('data-deviceId')
    $.taGet 'devices/' + deviceId.toString(), {}, (deviceInfo) ->
      if deviceInfo['deviceId']
        $.taGet 'devices/' + deviceId.toString() + '/deviceType', (deviceTypeInfo) ->
          if deviceInfo['name']
            $('#devicePopupTitle').text(deviceInfo['name']).append(cache)
            $('#deleteDevice').attr('data-objectName', deviceInfo['name'])
          else
            $('#devicePopupTitle').text(deviceTypeInfo['name']).append(cache)
            $('#deleteDevice').attr('data-objectName', deviceTypeInfo['name'])

          $('#deleteDevice').attr('data-path', 'devices/' + deviceInfo['deviceId'].toString())
          $('#deviceRoomSelect').attr('data-deviceId', deviceId)
          $('#deviceRoomSelect').attr('data-deviceName', $('#deleteDevice').attr('data-objectName'))
          $('#deviceRoomSelect').attr('data-initializing', 'true')
          if deviceInfo['roomId']
            $('#deviceRoomSelect').val(deviceInfo['roomId']).change()
          else
            $('#deviceRoomSelect').val('0').change()
          $('#devicePopupEmpty').show()

          if deviceTypeInfo['modes']
            modeHTML = ''
            $.each deviceTypeInfo['modes'], (modeName, modeValues) -> 
              modeHTML += '<label for="modeSelect-' + modeName + '">' + camelCaseToSpaced(modeName) + ':</label><select class="modeSelect" data-modeName="' + modeName + '" data-deviceId="' + deviceInfo['deviceId'].toString() + '" id="modeSelect-' + modeName + '" name="modeSelect-' + modeName + '">'
              $.each modeValues, (i, modeValue) ->
                selectedStr = ''
                if deviceInfo[modeName] && (deviceInfo[modeName] == modeValue)
                  selectedStr = '" selected="selected'
                modeHTML += '<option value="' + modeValue + selectedStr + '">' + modeValue + '</option>'
              modeHTML += '</select>'
            $('#devicePopupControls').append(modeHTML).trigger('create')

          if deviceTypeInfo['actionTypes']
            $.each deviceTypeInfo['actionTypes'], (i, actionType) -> 
              if actionType['receive'] && checkMode(deviceInfo, deviceTypeInfo['modes'], actionType)
                $('#devicePopupEmpty').hide()
                control = $('#devicePopupControls')
                if actionType['isSetting']
                  $('#devicePopupSettings').show()
                  control = $('#devicePopupSettingControls')

                if isValid(actionType['rangeLow']) && isValid(actionType['rangeHigh'])
                  currentLevel = actionType['rangeLow']
                  if deviceInfo[actionType['name']]
                    currentLevel = deviceInfo[actionType['name']]

                  if isValid(actionType['rangeStep'])
                    stepperId = 'stepper-' + deviceId.toString() + actionType['name']
                    control.append("""
                    <label for=\"""" + stepperId + '">' + camelCaseToSpaced(actionType['name']) + """:</label>
                    <div id=\"""" + stepperId + '" name="' + stepperId + '" class="box" data-deviceId="' + deviceId.toString() + '" data-actionName="' + actionType['name'] + '" data-rangeStep="' + actionType['rangeStep'] + '" data-rangeLow="' + actionType['rangeLow'] + '" data-rangeHigh="' + actionType['rangeHigh'] + """\">
                      <a href="#" class="ui-btn ui-btn-inline ui-btn-raised buttonMinus"><i class="zmdi zmdi-minus zmd-2x"></i></a>
                      <a href="#" class="ui-btn ui-btn-inline buttonValue">""" + currentLevel + """</a>
                      <a href="#" class="ui-btn ui-btn-inline ui-btn-raised buttonPlus"><i class="zmdi zmdi-plus zmd-2x"></i></a>
                    </div>""").trigger('create')
                  else
                    sliderId = 'slider-' + deviceId.toString() + actionType['name']
                    control.append('<label for="' + sliderId + '">' + camelCaseToSpaced(actionType['name']) + ':</label>').trigger('create')

                    control.append('<input id="' + sliderId + '" data-sliding="false" data-deviceId="' + deviceId.toString() + '" data-actionName="' + actionType['name'] + '" type="range" name="' + sliderId + '" data-lastVal="' + currentLevel + '" value="' + currentLevel + '" min="' + actionType['rangeLow'] + '" max="' + actionType['rangeHigh'] + '" data-highlight="true">').trigger('create')
                    $('#' + sliderId).slider
                      start: (event, ui) ->
                        $(this).attr('data-sliding', 'true')
                        $('#devicePopupDialog').attr('data-reload', 'true')
                        sendSlideEvents($(this))
                      stop: (event, ui) ->
                        $(this).attr('data-sliding', 'false')
                else if isValid(actionType['activate']) && isValid(actionType['deactivate']) 
                  flipId = 'flip-' + deviceId.toString() + actionType['name']
                  control.append('<label for="' + flipId + '">' + camelCaseToSpaced(actionType['name']) + ':</label>').trigger('create')

                  currentState = actionType['deactivate']
                  if deviceInfo[actionType['name']]
                    currentState = deviceInfo[actionType['name']]

                  selectedStr = ''
                  if actionType['activate'] == currentState
                    selectedStr = '" selected="selected'

                  control.append('<select id="' + flipId + '" name="' + flipId + '" class="flipControl" data-deviceId="' + deviceId.toString() + '" data-actionName="' + actionType['name'] + '" data-role="flipswitch"><option value="' + actionType['deactivate'] + '">' + actionType['deactivate'] + '</option><option value="' + actionType['activate'] + selectedStr + '">' + actionType['activate'] + '</option></select>').trigger('create')
          if deviceInfo['directUrl']
            $('#deviceDirectUrl').attr('href', deviceInfo['directUrl'])
            $('#deviceDirectUrlDiv').show() 
            $('#devicePopupSettings').show()                
          $('#devicePopupDialog').popup('reposition', {positionTo: 'window'});
      else
        $('#devicePopupTitle').text('Error').append(cache)
        $('#devicePopupDialog').popup('reposition', {positionTo: 'window'});

  editObject = (title, path, placeholder, dataLink) ->
    $.mobile.loading('hide')
    $('#editObjectPopupTitle').text(title)
    $('#editObjectSubmit').attr('data-path', path)
    $('#editObjectSubmit').attr('data-link', dataLink)
    $('#editObjectVal').attr('placeholder', placeholder)
    $('#editObjectVal').removeAttr('value')
    $('#editObjectVal').val('')
    $('#editObjectPopupDialog').popup('open')
    $('#deleteObject').attr('data-objectName', title)
    $('#deleteObject').attr('data-path', path)

  $('.newHome').click ->
    $('#deleteObject').hide()
    editObject('Add New Home', 'homes', 'Name for new home', 'false')

  $('.newRoom').click ->
    $('#deleteObject').hide()
    editObject('Add New Room', 'rooms', 'Name for new room', 'false')

  $('.editHome').click ->
    $('#deleteObject').show()    
    editObject($(this).attr('data-homeName'), 'homes/' + getCookie('homeId'), 'New name for ' + $(this).attr('data-homeName'), 'false')

  $('.editRoom').click ->
    $('#deleteObject').show()    
    editObject($(this).attr('data-roomName'), 'rooms/' + $(this).attr('data-roomId'), 'New name for ' + $(this).attr('data-roomName'), 'false')

  $('.editScene').click (event) ->
    $('#deleteObject').show()    
    editObject($(this).attr('data-sceneName'), 'scenes/' + $(this).attr('data-sceneId'), 'New name for ' + $(this).attr('data-sceneName'), 'false')

  $(document).on 'click','.renameDevice', (event) ->
    $('#deleteObject').hide()
    $('#devicePopupDialog').attr('data-reload', 'false')
    $('#devicePopupDialog').popup('close')
    path = $('#deleteDevice').attr('data-path')
    deviceName = $('#deleteDevice').attr('data-ObjectName')
    setTimeout (->
      editObject(deviceName, path, 'New name for ' + deviceName, 'false')
    ), 100

  $(document).on 'change','.flipControl', (event) ->
    postData = {}
    postData[$(this).attr('data-actionName')] = $(this).find('option:selected').val();
    $.taPost 'devices/' + $(this).attr('data-deviceId').toString(), postData, (response) ->
      errorCheck(response)
      return false

  $('#editObjectPopupDialog').on 'popupafterclose', () -> 
    if $('#editObjectSubmit').attr('data-link') == 'true'
      $('#linkDevicePopupDialog').popup('open')

  $('#editObjectSubmit').click ->
    postData = {}
    if $(this).attr('data-link') == 'true'
      cache = $('#linkDeviceName').children()
      $('#linkDeviceName').attr('data-name', $('#editObjectVal').val())
      $('#linkDeviceName').text($('#editObjectVal').val()).append(cache)
      $('#editObjectPopupDialog').popup('close')
      return false
    else
      postData['name'] = $('#editObjectVal').val()
      postData['homeId'] = Number(getCookie('homeId'))
      $.mobile.loading('show')
      $.taPost $(this).attr('data-path'), postData, (response) ->
        if errorCheck(response)
          if response['homeId']
            if response['roomId']
              window.location.href = '/?homeId=' + response['homeId'] + '&roomId=' + response['roomId']
            else
              window.location.href = '/?homeId=' + response['homeId']
          else
            window.location.href = '/'
          setTimeout (->
            return true
          ), 100
        else
          alertDialog('Error', 'Unexpected error')
          return false

  $('.deleteObject').click (event) ->
    path = $(this).attr('data-path')
    confirmDialog('Confirm', 'Delete ' + $(this).attr('data-objectName') + '? Cannot be undone.'
      ->
        $.mobile.loading('show')
        $.taDelete path, (response) ->
          window.location.href = '/'
          return true
      ->
        return false
    )

  $('.settingsForm').submit ->
    event.preventDefault()
    if $('#password').val() isnt $('#confirmPassword').val()
      alertDialog('Error', 'Password and confirmation do not match')
      $('#password').focus()
      return false
    else 
      postData = {}
      postData['userName'] = $('#userName').val()
      postData['emailAddress'] = $('#emailAddress').val()
      if $('#password').val() != ''
        postData['password'] = $('#password').val()
      $.mobile.loading('show')
      $.post 'settings', postData, (response) ->
        $.mobile.loading('hide')
        if errorCheck(response)
          if response.emailVerified
            alertDialog('Success', 'Settings saved')
          else
            alertDialog('Success', 'New email verification sent')
          setTimeout (->
            window.location.href = '/'
          ), 4000
        return false

  $('.emailSigninForm').submit ->
    event.preventDefault()
    postData = {}
    postData['userName'] = $('#userName').val()

    $.mobile.loading('show')
    $.taPost 'users/emailsignin', postData, (response) ->
      $.mobile.loading('hide')
      if errorCheck(response)
        alertDialog('Success', 'Email signin link sent')
      return false

# this is not working for some reason
#  $('.selectHome').click ->
#    setTimeout (->
#      $('#homeList').trigger('expand') 
#    ), 100

  $('.signupForm').validate

  $('.signupForm').submit ->
    event.preventDefault()
    if $('#password').val() isnt $('#confirmPassword').val()
      alertDialog('Password Error', 'Password and confirmation do not match.')
      $('#password').focus()
      return false
    else 
      postData = {}
      postData['userName'] = $('#userName').val()
      postData['emailAddress'] = $('#emailAddress').val()
      postData['password'] = $('#password').val()
      $.mobile.loading('show')
      $.post '/users/signup', postData, (response) ->
        data = response
        if !errorCheck(data)
          setTimeout (->
            window.location.href = '/users/signup'
          ), 6000
        else if isValid(data['userName']) && isValid(data['emailAddress'])
          alertDialog('Success', 'Registration succeeded!')
          setTimeout (->
            window.location.href = '/users/registered'
          ), 4000
        return false

  $('.signinForm').submit ->
    event.preventDefault()
    path = '/'
    if getCookie('editDeviceTypes')
      path = '/devicetypes'
    postData = {}
    postData['userName'] = $('#userName').val()
    postData['password'] = $('#password').val()
    $.mobile.loading('show')
    $.post '/users/signin', postData, (response) ->
      if errorCheck(response)
        window.location.href = path
        return true
      else
        setTimeout (->
          window.location.href = '/users/signin'
        ), 3000
        return false

  $('.signoutButton').click ->
    window.location.href = '/users/signout'
    return true

  deviceType = {}
  actionTypes = []
  deviceTypeStep = 0
  yesNoAnswer = 'unknown'
  modeName = ''
  modes = null
  eventCommandName = ''
  newAttrName = ''
  currentActionType = {}
  singleActionAdd = false

  $('#yesNoYes').click ->
    yesNoAnswer = 'yes'
    handleDeviceTypeWizardStep()

  $('#yesNoNo').click ->
    yesNoAnswer = 'no'
    handleDeviceTypeWizardStep()

  setTitlePrompt = (title, prompt) ->
    $('.popupTitle').text(title)
    $('.prompt').text(prompt)

  yesNoPopup = (title, prompt) ->
    setTitlePrompt(title, prompt)
    $('#yesNoPopupDialog').popup('open')

  getNamePopup = (title, prompt, placeholder, propName) ->
    setTitlePrompt(title, prompt)
    $('#getNameVal').attr('data-propName', propName)    
    $('#getNameVal').val('')
    $('#getNameVal').attr('placeholder', placeholder)
    $('#getNamePopupDialog').popup('open')
    $('#getNameVal').focus()

  getInstructionsPopup = (title, prompt, placeholder, propName) ->
    setTitlePrompt(title, prompt)
    $('#getInstructionsVal').attr('data-propName', propName)    
    $('#getInstructionsVal').val('')
    $('#getInstructionsVal').attr('placeholder', placeholder)
    $('#getInstructionsPopupDialog').popup('open')
    $('#getInstructionsVal').focus()

  modeNames = () ->
    response = ''
    $.each(modes, (modeName, modeValues) ->
      if response != ''
        response += ', '
      response += modeName
    )
    return response

  selectModesPopup = (title, prompt) ->
    setTitlePrompt(title, prompt)
    modesContent = $('.selectModesContent')
    modesContent.empty()
    $.each(modes, (modeName, modeValues) ->
      fieldSetContent = $('<legend>')
      fieldSetContent.text(modeName.toString() + ':')
      $.each(modeValues, (index, modeVal) ->
        fieldSetContent.append('<input type="checkbox" name="checkbox-' + modeName + modeVal + '" id="checkbox-' + modeName + modeVal + '">').trigger('create')
        fieldSetContent.append('<label for="checkbox-' + modeName + modeVal + '">' + camelCaseToSpaced(modeVal) + '<label>')
      )
      modesContent.append(fieldSetContent).trigger('create')
    )
    $('#selectModesPopupDialog').popup('open')

  gotoStep = (step) ->
    deviceTypeStep = step
    switch (deviceTypeStep)
      when 10
        getNamePopup('Device Type Name', 'What is the name of the new device type?', 'Enter name here', 'name')
      when 20
        yesNoPopup('Hub Device', 'Is "' + deviceType['name'] + '" a hub device which relays messages for other devices?')
      when 30
        yesNoPopup('Events / Commands', 'Does a "' + deviceType['name'] + '" report events and/or receive commands other than relaying messages for other devices?')
      when 40
        getNamePopup('Category', 'What type of device is a "' + deviceType['name'] + '"? e.g. lighting, thermostat, door lock')
      when 50
        yesNoPopup('Events / Commands', 'Does a "' + deviceType['name'] + '" report events and/or receive commands?')
      when 100
        yesNoPopup('Modes', 'Does a "' + deviceType['name'] + '" support different modes of operation? e.g. heating mode vs. cooling, input (audio/video/game), units (C/F for temperature)')
      when 110
        getNamePopup('Mode', 'What is the name of a single type of mode? e.g. input, units, mode')
      when 120
        getNamePopup('Mode', 'What is the name of a single mode of operation for "' + modeName + '"? e.g. heat, video, Celsius')
      when 130
        yesNoPopup('More modes', 'Does "' + modeName + '" support additional mode settings besides "' + modes[modeName].toString() + '"?')
      when 140
        yesNoPopup('Modes', 'Does the device "' + deviceType['name'] + '" support any additional types of modes besides "' + modeNames() + '"?')
      when 150
        getNamePopup('Mode', 'What is the name of an additional single type of mode? e.g. input, units, mode')
      when 1000
        getNamePopup('Event / Command', 'What is the name of a single event or command that a "' + deviceType['name'] + '" can send or receive? e.g. power, button, volume, brightness', 'Enter event/command name here', 'name')
      when 1020
        selectModesPopup('Modes', 'What modes of operation does "' + eventCommandName + '" apply to? Select all that apply')
      when 1030
        yesNoPopup('Range', 'Does "' + eventCommandName + '" support a range of numeric values? e.g. 0 to 100')
      when 1100
        getNamePopup('Range', 'What is the minimum value for "' + eventCommandName + '"? e.g. 0', 'Enter minimum value here', 'rangeLow')
      when 1101
        getNamePopup('Range', 'What is the maximum value for "' + eventCommandName + '"? e.g. 100', 'Enter maximum value here', 'rangeHigh')
      when 1102
        getNamePopup('Range', 'What are the number of decimal points of precision (optional)?', 'Enter number of digits to right of decimal point here', 'rangePrecision')
      when 1103
        getNamePopup('Range', 'What is the default step size for adjusting "' + eventCommandName + '" up or down (optional)?', 'Enter step size here', 'rangeStep')
      when 1104
        gotoStep(1110)
      when 1110, 2030
        yesNoPopup('Command', 'Is "' + eventCommandName + '" a command that can be received and understood by a "' + deviceType['name'] + '"?')
      when 1120
        yesNoPopup('Setting', 'Is "' + eventCommandName + '" used as part of normal operation of a "' + deviceType['name'] + '" rather than an infrequently used setting? e.g. sound volume on a TV would be used in normal operation but screen brightness would be an infrequently used setting')
      when 1130, 2110
        yesNoPopup('Learning', 'Should "' + eventCommandName + '" be learned by the platform?')
      when 1140, 2120
        yesNoPopup('Learning', 'Should the platform guess "' + eventCommandName + '" values vs. only remembering them? e.g. guessing light brightness is appropriate but not stereo volume level')
      when 2000
        yesNoPopup('Activation / Deactivation State', 'Does "' + eventCommandName + '" have an activation/dectivation state? e.g. on/off, unlocked/locked')
      when 2010
        getNamePopup('Activation State', 'What is the name of the "' + eventCommandName + '" activated state? e.g. on, open, unlock', 'Enter activated state value here', 'activate')
      when 2020
        getNamePopup('Deactivation State', 'What is the name of the "' + eventCommandName + '" deactivated state? e.g. off, close, lock', 'Enter deactivated state value here', 'deactivate')
      when 2040
        yesNoPopup('Event', 'Is "' + eventCommandName + '" an event or status change that can be sent from / reported by a "' + deviceType['name'] + '"?')
      when 2050
        yesNoPopup('Trigger', 'Should "' + eventCommandName + '" events from a "' + deviceType['name'] + '" trigger scene changes involving other devices?')
      when 2060
        yesNoPopup('Wake Up Trigger', 'Should "' + eventCommandName + '" events from a "' + deviceType['name'] + '" only serve as a wake up trigger? (for example a motion sensor trigger)')
      when 3000
        yesNoPopup('More Events / Commands', 'Are there additional events/commands supported by a "' + deviceType['name'] + '"?')
      when 3005
        yesNoPopup('Link code', 'Should "' + deviceType['name'] + '" make use of a 6 digit link code? e.g. a way for a device managed by an external service to authenticate via user interaction (if in doubt choose no)')
      when 3010
        getInstructionsPopup('Pre-Link Instructions', 'Instructions to prepare a "' + deviceType['name'] + '" before a linking/pairing command is issued from platform (optional and can be added later)?', 'Enter instructions here', 'preLinkInstructions')
      when 3020
        getInstructionsPopup('Post-Link Instructions', 'Instructions to finalize linking/pairing on a "' + deviceType['name'] + '" after a link command is issued from platform (optional and can be added later)?', 'Enter instructions here', 'postLinkInstructions')
      when 3030
        yesNoPopup('Additional Attributes', 'Would you like to add additional optional attributes to "' + deviceType['name'] + '" such as model name or version number? Can also be added later.')
      when 3040
        getNamePopup('Attribute Name', 'What is the name of the additional attribute?', 'Enter attribute name here', '')
      when 3050
        getNamePopup('Attribute Value', 'What is the value for "' + newAttrName + '"?', 'Enter attribute value here', newAttrName)
      when 3060
        yesNoPopup('Additional Attributes', 'Would you like to add another attribute for "' + deviceType['name'] + '"?')
      when 4000
        deviceType['actionTypes'] = actionTypes
        if modes
          deviceType['modes'] = modes
        saveAsDraft()

  handleYesNo = (yesNoAnswer, yesStep, noStep) ->
    if yesNoAnswer == 'yes'
      gotoStep(yesStep)
    else
      gotoStep(noStep)

  addProp = (element) ->
    if !($('#getNameVal').val() == '') && !($('#getNameVal').attr('data-propName') == '')
      element[$('#getNameVal').attr('data-propName')] = $('#getNameVal').val()

  addNumProp = (element) ->
    if !($('#getNameVal').val() == '') && !($('#getNameVal').attr('data-propName') == '')
      element[$('#getNameVal').attr('data-propName')] = parseInt($('#getNameVal').val())

  handleDeviceTypeWizardStep = () ->
    $("div[data-role='popup']").popup('close')
    setTimeout (->
      switch (deviceTypeStep)
        when 0
          handleYesNo(yesNoAnswer, 10)
        when 10
          if $('#getNameVal').val() == ''
            gotoStep(deviceTypeStep)
          else
            deviceType['name'] = $('#getNameVal').val()
            gotoStep(40)
        when 20
          deviceType['isHub'] = (yesNoAnswer == 'yes')
          handleYesNo(yesNoAnswer, 30, 50)
        when 30, 50
          handleYesNo(yesNoAnswer, 100, 3005)
        when 40
          deviceType['category'] = $('#getNameVal').val()
          gotoStep(20)
        when 100
          modes = null
          handleYesNo(yesNoAnswer, 110, 1000)
        when 110, 150
          if $('#getNameVal').val() == ''
            gotoStep(deviceTypeStep)
          else
            modes = {}
            modeName = $('#getNameVal').val()
            modes[modeName] = []
            gotoStep(120)
        when 120
          if $('#getNameVal').val() == ''
            gotoStep(deviceTypeStep)
          else
            modes[modeName].push($('#getNameVal').val())
            gotoStep(130)
        when 130
          handleYesNo(yesNoAnswer, 120, 140)
        when 140
          handleYesNo(yesNoAnswer, 150, 1000)
        when 1000
          if $('#getNameVal').val() == ''
            gotoStep(deviceTypeStep)
          else
            eventCommandName = $('#getNameVal').val()
            currentActionType = { name: eventCommandName, guess: false, isTrigger: false }
            if modes
              gotoStep(1020)
            else
              gotoStep(1120)
        when 1020
          if modes
            $.each(modes, (modeName, modeValues) ->
              $.each(modeValues, (index, modeVal) ->
                if $('#checkbox-' + modeName + modeVal).prop('checked')
                  if (!currentActionType['modes'])
                    currentActionType['modes'] = {}
                  if (!currentActionType['modes'][modeName])
                    currentActionType['modes'][modeName] = []
                  currentActionType['modes'][modeName].push(modeVal)
              )
            )
          gotoStep(1120)
        when 1030
          handleYesNo(yesNoAnswer, 1100, 2010)
        when 1100, 1101, 1102, 1103
          addNumProp(currentActionType)
          gotoStep(deviceTypeStep + 1)
        when 1110
          currentActionType['receive'] = (yesNoAnswer == 'yes')
          handleYesNo(yesNoAnswer, 1130, 2000)
        when 1120
          currentActionType['isSetting'] = (yesNoAnswer == 'no')
          gotoStep(1030)
        when 1130, 2110
          currentActionType['learn'] = (yesNoAnswer == 'yes')
          handleYesNo(yesNoAnswer, deviceTypeStep + 10, if deviceTypeStep == 1130 then 2000 else 2040)
        when 1140, 2120
          currentActionType['guess'] = (yesNoAnswer == 'yes')
          gotoStep(if deviceTypeStep == 1140 then 2000 else 2040)
        when 2000
          handleYesNo(yesNoAnswer, 2010, 3000)
        when 2010
          addProp(currentActionType)
          gotoStep(2020)
        when 2020
          addProp(currentActionType)
          if !currentActionType.hasOwnProperty('receive')
            gotoStep(2030)
          else if currentActionType['receive'] && !currentActionType['isSetting'] && !currentActionType.hasOwnProperty('learn')
            gotoStep(2110)
          else
            gotoStep(2040)
        when 2030 
          currentActionType['receive'] = (yesNoAnswer == 'yes')
          if currentActionType['receive'] && !currentActionType['isSetting'] && !currentActionType.hasOwnProperty('learn')
            gotoStep(2110)
          else
            gotoStep(2040)
        when 2040
          handleYesNo(yesNoAnswer, 2050, 3000)
        when 2050
          currentActionType['isTrigger'] = (yesNoAnswer == 'yes')
          handleYesNo(yesNoAnswer, 2060, 3000)
        when 2060
          currentActionType['isWakeUpOnly'] = (yesNoAnswer == 'yes')
          gotoStep(3000)
        when 3000
          actionTypes.push(currentActionType)
          handleYesNo(yesNoAnswer, 1000, 3005)
        when 3005
          deviceType['useLinkCode'] = (yesNoAnswer == 'yes')
          handleYesNo(yesNoAnswer, 3020, 3010)
        when 3010, 3020
          if !($('#getInstructionsVal').val() == '') && !($('#getInstructionsVal').attr('data-propName') == '')
            deviceType[$('#getInstructionsVal').attr('data-propName')] = $('#getInstructionsVal').val()
          gotoStep(deviceTypeStep + 10)
        when 3030
          handleYesNo(yesNoAnswer, 3040, 4000)
        when 3040
          if $('#getNameVal').val() == ''
            gotoStep(deviceTypeStep)
          else
            newAttrName = $('#getNameVal').val()
            gotoStep(3050)
        when 3050
          addProp(deviceType)
          gotoStep(3060)
        when 3060
          handleYesNo(yesNoAnswer, 3040, 4000)
    ), 100
  
  gotoPrevStep = () ->
    $("div[data-role='popup']").popup('close')
    setTimeout (->
      switch (deviceTypeStep)
        when 10, 120, 130, 140, 1000, 1030, 1100, 2000, 2040, 3000, 3040
          gotoStep(deviceTypeStep)
        when 100
          gotoStep(20)
        when 1020
          gotoStep(1000)
        when 1100
          gotoStep(1030)
        when 1101, 1102, 1103, 1104
          gotoStep(deviceTypeStep - 1)
        else
          gotoStep(deviceTypeStep - 10)
    ), 100

  $('.newDeviceType').click ->
    deviceType = {}
    actionTypes = []
    modes = null
    gotoStep(10)

  $('.prevButton').click ->
    gotoPrevStep()

  $('.getNameForm').submit (event) ->
    event.preventDefault()
    handleDeviceTypeWizardStep() 

  $('.getInstructionsForm').submit (event) ->
    event.preventDefault()
    handleDeviceTypeWizardStep() 

  $('.selectModesForm').submit (event) ->
    event.preventDefault()
    handleDeviceTypeWizardStep() 

  $('.cancelButton').click ->
    if deviceTypeStep < 100 && !singleActionAdd
      confirmDialog('Confirm', 'Cancel creating new device type?'
        ->
          $.mobile.loading('show')
          setTimeout (->
            window.location.reload()
          ), 100
        ->
          return false
      )
    else
      $("div[data-role='popup']").popup('close')

  $('.actionTypeCancelButton').click ->
    if $('#actionTypeInfo').attr('data-edited') == 'true'
      confirmDialog('Confirm', 'Save changes?'
        ->
          rangePrecision = 1
          if $('#attr-rangePrecision').val() && parseFloat($('#attr-rangePrecision').val()) != 0
            rangePrecision = parseFloat($('#attr-rangePrecision').val()) * 10

# this needs work - checkboxes are not being saved correctly, nor are modes for individual actions...
          $('.actionTypeAttr').each( ->
            if $(this).is('input:text') 
              if $(this).attr('id') == 'attr-rangeLow' || $(this).attr('id') == 'attr-rangeHigh' || $(this).attr('id') == 'attr-rangeStep'
                if $(this).val() && !isNaN($(this).val()) && $(this).val() != '' && rangePrecision != 0
#                  currentActionType[$(this).attr('name').substring(5)] = (parseFloat($(this).val()) * rangePrecision).toString()
                  currentActionType[$(this).attr('name').substring(5)] = (parseFloat($(this).val()) * rangePrecision)
              else
                currentActionType[$(this).attr('name').substring(5)] = $(this).val()
            else if $(this).is('input:checkbox')
              currentActionType[$(this).attr('name').substring(5)] = $(this).prop('checked')
#              currentActionType[$(this).attr('name').substring(5)] = $(this).prop('checked').toString()
          )
          currentActionType['rangePrecision'] = (if rangePrecision != 0 && rangePrecision != 1 then rangePrecision else undefined)

          saveAsDraft()
        ->
          confirmDialog('Confirm', 'Discard changes?'
            ->
              $("div[data-role='popup']").popup('close')
              return false
            ->
              return false
          )
      )
    else
      $("div[data-role='popup']").popup('close')
      return false

  $('.actionTypeAttr').change ->
    $('#actionTypeInfo').attr('data-edited', 'true')

  getDeviceTypeInfo = (cb) ->
    if getCookie('deviceTypeUuid')
      path = 'deviceTypes/' + getCookie('deviceTypeUuid')
    else
      path = 'deviceTypes/' + getCookie('deviceTypeDraftId') + '/draft'

    $.mobile.loading('show')
    $.taGet path, (response) ->
      $.mobile.loading('hide')
      deviceType = response
      cb()

  $('.actionTypePopup').click ->
    $("div[data-role='popup']").popup('close')
    actionTypeName = $(this).attr('data-actionTypeName')
    getDeviceTypeInfo( () ->
      if deviceType['deviceTypeUuid']
        $('.popupTitle').text('Action Type (read only)')
        $('.actionTypeAttr').attr('disabled', true).trigger('refresh')
      else
        $('.popupTitle').text('Action Type')
        $('.actionTypeAttr').attr('disabled', false).trigger('refresh')

      $.each(deviceType['actionTypes'], (index, atValue) ->
        if atValue['name'] == actionTypeName
          currentActionType = atValue
          rangePrecision = parseInt(currentActionType['rangePrecision']) * 10
          if !rangePrecision
            rangePrecision = 1
          $.each(atValue, (key, val) ->
            el = $('#attr-' + key)
            if el.is('input:text')
              if val && rangePrecision != 0 && (key == 'rangeLow' || key == 'rangeHigh' || key == 'rangeStep')
                val = parseInt(val)
                if (rangePrecision != 0)
                  val = val / rangePrecision
              else if key == 'modes'
                val = JSON.stringify(val)
              el.val(val).trigger('refresh')
            else if el.is('input:checkbox')
              el.prop('checked', (val.toString() == 'true')).checkboxradio('refresh')
          )
      )
    )

    setTimeout (->
      $('#viewActionTypePopupDialog').popup('open')
    ),100

  $('#deleteActionType').click ->
    getDeviceTypeInfo( () ->
      confirmDialog('Confirm', 'Delete action type "' + $('#attr-name').val() + '"?'
        ->
          actionTypes = []
          
          $.each(deviceType['actionTypes'], (index, atValue) ->
            if atValue['name'] != $('#attr-name').val()
              actionTypes.push(atValue)
          )
          deviceType['actionTypes'] = actionTypes
          saveAsDraft()
        ->
          return false
      )
    )

  $('#addDeviceTypeAttribute').click ->
    getDeviceTypeInfo( () ->
      $('#deviceTypeElements').attr('data-edited', 'true')
      gotoStep(3040)
    )

  $('#addDeviceTypeAction').click ->
    getDeviceTypeInfo( () ->
      actionTypes = deviceType['actionTypes']
      modes = deviceType['modes']
      if !actionTypes
        actionTypes = []
      $('#deviceTypeElements').attr('data-edited', 'true')
      singleActionAdd = true
      gotoStep(1000)
    )

  saveAsDraft = () ->
    $.taPost 'deviceTypes/draft', deviceType, (response) ->
      if response['draftId']
        window.location.href = '/deviceTypes/edit?deviceTypeDraftId=' + response['draftId'].toString()
      else
        window.location.href = '/deviceTypes/edit'
      return true

  updateDtSearch = () ->
    if $('#dtSearchText').val() == ''
      window.location.href = '/devicetypes?showAll=true'
    else
      window.location.href = '/devicetypes?filter=' + fixedEncodeURI($('#dtSearchText').val())
    return true

  dtSearchTextBlur = false

  $('.dtButton').click (event) ->
    $.mobile.loading('show')
    if $(this).attr('data-deviceTypeUuid')
      window.location.href = '/deviceTypes/edit?deviceTypeUuid=' + $(this).attr('data-deviceTypeUuid')
    else if $(this).attr('data-deviceTypeDraftId')
      window.location.href = '/deviceTypes/edit?deviceTypeDraftId=' + $(this).attr('data-deviceTypeDraftId')
    return true

  $('#dtSearchText').change ->
    dtSearchTextBlur = true

  $('#dtSearchText').blur ->
    if dtSearchTextBlur
      updateDtSearch()

  $('.deviceTypeField').change ->
    if $(this).attr('data-propName') != 'deviceTypeUuid'
      $('#deviceTypeElements').attr('data-edited', 'true')

  $('.deviceTypeEditorBack').click ->
    if $('#deviceTypeElements').attr('data-edited') == 'true'
      confirmDialog('Confirm', 'Discard changes?'
        ->
          $.mobile.loading('show')
          setTimeout (->
            window.location.href = '/devicetypes'
            return true
          ), 100
        ->
          return false
      )
    else
      window.location.href = '/devicetypes'
      return true

  loadDeviceTypeWithChanges = (cb) ->
    getDeviceTypeInfo( () ->
      $('.deviceTypeField').each( ->
        if $(this).is('input:text') || $(this).is('textarea')
          deviceType[$(this).attr('data-propName')] = $(this).val()
        else if $(this).is('input:checkbox')
          deviceType[$(this).attr('data-propName')] = $(this).prop('checked')
#          deviceType[$(this).attr('data-propName')] = $(this).prop('checked').toString()
      )
      cb()
    )

  $('#editDeviceTypeSaveDraft').click ->
    loadDeviceTypeWithChanges( () ->
      if deviceType['deviceTypeUuid']
        confirmDialog('New Device Type', 'Treat as new device type?'
          ->
            deviceType['deviceTypeUuid'] = undefined
            deviceType['ownerUserName'] = undefined
            deviceType['ownerUserId'] = undefined
            deviceType['created'] = undefined
            deviceType['name'] = deviceType['name'] + ' (copy)'
            saveAsDraft()
          ->
            saveAsDraft()
        )
      else
        saveAsDraft()
    )

  registerDeviceType = () ->
    path = 'deviceTypes'
    if deviceType['deviceTypeUuid'] && deviceType['deviceTypeUuid'] != ''
      path = 'deviceTypes/' + deviceType['deviceTypeUuid']

    $.mobile.loading('show')
    $.taPost path, deviceType, (response) ->
      if isValid(response['error'] && response['error']['message'])
        $.mobile.loading('hide')
        alertDialog('Error', response['error']['message'])
        return false
      else
        window.location.href = '/devicetypes'
        return true


  $('#editDeviceTypeRegister').click ->
    loadDeviceTypeWithChanges( () ->
      if !deviceType['actionTypes'] || deviceType['actionTypes'] == null
        deviceType['actionTypes'] = []

      if deviceType['deviceTypeUuid']
        confirmDialog('Confirm', 'Re-register device type with changes?'
          ->
            return registerDeviceType()
          ->
            return false
        )
      else
        confirmDialog('Confirm', 'Register device type? Action types cannot be changed for this device type after registration.'
          ->
            if !deviceType['published'] || deviceType['published'] == 'false'
              confirmDialog('Confirm', 'Would you like the new device type to be discoverable (a.k.a. published)? Can be changed later.'
                ->
                  deviceType['published'] = true
                  return registerDeviceType()
                ->
                  return registerDeviceType()
              )
            else
              return registerDeviceType()
          ->
            return false
        )
    )

  $('#deleteDeviceTypeSubmit').click ->
    getDeviceTypeInfo( () ->
      if deviceType['draftId']
        prompt = 'Delete "' + deviceType['name'] + '" draft type?'
      else
        prompt = 'Delete "' + deviceType['name'] + '" type? If device type already in use, consider deprecating instead.'
      confirmDialog('Confirm', prompt
        ->
          $.mobile.loading('show')
          if deviceType['deviceTypeUuid']
            $.taDelete 'deviceTypes/' + deviceType['deviceTypeUuid'] + '/draft',  (response) ->
              window.location.href = '/devicetypes'
              return true
          else if deviceType['draftId']
            $.taDelete 'deviceTypes/' + deviceType['draftId'] + '/draft',  (response) ->
              window.location.href = '/devicetypes'
              return true
          else
            window.location.href = '/deviceTypes/edit'
            return true
        ->
          return false
      )
    )

