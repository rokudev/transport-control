' ********** Copyright 2016-2019 Roku Corp.  All Rights Reserved. **********

Function init()
    'set video node'
    m.ExtVideo = m.top
    m.video=m.top.findnode("video")
    m.top.observeField("state", "handleStateChange")
    m.top.observeField("bufferingStatus", "handleBufferingStatus")
    'init roAppManager Thread for NowPlaying response'
    m.appmanager=createobject("roSGNode","appman")
    m.appmanager.control="RUN"
    
    initProgressBar()
    initThumbnails()  ' hostPrefix and trickInterval are passed in from interface fields'
    initLoadingBar()

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
end Function

Function handleStateChange(msg)
  if type(msg) = "roSGNodeEvent" and msg.getField() = "state"
      ' This is to take in the video node thumbnails and content duration
      ' Is there a better way? '
      state = msg.getData()
      if m.ExtVideo.thumbnailHostPrefix <> ""
          m.hostPrefix = m.ExtVideo.thumbnailHostPrefix
          m.trickInterval = m.ExtVideo.thumbnailIntervalInSecs
      else
          m.hostPrefix = invalid
          m.trickInterval = 5
      end if
      m.videoDuration = m.top.duration
  end if
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
  hoursText = formatNumberString( Fix(timeInSeconds / 3600) )
  minutesText = formatNumberString( Fix(timeInSeconds / 60) )
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
    leftPositionSeconds = position * 100 / 100
    rightPositionSeconds = m.videoDuration - leftPositionSeconds
    m.leftProgressLabel.text = setTimeText(leftPositionSeconds)
    m.rightProgressLabel.text = setTimeText(rightPositionSeconds)
    setProgressMode()
end Function

Function hideProgressBar()
    m.progress.visible = false
end Function

Function setProgressMode()
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
  m.ExtVideo.control = "stop"
  m.ExtVideo.control = "play"
  'm.trickPosition -= 1
  'm.trickplayDirection = "paused"
  seekPosition = Cdbl(m.trickPosition * m.trickInterval)
  m.ExtVideo.seek = seekPosition

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
      hideLoadingBar()
      hideProgressBar()
      hideThumbnails()
    end if
  end if
end Function

Function handleTransport(evt as object) as String

  print "command is ";evt.command
  cmd = evt.command
  ret = "unhandled"
  if m.extvideo.state="none" then
    ret="error.generic"
  end if
  if validateTransportControl(evt) and m.ExtVideo.visible = true
    ret = "success"
    cmd = evt.command
    ' If status in transportControl is "unhandled", the firmware handles the command if
    ' a default behavior is available'
    ' in this channel, resume, forward, rewind, and replay uses default behavior'
    if cmd = "startover"
        m.ExtVideo.seek = 0
        'm.ExtVideo.control = "play"
        if isSeeking()
            showLoadingBar()
            endSeeking()
        else
            hideProgressBar()
        end if
    else if cmd = "seek"
        if m.lastCmd = "forward" or m.lastCmd = "rewind" ' only allow seeking when not fast forwarding or rewinding
            ret = "error"
        else
            duration = evt.duration.ToInt()
            seekPosition = m.ExtVideo.position
            if (evt.direction = "backward") then
                seekPosition = m.ExtVideo.position - duration
            else
                seekPosition = m.ExtVideo.position + duration
            end if
            if (seekPosition > m.ExtVideo.duration) then
                ret = "success.seek-end"
                seekPosition = m.ExtVideo.duration - 30
            else if (seekPosition < 0) then
                ret = "success.seek-start"
                seekPosition = 0
            end if
            m.ExtVideo.seek = seekPosition
            if isSeeking() and m.ExtVideo.state <> "paused"
                showLoadingBar()
                endSeeking()
            else
                hideProgressBar()
            end if
        end if
    else if (cmd = "rewind" and m.lastCmd = "forward") or (cmd = "forward" and m.lastCmd = "rewind") ' if user says rewind while fast forwarding, rewind rather than pausing (default behavior) and vice versa
        if not isSeeking()
          position = m.ExtVideo.position
        else
          position = m.trickPosition * m.trickInterval
          if cmd = "rewind" then position -= m.trickInterval
        end if
        m.trickplayDirection = "paused"
        m.ExtVideo.control = "pause"
        if position < m.videoDuration ' block additional fast forwards from going off the progress bar
            showProgressBar(position)
            startSeeking(cmd)
            showThumbnails(position)
        end if
    else if (cmd = "pause" or cmd = "stop") and (m.lastCmd = "forward" or m.lastCmd = "rewind") ' handle pause in cases where the user is moving but position isn't being updated
        resetSeekLogic()
        m.ExtVideo.control = "pause"
        position = m.trickPosition * m.trickInterval
        pauseSeeking("pause", position)
        showProgressBar(position)
        setProgressMode()
    else if cmd = "pause" or cmd = "stop"
        if (m.ExtVideo.state = "paused")
          ret = "error.redundant"
        else
          if isSeeking()
              position = m.trickPosition * m.trickInterval
              pauseSeeking("pause", position)
          else
              position = m.ExtVideo.position
          end if
          showProgressBar(position)
          m.ExtVideo.control = "pause"
        end if
    else if cmd = "play" or cmd = "resume"
        if m.ExtVideo.state <> "playing"
            if isSeeking()
                showLoadingBar()
                endSeeking()
            else
                m.ExtVideo.control = "resume"
                hideProgressBar()
            end if
        else
            ret = "error.redundant"
        end if
    else if cmd = "next"
        ' skip to next content in playlist'
        m.ExtVideo.control = "skipcontent"
    else if cmd = "nowplaying"
        parent=m.top.getparent()
        vid_metadata=m.top.content.getchild(m.top.contentindex)
        vidtitle=vid_metadata.title
        'prepend "Sample" to string top demonstrate client control of Now Playing response'
        nowplaying={ContentType:"episode",contentTitle:"Sample, "+vidtitle}
        m.appmanager.setfield("Title",nowplaying)
        ret = "success"
    else
        ret = "unhandled"
    end if
  else
    ret = "error.generic"
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
      if key = "fastforward" or key = "forward" or key = "rewind"
        if not isSeeking()
          position = m.ExtVideo.position
        else
          position = m.trickPosition * m.trickInterval
          if key = "rewind" then position -= m.trickInterval
        end if

        m.ExtVideo.control = "pause"

        if position < m.videoDuration ' block additional fast forwards from going off the progress bar
            showProgressBar(position)
            startSeeking(key)
            showThumbnails(position)
        end if

      else if key = "left" or key = "right"
        if not isSeeking()
          position = m.ExtVideo.position
        else
          position = m.trickPosition * m.trickInterval
        end if
        pauseSeeking(key, position)
      else if key = "play" or key = "OK"
          if m.ExtVideo.state = "playing"
              m.initPos = m.ExtVideo.position
              showProgressBar(m.ExtVideo.position)
              m.ExtVideo.control = "pause"
          else
              if isSeeking()
                  showLoadingBar()
                  endSeeking()
              else
                  m.ExtVideo.control = "resume"
                  hideProgressBar()
                  hideThumbnails()
              end if
          end if
      else if key = "back"
          return false
      end if
    end if

	return true
end Function

function stop_appmgr()
PRINT "APP MANAGER STOP"
m.top.appmanager.control="STOP"
end function
