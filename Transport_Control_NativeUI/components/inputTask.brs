Sub Init()
    m.port=createobject("romessageport")
    m.top.observeField("transportResponse", m.port)
    m.xfer = createObject("roUrlTransfer")
    m.transportIdList = {}

    m.top.functionName = "listenInput"
End Sub

function ListenInput()

    InputObject=createobject("roInput")
    InputObject.setmessageport(m.port)

    while true
      msg=m.port.waitmessage(500)
      if type(msg)="roInputEvent" then
        print "INPUT EVENT!"
        if msg.isInput()
          inputData = msg.getInfo()
          'print inputData'
          for each item in inputData
            print item  +": " inputData[item]
          end for

          ' pass the deeplink to UI
          if inputData.DoesExist("mediaType") and inputData.DoesExist("contentID")
            deeplink = {
                id: inputData.contentID
                mediaType: inputData.mediaType
                type: "deeplink"
            }
            print "got input deeplink= "; deeplink
            m.top.inputData = deeplink
          else if m.global.version >= "910" and inputData.DoesExist("type") and inputData.type = "transport"
            transport = {
                id: inputData.id
                command: inputData.command
                duration: inputData.duration
                direction: inputData.direction
                type: inputData.type
            }
            print "got transport input= "; transport
            m.transportIdList[inputData.id] = {transport: transport}
            ? "id list size= "; m.transportIdList.count()
            m.top.inputData = transport
          end if
        end if
      else if type(msg) = "roSGNodeEvent"
        if msg.getField() = "transportResponse"
            response = msg.getData()
            ? "transport response= "; response
            id = response.id
            job = m.transportIdList[id]
            if job <> invalid
                eventStatus = response.status
                ' Send the response (may need to be after command executed)
                InputObject.EventResponse({id:inputData.id, status: eventStatus})
                m.transportIdList.delete(id)
                ? "deleted from list id= "; id
            else
                ? "id= "; id; " not found"
            end if

        end if
      end if
    end while
end function
