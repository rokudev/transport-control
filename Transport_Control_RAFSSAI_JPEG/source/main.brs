'********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

sub main()
    screen = CreateObject("roSGScreen") 'Create SceneGraph screen
    m.port = CreateObject("roMessagePort") 'Create message port to listen for screen events
    screen.setMessagePort(m.port)
    m.scene = screen.CreateScene("Mainscene") 'Sets main scene to be SimpleCaptionsScene

    m.global = screen.getGlobalNode()
    m.global.addField("version", "string", false)
    m.global.version = getOSVersion()    ' format OS major + minor, e.g 900 or 910'
    ? "m.global.version= "; m.global.version

    screen.show() 'Show screen

    while(true) 'This loop constantly listens for a screen close message so that it will stop the app.
      msg = wait(0, m.port)
	    msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while
end sub


function getOsVersion() as string
  version = createObject("roDeviceInfo").GetVersion()
  major = Mid(version, 3, 1)
  minor = Mid(version, 5, 2)
  'build = Mid(version, 8, 5)
  return major + minor
end function
