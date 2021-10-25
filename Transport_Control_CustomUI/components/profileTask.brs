Sub Init()
    ' "initializing Profile Listener"
    ' "detach thread from calling function so it runs independently:"
    m.top.functionName = "profileInput"
    ' "create app mgr so we can tell voice system profile names"
    m.appMgr = CreateObject("roAppManager")
    ' "create a message port for roinput messages"
    m.port=createobject("romessageport")
    ' "set up listener "
    m.top.setFocus(true)
End Sub

function profileInput()
    ' "setting up Voice"
    VoiceConfig()
    ' "starting profileInput"
    m.InputObject=createobject("roInput")
    m.InputObject.setmessageport(m.port)
      m.InputObject.enableTransportEvents()

    while true
      ' "wait for a message on the message port"
      msg=m.port.waitmessage(0)
      if type(msg) <> invalid then
        if type(msg)="roInputEvent" then
          m.msg=msg
          if msg.isInput()
            m.info = msg.getInfo()

            if m.info.DoesExist("type") and m.info.type = "transport"
              ' "ok we have an roInput of the transport type, likely to be a profile selection command"
              ' "handle event and get return value"
              eventStatus = handleTransport(m.info)
              m.InputObject.EventResponse({id:m.info.id, status: eventStatus})


              ' "selecting user number"
              if m.info.command="action" then
                ' "notifying HomeScene"
                m.top.userindex=m.index[m.info.contentID]
              else if m.info.command="select" then
                ' "notifying HomeScene"
                m.top.userindex=m.info.ordinal.toInt()-1
              end if
            else if m.info.DoesExist("mediaType")
            'handle roInputDeepLink that comes in during Profile Selection
            'this will oveerride any deep link that launched the channel
              deeplink = {
                  id: m.info.contentID
                  type: m.info.mediaType
                  controltype: "deeplink"
              }
              'pass deep link up to homeScene'
              m.top.deeplinked = deeplink
            end if
          end if
        end if
      end if
    end while
end function


function VoiceConfig()
'load users - IRL this would be pulled from a server
  m.users=[{"text":"Jim",    "hdGridposterURL":"pkg://images/avatars/m-1.jpg","link":"ec33a4af-515d-4b06-ad0d-1f9977dae461",order:0}
           {"text":"Sarah","hdGridposterURL":"pkg://images/avatars/f-1.jpg","link":"b0e5f5d7-c012-4893-9a93-fbcf35c51c28",order:1}
           {"text":"George", "hdGridposterURL":"pkg://images/avatars/m-3.jpg","link":"c4f5579b-7fc4-4110-bf2c-25b253fc3d30",order:2}
           {"text":"Linda",   "hdGridposterURL":"pkg://images/avatars/f-2.jpg","link":"d8fda150-ae1b-417d-96dc-cb711ab60067",order:3}
           {"text":"Wayne","hdGridposterURL":"pkg://images/avatars/m-2.jpg","link":"ccd153a5-e3a0-4ffe-bf19-51d230fb9fd0",order:4}
           {"text":"Jane",   "hdGridPosterURL":"pkg://images/avatars/f-4.jpg","link":"ddffddaa-fefa-577D-fbff-31415bfedcba",order:5}
           {"text":"Jack",   "hdGridPosterURL":"pkg://images/avatars/m-4.jpg","link":"ffffeeee-aaaa-bbbb-cccc-dddddddddddd",order:6}]

  print "starting getcontent"

m.profiles=createobject("roSGnode","ContentNode")
actions=[]
m.index={}
  for each user in m.users
      action={}
      itemcontent = createobject("roSGNode","ContentNode")
      itemcontent.addfields({text:user.text})
      itemcontent.addfields({"HDPOSTERURL":user.hdGridPosterURL})
      itemcontent.addfields({"order":user.order})
      itemcontent.addfields({"link":user.link})
      action["text"]=user.text
      action["link"]=user.link
      m.index[user.link]=user.order
      actions.push(action)
      m.profiles.appendChild(itemcontent)
  end for


  print "set m.top.content"
  m.top.content = m.profiles


  print "program voice subsystem with names to listen to"
  m.appMgr.SetVoiceActionStrings(actions)

  print "Start voice request to select profile"
  m.appMgr.StartVoiceActionSelectionRequest()
end function


function handleTransport(evt)
    cmd = evt.command
    print "EVENT COMMAND:";cmd
    ret = "success"
? "handler: "; evt.command
    if cmd = "action" ' This is the event for matching action string set above
        print "Voice Action word event"
        print evt.text
        print evt.contentid ' Optional deep link if channel provided

        'ret = "unhandled" ' TODO: Needs handling. Return "success" when handled.
    else if cmd = "select" ' This is the event for handing back number for "Pick the third" type voice command
        print "Voice ordinal event"
        print evt.ordinal

        ret = "success" ' TODO: Needs handling. Return "success" when handled.
    else
        ret = "unhandled"
    end if
    print "ret=";ret
    return ret
end function
