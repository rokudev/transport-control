Sub Init()
    m.port=createobject("romessageport")
    m.top.observeField("transportResponse", m.port)
    m.ExtVideo = m.top.getScene().findNode("Video")
    m.top.functionName = "listenInput"
End Sub

function ListenInput()
    ' "input task listening!"
    InputObject=createobject("roInput")
    InputObject.setmessageport(m.port)
    InputObject.enableTransportEvents()

    while true
      msg=m.port.waitmessage(500)
      if type(msg)="roInputEvent" then
        if msg.isInput()
          inputData = msg.getInfo()
          'uncomment for debugging:'
          'print "inputData";inputData
          'for each item in inputData
            'print item  +": " inputData[item]
          'end for

          ' pass the deeplink to UI
          if inputData.DoesExist("mediaType") and inputData.DoesExist("contentID")
            ' "mediatype DoesExist"

            deeplink = {
                id: inputData.contentID
                type: inputData.mediaType
                controltype: "deeplink"
            }
            'notifying homeScene
            m.top.inputData = deeplink
          else if inputData.DoesExist("type") and inputData.type = "transport"
            transport = {
                id: inputData.id
                command: inputData.command
                duration: inputData.duration
                direction: inputData.direction
                type: inputData.type
                controltype:"transport"
            }
            ' "got transport input= "; transport
            ret = m.ExtVideo.callFunc("handleTransport", inputData)
            
            InputObject.EventResponse({id:inputData.id, status: ret})
          end if
        end if
      end if
    end while
end function
