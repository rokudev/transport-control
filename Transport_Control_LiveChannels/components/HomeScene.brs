
' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

Sub init()
    m.count = 0
    m.AdTimer = m.top.findNode("AdTimer")
    m.Video = m.top.findNode("Video")
    m.RowList = m.top.findNode("RowList")
    m.BottomBar = m.top.findNode("BottomBar")
    m.ShowBar = m.top.findNode("ShowBar")
    m.HideBar = m.top.findNode("HideBar")
    m.Hint = m.top.findNode("Hint")
    m.Timer = m.top.findNode("Timer")

    m.Hint.font.size = "20"
    showHint()

    m.array = loadConfig()
    if m.array.count() = 1
        m.BottomBar.visible = false
        m.Video.setFocus(true)
    end if

    m.Video.enableUI = false  ' enable media player custom UI'
    m.Video.content = invalid
    m.Video.observeField("state", "onVideoStateChanged")
    m.video.loop = true

    m.AdTimer.control = "start"

    m.LoadTask = createObject("roSGNode", "RowListContentTask")
    m.LoadTask.observeField("content", "rowListContentChanged")
    m.LoadTask.control = "RUN"

    m.global.Options = 0
    optionsMenu()

    m.RowList.rowLabelFont.size = "24"

    m.Timer.observeField("fire", "hideHint")

    m.AdTimer.observeField("fire", "change")
    m.RowList.observeField("rowItemSelected", "ChannelChange")

    'transport control implementation
    m.InputTask = createObject("roSgNode","input_task")
    m.InputTask.observefield("inputData","handleInputEvent")
    m.InputTask.control = "RUN"
    ' m.trickInterval = 5
    ' m.trickPosition = 0
End Sub

Sub playVideo(url = invalid)
    ? "url= "; url
    if type(url) = "roSGNodeEvent"   ' passed from observe callback'
        m.videoContent.url = m.RowList.content.getChild(m.RowList.rowItemFocused[0]).getChild(m.RowList.rowItemFocused[1]).URL
        'rowItemFocused[0] is the row and rowItemFocused[1] is the item index in the row
    else
        m.videoContent.url = url
    end if

    m.videoContent.streamFormat = "mp4"
    keepPlaying = false

    m.Video.content = m.videoContent
    m.Video.visible = "true"
    m.Video.control = "play"

    m.Video.setFocus(true)

    m.vector2danimation = m.top.FindNode("moveOverhangPanelUp")
    m.vector2danimation.repeat = false
    m.vector2danimation.control = "start"
End Sub

Sub change()
    m.global.Adtracker = 0
End Sub

Sub  hideHint()
    m.Hint.visible = false
End Sub

Sub showHint()
    m.Hint.visible = true
    m.Timer.control = "start"
End Sub

Sub optionsMenu()
    if m.global.Options = 0
        m.ShowBar.control = "start"
        m.RowList.setFocus(true)
        hideHint()
    else
        m.HideBar.control = "start"
        m.Video.setFocus(true)
        showHint()
    End if
End Sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    handled = false
        if press
           if key = "down"
               if m.global.Options = 0
                    m.global.Options = 1
                    optionsMenu()
               else
                    m.global.Options = 0
                    optionsMenu()
               end if
               handled = true
           end if
        end if
    return handled
end function

Function ChannelChange()
    m.global.AdTracker = 0
    'prevent the same channel from being selected again
    if m.Video.content.TITLE <> m.RowList.content.getChild(m.RowList.rowItemFocused[0]).getChild(m.RowList.rowItemFocused[1]).title
        m.top.isChannelChange = true
        m.Video.content = m.RowList.content.getChild(m.RowList.rowItemFocused[0]).getChild(m.RowList.rowItemFocused[1])
        m.Video.content.live = m.isVideoLive[m.Video.content.title]
        if m.Video.content.live then 'if video is live then play from the end
            m.Video.content.PlayStart = m.global.maxInt
        else 'play from the beginning
            m.Video.content.PlayStart = 0
        end if
        m.Video.control = "play"
      else 'if attempting to change to the same channel
        m.top.isChannelChange = false
    end if
    'hide the bar and focus on video
    m.Video.setFocus(true)
    m.global.Options = 1
    m.HideBar.control = "start"
End Function

Sub rowListContentChanged()
    m.RowList.content = m.LoadTask.content
    m.top.allowSeek = m.LoadTask.seekType
    m.isVideoLive = m.LoadTask.isLive

    if m.count = 0
        m.Video.content = m.RowList.content.getChild(0).getChild(0)
        ? m.Video.Content.title
        m.Video.content.live = m.isVideoLive[m.Video.content.title]
        if m.Video.content.live then 'if video is live then play from the end
            m.Video.content.PlayStart = m.global.maxInt
        else 'play from the beginning
            m.Video.content.PlayStart = 0
        end if
        m.Video.control = "play"
        m.count = 1
    end if
End Sub

Function returnToUIPage()
    m.Video.visible = "false" 'Hide video
    m.Video.control = "stop"  'Stop video from playing
    m.RowList.setFocus(true)
end Function

Function onVideoStateChanged(msg as Object)
  if type(msg) = "roSGNodeEvent" and msg.getField() = "state"
      state = msg.getData()
      if state = "finished"
          returnToUIPage()
      end if
      m.lastState = state
  end if
end Function

Function handleDeepLink(deeplink as object)
  if validateDeepLink(deeplink)
    playVideo(m.mediaIndex[deeplink.id].url)
  else
    print "deeplink not validated"
  end if
end Function

sub handleInputEvent(msg)
    if type(msg) = "roSGNodeEvent" and msg.getField() = "inputData"
        inputData = msg.getData()
        if inputData <> invalid
          if inputData.type = "deeplink"
            handleDeepLink(inputData)
          end if
        end if
    end if
end sub

function validateDeepLink(deeplink as Object) as Boolean
  mediatypes={movie:"movie",episode:"episode",season:"season",series:"series"}
  if deeplink <> Invalid
      ? "mediaType = "; deeplink.mediaType
      ? "contentId = "; deeplink.id
      ? "content= "; m.mediaIndex[deeplink.id]
      if deeplink.mediaType <> invalid then
        if mediatypes[deeplink.mediaType]<> invalid
          if m.mediaIndex[deeplink.id] <> invalid
            if m.mediaIndex[deeplink.id].url <> invalid
              return true
            else
                print "invalid deep link url"
            end if
          else
            print "bad deep link contentId"
          end if
        else
          print "unknown media type"
        end if
      else
        print "deeplink.type string is invalid"
      end if
  end if
  return false
end function
