' ********** Copyright 2016-2019 Roku Corp.  All Rights Reserved. **********

Function init()
    'set video node'
    m.customVid = m.top
    m.top.observeField("state", "handleStateChange")
    m.top.observeField("bufferingStatus", "handleBufferingStatus")
    m.timeWaited = 0

    initProgressBar()
    initThumbnails()  ' hostPefix and trickInterval are passed in from interface fields'

    initLoadingBar()

    m.finishLoading = false
end Function

' *** Progress Bar Section *** '
Function initProgressBar()

  'progress bar nodes'
  m.progress = m.top.findNode("progress")
  m.progress.visible = false

  m.progressWidth = m.top.findNode("outlineRect").width
  m.progressRect = m.top.findNode("progressRect")
  m.leftProgressLabel = m.top.findNode("leftProgressLabel")
  m.rightProgressLabel = m.top.findNode("rightProgressLabel")
  m.progressMode = m.top.findNode("progressMode")

  m.progressModeBackground = m.top.findNode("progressModeBackground")
end Function

Function handleStateChange(msg)
  if type(msg) = "roSGNodeEvent" and msg.getField() = "state"
      ' This is to take in the video node thumbnails and content duration
      state = msg.getData()
      if m.customVid.thumbnailHostPrefix <> ""
          m.hostPrefix = m.customVid.thumbnailHostPrefix
          m.trickInterval = m.customVid.thumbnailIntervalInSecs
      else
          m.hostPrefix = invalid
          m.trickInterval = 5
      end if
      m.videoDuration = m.top.duration

      seekRestrict = m.top.getScene().allowSeek[m.customVid.content.TITLE]
      if not seekRestrict and m.finishLoading'if channel supports video fastforward and rewind
          if m.resumeTime <> invalid and state = "playing" 'resume from saved pos
              m.customVid.seek = m.resumeTime
              resetSeekLogic()
              setProgressModePlay()
              m.resumeTime = invalid
          end if
      end if
  end if
  m.finishLoading = false
end Function

Function formatNumberString(number as Integer) as String
  numberText = number.toStr()
  if number <= 0
    numberText = "00"   ' min number is 0'
  else if number < 10
    numberText = "0" + numberText
  else if number > 99
    numberText = "99"   ' max number - saturates at 99'
  end if
  return numberText
end Function

Function setTimeText(timeInSeconds) as String
  hoursText   = formatNumberString( Fix(timeInSeconds / 3600) )
  minutesText = formatNumberString( Fix(timeInSeconds / 60 MOD 60) )
  secondsText = formatNumberString( Fix(timeInSeconds MOD 60) )

  timeText = minutesText + ":" + secondsText
  if hoursText <> "00"
    timeText = hoursText + ":" + timeText
  end if

  return timeText
end Function

Function showProgressBar(position)
    m.progress.visible = true
    m.progressRect.width = position * m.progressWidth / m.videoDuration

    if position >= m.videoDuration
      m.progressRect.width = m.progressWidth
    end if
    leftPositionSeconds = position
    rightPositionSeconds = m.videoDuration - leftPositionSeconds
    m.leftProgressLabel.text = setTimeText(leftPositionSeconds)
    if m.customVid.content.live then
        m.rightProgressLabel.text = "LIVE"
    else 
        m.rightProgressLabel.text = setTimeText(rightPositionSeconds)
    end if
    setProgressMode()
end Function

Function hideProgressBar()
    m.progress.visible = false
end Function

Function setProgressMode()
  m.progressModeBackground.visible = true
  if m.trickPlaySpeed = 0
    m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_PAUSE_HD.png"
  else if m.trickplayDirection = "forward"
    if m.trickplaySpeed = 1
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_FWDx1_HD.png"
    else if m.trickplaySpeed = 2
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_FWDx2_HD.png"
    else
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_FWDx3_HD.png"
    end if
  else if m.trickplayDirection = "reverse"
    if m.trickplaySpeed = 1
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_REWx1_HD.png"
    else if m.trickplaySpeed = 2
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_REWx2_HD.png"
    else
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_REWx3_HD.png"
    end if
  end if
end Function

Function setProgressModePlay()
  m.progressModeBackground.visible = true
  m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_PLAY_HD.png"
end Function

' *** Thumbnails Section *** '
Function initThumbnails()
  ' thumbnails nodes'
  m.thumbnails = m.top.findNode("thumbnails")
  m.thumbnails.visible = false

  ' set some default values'
  'm.hostPrefix = invalid
  m.trickInterval = 5
  m.trickPosition = 0

  m.trickPlayTimer = createObject("roSGNode", "Timer")
  m.trickPlayTimer.duration = 1
  m.trickPlayTimer.repeat = True
  m.trickPlayTimer.observeField("fire", "handleTrickPlayTimer")

  'array with thumbnails'
  poster0 = m.top.findNode("poster_thumb_minus2")
  poster1 = m.top.findNode("poster_thumb_minus1")
  poster2 = m.top.findNode("poster_thumb_center")
  poster3 = m.top.findNode("poster_thumb_plus1")
  poster4 = m.top.findNode("poster_thumb_plus2")
  m.arrayPosters = []
  m.arrayPosters.push(poster0)
  m.arrayPosters.push(poster1)
  m.arrayPosters.push(poster2)
  m.arrayPosters.push(poster3)
  m.arrayPosters.push(poster4)
  resetSeekLogic()
end Function

Function resetSeekLogic()
  m.trickplayDirection = "paused"
  m.trickPlaySpeed = 0
  m.trickPlayTimer.duration = 1
end Function

Function isSeeking() as boolean
  return m.trickplayDirection <> "paused"
end Function

Function startSeeking(key)  ' key is either "fastforward" or "rewind"
  if m.trickplayDirection = "paused"
      m.trickplaySpeed = 1
      m.trickPlayTimer.duration = 1 / m.trickPlaySpeed
      ' set the trickplay direction'
      if key = "fastforward" or key = "forward"
        m.trickplayDirection = "forward"
      else
        m.trickplayDirection = "reverse"
      end if

      m.trickPlayTimer.control = "START"
  else if key = "fastforward" and m.trickplayDirection <> "forward" or key = "rewind" and m.trickplayDirection <> "reverse"
      pauseSeeking(key, m.trickPosition * m.trickInterval)
  else
      ' set the trick play speed'
      m.trickPlaySpeed += 1
      if m.trickPlaySpeed > 3 ' saturate trickplay speed at 3x'
          m.trickPlaySpeed = 1
      end if
      m.trickPlayTimer.control = "STOP"
      m.trickPlayTimer.duration = 1 / m.trickPlaySpeed
      m.trickPlayTimer.control = "START"
  end if
  print "trickPlaySpeed= "; m.trickPlaySpeed

end Function

Function pauseSeeking(key, position)  ' key is either "left" or "right"
  m.trickPlayTimer.control = "STOP"
  'm.trickPosition = Fix(position / 5) + 1
  m.trickPlaySpeed = 0
  if m.trickplayDirection = "paused"
    showThumbnails(position)
    if key = "right"
      m.trickplayDirection = "forward"
    else
      m.trickplayDirection = "reverse"
    end if
  else if key = "right" or key = "fastforward"    ' shift thumbnails to the left - forward
    if m.trickPosition < Fix((m.videoDuration / m.trickInterval) + 1)
        m.trickPosition += 1
        shiftThumbnailsLeft()
    end if
    m.trickplayDirection = "forward"
  else if key = "left" or key = "rewind"    ' shift thumbnails to the right - reverse
    if m.trickPosition > 0
        m.trickPosition -= 1
        shiftThumbnailsRight()
    end if
    m.trickplayDirection = "reverse"
  end if
  showProgressBar(position)
end Function

Function endSeeking()
  m.trickPlayTimer.control = "STOP"
  ' is there a better way to force seek position?'
  m.customVid.control = "pause"
  m.customVid.control = "play"
  'm.trickPosition -= 1
  'm.trickplayDirection = "paused"

  seekPosition = Cdbl(m.trickPosition * m.trickInterval)
  'if channel can fastforward and rewind and ff/rw was just called
  if not m.top.getScene().allowSeek[m.customVid.content.TITLE] and wasLastCmdFFRW()
      'calculate the new position relative to the pre buffered video
      seekDiff = m.customVid.position - seekPosition
      newSeekPosition = m.resumeTime - seekDiff
      seekPosition = Cdbl(newSeekPosition)
      m.resumeTime = seekPosition
  end if

  m.customVid.seek = seekPosition

  resetSeekLogic()
  setProgressModePlay()
end Function

Function showThumbnails(position)
    m.trickPosition = Fix(position / 5) + 1
    ? "m.trickPosition= ", m.trickPosition

    if m.hostPrefix = invalid
      return 0
    end if

    m.thumbnails.visible = true

    ' calculate the start index, special handling if m.trickPosition < 3
    ' the arrayPosters have 5 slots, don't fill lower two slots at beginning of the stream
    startIndex = 0
    endIndex = 4
    if m.trickPosition < 3
      startIndexData = [3, 2, 1]
      startIndex = startIndexData[m.trickPosition]
    end if

    for i = startIndex to endIndex
      ' array index 2 is the current position (poster_thumb_center), other indexes are offset'
      position = (m.trickPosition + i - 2) * m.trickInterval
      m.arrayPosters[i].uri = m.hostPrefix + "thumb-" + (m.trickPosition + i - 2).toStr() + ".jpg"
      ? "show - poster i="; i; ", position="; position; ", uri="; m.arrayPosters[i].uri
    end for
end Function

Function hideThumbnails()
    m.thumbnails.visible = false
end Function

Function shiftThumbnailsLeft()    ' forward direction'
  if m.hostPrefix = invalid
    return 0
  end if

  m.arrayPosters[0].uri = m.arrayPosters[1].uri
  m.arrayPosters[1].uri = m.arrayPosters[2].uri
  m.arrayPosters[2].uri = m.arrayPosters[3].uri
  m.arrayPosters[3].uri = m.arrayPosters[4].uri
  if m.trickPosition < (m.videoDuration / m.trickInterval) - 2
      m.arrayPosters[4].uri = m.hostPrefix + "thumb-" + (m.trickPosition + 2).toStr() + ".jpg"
  else
      m.arrayPosters[4].uri = ""
  end if
  ''? "shift left - thumb 4 uri= "; m.arrayPosters[4].uri
end Function

Function shiftThumbnailsRight()   ' reverse direction'
  if m.hostPrefix = invalid
    return 0
  end if

  m.arrayPosters[4].uri = m.arrayPosters[3].uri
  m.arrayPosters[3].uri = m.arrayPosters[2].uri
  m.arrayPosters[2].uri = m.arrayPosters[1].uri
  m.arrayPosters[1].uri = m.arrayPosters[0].uri
  if m.trickPosition > 2
      m.arrayPosters[0].uri = m.hostPrefix + "thumb-" + (m.trickPosition - 2).toStr() + ".jpg"
  else
      m.arrayPosters[0].uri = ""
  end if
  ''? "shift right - thumb 0 uri= "; m.arrayPosters[0].uri
end Function

Function handleTrickPlayTimer() as Void
    'print "TrickPlayTimer fired"
    if m.trickplayDirection = "forward"
        if m.trickPosition * m.trickInterval + m.trickInterval >= m.videoDuration ' handle fast foward overflow
            shiftThumbnailsLeft()
            showProgressBar(m.videoDuration)
            pauseSeeking("right", m.videoDuration)
            return
        else if m.trickPosition < Fix((m.videoDuration / m.trickInterval) + 1)
            m.trickPosition += 1
            shiftThumbnailsLeft()
        end if
    else if m.trickplayDirection = "reverse"
        if m.trickPosition > 0
            m.trickPosition -= 1
            shiftThumbnailsRight()
        else
            pauseSeeking("left", 0)
        end if
    end if
    showProgressBar(m.trickPosition * m.trickInterval)
end Function

' *** Loading Bar Section *** '
Function initLoadingBar()
  m.loadingPercentage = 0
  m.loading = m.top.findNode("loading")
  m.loading.visible = false
  m.loadingWidth = m.top.findNode("loadOutlineRect").width
  m.loadingProgressRect = m.top.findNode("loadProgressRect")
end Function

Function showLoadingBar()
  m.loading.visible = true
  m.loadingProgressRect.width = m.loadingPercentage * m.loadingWidth / 100
end Function

Function hideLoadingBar()
  m.loading.visible = false
  m.loadingPercentage = 0
end Function

Function handleBufferingStatus(msg)
  bufferingStatus = msg.getData()
  if bufferingStatus <> invalid
    m.loadingPercentage = bufferingStatus.percentage
    print "buffering - percentage= "; m.loadingPercentage
    showLoadingBar()
    if m.loadingPercentage = 100
      m.finishLoading = true
      hideLoadingBar()
      hideProgressBar()
      hideThumbnails()
    end if
  end if
end Function

Function wasLastCmdFFRW() as Boolean
  if m.lastCmd = "forward" or m.lastCmd = "rewind"
    return true
  end if
  if m.lastKey = "forward" or m.lastKey = "rewind"
    return true
  end if
  if m.lastKey = "fastforward" or m.lastKey = "left" or m.lastKey = "right"
    return true
  end if

  return  false
end function

Function handleTransport(evt as object) as String
  ret = "unhandled"
  if m.customVid.state = "buffering" then return ret
  if validateTransportControl(evt) and m.customVid.visible = true
    ret = "success"
    cmd = evt.command
    seekRestrict = m.top.getScene().allowSeek[m.customVid.content.TITLE]
    ' If status in transportControl is "unhandled", the firmware handles the command if
    ' a default behavior is available'
    ' in this channel, resume, forward, rewind, and replay uses default behavior'
    if cmd = "startover"
        m.customVid.seek = 0
        'm.customVid.control = "play"
        if isSeeking()
            showLoadingBar()
            endSeeking()
        else
            hideProgressBar()
        end if
    else if cmd = "forward" or cmd = "rewind"
        if seekRestrict 'fastforward and rewind not supported for this channel
            ret = "error.live"
        else 'regular fastforward and rewind
            if not isSeeking()
                position = m.customVid.position
            else
                position = m.trickPosition * m.trickInterval
                if cmd = "rewind" then position -= m.trickInterval
            end if
            ' if user says rewind while fast forwarding, rewind rather than pausing (default behavior) and vice versa
            if (cmd = "rewind" and m.lastCmd = "forward") or (cmd = "forward" and m.lastCmd = "rewind")
                m.trickplayDirection = "paused"
            end if
            m.customVid.control = "pause"

            if position < m.videoDuration ' block additional fast forwards from going off the progress bar
                showProgressBar(position)
                startSeeking(cmd)
                showThumbnails(position)
            end if
        end if
    else if cmd = "seek"
        if m.lastCmd = "forward" or m.lastCmd = "rewind" ' only allow seeking when not fast forwarding or rewinding
            ret = "error"
        else if seekRestrict = false
            'm.customVid.control = "pause"
            duration = evt.duration.ToInt()
            seekPosition = m.customVid.position
            if (evt.direction = "backward") then
                seekPosition = m.customVid.position - duration
            else
                seekPosition = m.customVid.position + duration
            end if
            if (seekPosition > m.customVid.duration) then
                ret = "success.seek-end"
                seekPosition = m.customVid.duration - 30
            else if (seekPosition < 0) then
                ret = "success.seek-start"
                seekPosition = 0
            else
                seekPosition = seekPosition
            end if
            ? "handleTransport() seek position= "; seekPosition
            m.customVid.seek = seekPosition
            if isSeeking() and m.customVid.state <> "paused"
                ? "handleTransport() - isSeeking "
                showLoadingBar()
                endSeeking()
            else
                ? "handleTransport() - not isSeeking "
                hideProgressBar()
            end if
        else
            ret = "error.live"
        end if
    else if (cmd = "pause" or cmd = "stop") and (m.lastCmd = "forward" or m.lastCmd = "rewind") ' handle pause in cases where the user is moving but position isn't being updated
        resetSeekLogic()
        m.customVid.control = "pause"
        setProgressMode()
    else if cmd = "pause" or cmd = "stop"
        REM - TODO: BIF player behavior: OK key only works during trick play
        ? "Hit stop key in state: "; m.customVid.state
        if (m.customVid.state = "paused")
            ret = "error.redundant"
        else if isSeeking()
            position = m.trickPosition * m.trickInterval
            pauseSeeking("pause", position)
        else
            position = m.customVid.position
        end if

        if seekRestrict
            showProgressBar(m.videoDuration)
        else
            showProgressBar(position)
        end if
        m.customVid.control = "pause"
    else if cmd = "play" or cmd = "resume"
        ? "Hit play key in state: "; m.customVid.state
        if m.customVid.state <> "playing" 'if video is paused
            'save the current position relative to the new buffered time
            if(not seekRestrict) then m.resumeTime = m.customVid.position
            m.customVid.control = "resume"
            m.trickplayDirection = "playing"
            if isSeeking()
                showLoadingBar()
                endSeeking()
            else
                hideProgressBar()
            end if
        else
            ret = "error.redundant"
        end if
    else
        ret = "unhandled"
    end if
  else
    ret = "error.no-media"
  end if
  m.lastCmd = cmd
  return ret
end Function

function validateTransportControl(transport as Object) as Boolean
  return true
end function

Function onKeyEvent(key as String, press as Boolean) as Boolean  'Maps back button to leave video
    ? "playerUI - key="; key
    if press
    seekRestrict = m.top.getScene().allowSeek[m.customVid.content.TITLE]
      if key="up"
          'toggle the progress bar
          if m.progress.visible = true
              hideProgressBar()
          else
              if seekRestrict
                  showProgressBar(m.videoDuration)
              else
                  showProgressBar(m.customVid.position)
              end if
          end if
          'hide the progress mode on top of the progress bar
          m.progressModeBackground.visible = false
      else if key = "down"
          if m.global.Options = 0 'when channel menu is hidden
              m.global.Options = 1
              m.top.getScene().callFunc("optionsMenu")
          else 'when channel menu is open
              if m.progress.visible = true
                  hideProgressBar()
              end if
              m.global.Options = 0
              m.top.getScene().callFunc("optionsMenu")
          end if
          return true
      else if (key = "fastforward" or key = "forward" or key = "rewind") and m.customVid.state <> "buffering"
          if not seekRestrict
            if not isSeeking()
              position = m.customVid.position
            else
              position = m.trickPosition * m.trickInterval
              if key = "rewind" then position -= m.trickInterval
            end if

            m.customVid.control = "pause"

            if position < m.videoDuration ' block additional fast forwards from going off the progress bar
                showProgressBar(position)
                startSeeking(key)
                showThumbnails(position)
            end if
          end if
      else if key = "left" or key = "right"
        'when channel menu is closed and channel supports seek and video is not mid buffer
        if m.global.options = 1 and not seekRestrict and m.customVid.state <> "buffering"
            if not isSeeking()
              position = m.customVid.position
            else
              position = m.trickPosition * m.trickInterval
            end if
            ' pauseSeeking calls showProgressBar
            pauseSeeking(key, position)
        end if
      else if key = "play" or key = "OK"
          if m.global.Options = 1 and m.customVid.state <> "buffering"'only allow when menu is not open
              if m.customVid.state = "playing" 'PAUSE the content
                  REM - TODO: BIF player behavior: OK key only works during trick play
                  if seekRestrict
                      showProgressBar(m.videoDuration)
                  else
                      showProgressBar(m.customVid.position)
                  end if
                  m.customVid.control = "pause"
              else 'RESUME the content
                  'save the current position relative to the new buffered time
                  if(not seekRestrict) then m.resumeTime = m.customVid.position
                  m.customVid.control = "resume"
                  m.trickplayDirection = "playing"
                  if isSeeking()
                      showLoadingBar()
                      endSeeking()
                  else
                      hideProgressBar()
                  end if
              end if
          end if
      else if key = "back"
          return false
      end if
    end if
    m.lastKey = key
	return true
end Function
