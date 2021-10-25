Sub init()

    m.top.setFocus(true)

    'deeplink if it exists when app starts will be in m.global.deeplink'
    'uncomment for debugging:
    'print "deeplink at start of app"
    'print m.global.deeplink

    ' "finding grid node"
    m.markupgrid = m.top.findNode("exampleMarkupGrid")
    m.usertext= m.top.findNode("USX")
    m.userposter=m.top.findNode("UserPoster")
    m.userpostertext=m.top.findNode("userpostertext")
    m.TimedOverlay=m.top.findnode("TimedContentOverlay")
    m.SelectedUser={}
    ''"when content of screen is loaded, print acknowledgement"
    m.markupgrid.observeField("content","ackgridcontentloaded")

    ' "creating profile task"
    m.profileTask=createObject("roSGNode","profileTask")
    ' "setting up observers"
    m.profileTask.observeField("deeplinked","updateGlobalDeepLink")
    m.profileTask.observeField("userindex","setGridfocus")     ''
    m.profileTask.observeField("content", "showmarkupgrid")
    m.markupgrid.observeField("itemSelected","ProfileItemSelected")
    ' "starting profile content loader and listener"
    m.profileSelected=false
    m.profileTask.control="RUN"

    m.RowList = m.top.findNode("RowList")
    m.Title = m.top.findNode("Title")
    m.Description = m.top.findNode("Description")
    m.Poster = m.top.findNode("Poster")
    ' "show profile selector"
    m.rowlist.visible=false

    ' "prep feed parser"
    m.LoadTask = CreateObject("roSGNode", "FeedParser")  'Create XML parsing node task

    m.LoadTask.observeField("content", "rowListContentChanged")
    m.LoadTask.observeField("mediaIndex","indexloaded")
    'defer running task till after user is selected


    m.InputTask=createObject("roSgNode","inputTask")
    m.InputTask.observefield("inputData","handleInputEvent")
    'defer running task till after user is selected

    m.RowList.observeField("rowItemFocused", "changeContent")

    m.Video = m.top.findNode("Video")
    m.Video.enableUI = false  ' enable media player custom UI'
    m.Video.content = invalid
    m.Video.observeField("state", "onVideoStateChanged")
    m.VideoContent = createObject("roSGNode", "ContentNode")
    m.RowList.observeField("rowItemSelected", "playVideo")

    ' so we can use next video in playlist'
    m.Video.contentIsPlaylist = true

    ' Node for RALE tool'
    m.tracker = m.top.createChild("TrackerTask")

End Sub


function showmarkupgrid(param)
  ' "extract useful parameters for this application"
  ' "get node passed from voice command"
  sgnode=param.getdata()
  ' "count how many user profiles to select from"
  count=sgnode.getchildcount()
  ' "get list of profiles"
  result=sgnode.getchildren(count,0)

' "set up columns for display of profiles"
m.markupgrid.numColumns=count

' "add profiles to grid"
m.markupgrid.content = m.profileTask.content
' "set focus on markup grid"
m.markupgrid.setFocus(true)

end function

function ProfileItemSelected(idx)
  'uncomment for debugging:
  'print "index data type:";type(idx)
  'print "setting grid focus in response to voice selection"
  'print "index.getData=" idx.getdata()
  'print "index.getData type="; type(idx.getdata())
  m.userselected=idx.getdata()
  m.markupgrid.jumptoitem=idx.getdata()
  m.selectedUser = m.markupgrid.content.getchild(m.markupgrid.itemSelected)
  'uncomment for debugging:
  'print m.selectedUser

  StoreProfileAndRun(m.selectedUser)
end function

function setGridfocus(idx)
  m.userselected=idx.getdata()
  m.markupgrid.jumptoitem=idx.getdata()
  m.selectedUser = m.markupgrid.content.getchild(m.markupgrid.itemfocused)
  print m.selectedUser
StoreProfileAndRun(m.selectedUser)
end function

function ackgridcontentloaded(params)
  print "grid content should be loaded now"
  print type(params)
end function

sub StoreProfileAndRun(user)
    timer=createobject("roTimeSpan")
    timer.mark()
    'Run deferred task nodes
    m.LoadTask.control = "RUN"
    m.InputTask.control="RUN"
    m.ProfileTask.control="STOP"
    m.UserPoster.uri=user.HDPOSTERURL
    m.userpostertext.text=user.text
    m.userpostertext.visible=true
    m.usertext.visible=false
    m.UserPoster.visible=true
    m.rowlist.visible=true
    m.rowlist.Setfocus(true)
end sub


sub indexloaded(msg as Object)
    'content is loaded and indexed for deep linking, handle'
    if type(msg) = "roSGNodeEvent" and msg.getField() = "mediaIndex"
        m.mediaIndex = msg.getData()
    end if
    ' signal app launch completed beacon (requires RAF library instantiated to actually send beacon)
      m.top.setField("beacon", "AppLaunchComplete")

    'if a deep link is present, handle it'
      handleDeepLink(m.global.deeplink)
end sub

Function handleDeepLink(deeplink as object)
  if validateDeepLink(deeplink)
    ' "deeplink validated, now play vid"
    ' "video link:";m.mediaIndex[deeplink.id].url
    playVideo(m.mediaIndex[deeplink.id].url)
  else
    'uncomment for debugging:
    'print "deeplink not validated"
  end if
end Function

sub handleInputEvent(msg)
    'event arrives via roInput'
    if type(msg) = "roSGNodeEvent" and msg.getField() = "inputData"
    ' "it is an sgnode event and msg.getfield=inputdata"
        inputData = msg.getData()
        if inputData <> invalid
          ' "input data valid"
          if inputData.controltype = "deeplink"
            handleDeepLink(inputData)
          else
            ' "inputdata.type must be something else"
            'uncomment for debugging:'
            'print inputdata.type
          end if
        else
          'uncomment for debugging:
          'print "input data is invalid"
        end if
    else
      'uncomment for debugging:
      'print "deeplink unhandled"
    end if
end sub



function validateDeepLink(deeplink as Object) as Boolean
  ' "validate deep link"
  mediatypes={movie:"movie",episode:"episode",season:"season",series:"series"}
  if deeplink <> Invalid
      'uncomment for debugging:
      'print "mediaType = "; deeplink.type
      'print "contentId = "; deeplink.id
      'print "content= "; m.mediaIndex[deeplink.id]
      if deeplink.type <> invalid then
        if mediatypes[deeplink.type]<> invalid
          if m.mediaIndex[deeplink.id] <> invalid
            if m.mediaIndex[deeplink.id].url <> invalid
              return true
            else
                'uncomment for debugging:
                'print "invalid deep link url"
            end if
          else
            'uncomment for debugging:
            'print "bad deep link contentId"
          end if
        else
          'uncomment for debugging:
          'print "unknown media type"
        end if
      else
        'uncomment for debugging:
        'print "deeplink.type string is invalid"
      end if
  end if
  return false
end function



Sub rowListContentChanged(msg as Object)
  m.markupgrid.visible=false
    if type(msg) = "roSGNodeEvent" and msg.getField() = "content"
        m.RowList.content = msg.getData()
    end if
end Sub

Sub changeContent()  'Changes info to be displayed on the overhang
    contentItem = m.RowList.content.getChild(m.RowList.rowItemFocused[0]).getChild(m.RowList.rowItemFocused[1])
    'contentItem is a variable that points to (rowItemFocused[0]) which is the row, and rowItemFocused[1] which is the item index in the row

    m.top.backgroundUri = contentItem.HDPOSTERURL  'Sets Scene background to the image of the focused item
    'm.Poster.uri = contentItem.HDPOSTERURL  'Sets overhang image to the image of the focused item
    m.Title.text = contentItem.TITLE  'Sets overhang title to the title of the focused item
    m.Description.text = contentItem.DESCRIPTION  'Sets overhang description to the description of the focused item
End Sub

Sub playVideo(url = invalid)
    'm.video.control="stop"
    print "sub playvideo"
    ? "url= "; url
    if type(url) = "roSGNodeEvent"   ' passed from observe callback'
        print "url is a node"
        m.videoContent = m.RowList.content.getChild(m.RowList.rowItemFocused[0])
        'rowItemFocused[0] is the row and rowItemFocused[1] is the item index in the row
        'm.videoContent.streamFormat = "mp4"
        m.Video.content = m.videoContent
        m.Video.contentIsPlaylist = true
    else

        print "url is a string"
        m.videoContent.url = url
        m.videoContent.streamFormat = "mp4"
        keepPlaying = false
        m.video.control="stop"
        m.video.content=invalid
        m.Video.content=m.videoContent
        m.Video.contentIsPlaylist = false
    end if
    m.Video.visible = "true"
    m.Video.control = "play"
    column = m.RowList.rowItemFocused[1]
    ' avoid double loading bar if it is first item'
    if column > 0
      m.video.nextContentIndex = column
      m.Video.control = "skipcontent"
    end if

    m.Video.setFocus(true)

    m.vector2danimation = m.top.FindNode("moveOverhangPanelUp")
    m.vector2danimation.repeat = false
    m.vector2danimation.control = "start"
End Sub

Function returnToUIPage()
    ? "m.Video.pauseBufferStart= "; m.Video.pauseBufferStart
    m.Video.visible = "false" 'Hide video
    m.Video.control = "stop"  'Stop video from playing
    m.RowList.setFocus(true)

    m.vector2danimation = m.top.FindNode("moveOverhangPanelDown")
    m.vector2danimation.repeat = false
    m.vector2danimation.control = "start"
end Function

Function onVideoStateChanged(msg as Object)
  if type(msg) = "roSGNodeEvent" and msg.getField() = "state"
      state = msg.getData()
      ? "onVideoStateChanged() state= "; state
      if state = "finished"
          returnToUIPage()
      end if
  end if
end Function

Function onKeyEvent(key as String, press as Boolean) as Boolean  'Maps back button to leave video
    if press
      print "pressed key="; key
        if key = "back"  'If the back button is pressed
            if m.Video.visible
                returnToUIPage()
                return true
            else
                return false
            end if
        end if
    end if
end Function

function updateGlobalDeepLink(param)
  'this is for the case where a deep link arrives via roInput while profile selector is active. '
  m.global.deeplink = m.profileTask.deeplinked
end function
