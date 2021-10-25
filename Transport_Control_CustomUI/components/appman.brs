Sub Init()
    ' "initializing Profile Listener"
    ' "detach thread from calling function so it runs independently:"
    m.top.functionName = "appman"
    ' "create app mgr so we can tell voice VIDEO TITLE"
    m.am = CreateObject("roAppManager")
    ' "set up listener "
    m.title=m.top.findnode("Title")
    m.done=m.top.findNode("done")
    m.done=false
    m.port=createObject("roMessagePort")
    m.top.observeField("Title",m.port)

End Sub


function appman()
    ' "appmanager running"
    while true
      msg=wait(0,m.port)
      print type(msg)
      if type(msg)="roSGNodeEvent" then
        data=msg.getdata()
        print data
      end if
      m.am.SetNowPlayingContentMetaData({title:data.ContentTitle,contentType: Data.contentType})
    end while
end function
