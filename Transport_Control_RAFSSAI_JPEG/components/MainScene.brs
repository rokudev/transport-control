' ********** Copyright 2016-2019 Roku Corp.  All Rights Reserved. **********

function init()
    m.video = m.top.findNode("myVideo")
	m.videoPlayer = m.top.findNode("videoPlayer")

	m.playerUI = m.top.findNode("playerUI")

    m.playertask = createObject("roSGNode","PlayerTask")
    m.playertask.video = m.video
    m.playertask.playerUI = m.playerUI
    m.playertask.observeField("adPods", "handleAdPodUpdate")
    m.playertask.control = "RUN"

    m.InputTask = createObject("roSgNode","inputTask")
    m.InputTask.observefield("inputData","handleInputEvent")
    m.InputTask.control="RUN"
    playVideo()
end function

function playVideo() as void

    vidContent = createObject("RoSGNode", "ContentNode")
    vidContent.url = "http://production.smedia.lvp.llnw.net/59021fabe3b645968e382ac726cd6c7b/-P/HHZYyAQwH2HsvMPI9dRM844YFCsrlTO-2zWNBxxgw/video.mp4?x=0&h=88019e9866a54a1418a11d953d464ed5"
    vidContent.streamformat = "mp4"

    m.video.thumbnailHostPrefix = "https://image.roku.com/ZHZscHItc2Ft/thumbnails/RAFSSAI-with-jpeg/"
    m.video.thumbnailIntervalInSecs = 5
    m.video.enableUI = false
    m.video.content = vidContent
    m.playerUI.setFocus(true)
    'm.videoPlayer.setFocus(true)
    m.video.control = "play"
end function

function handleAdPodUpdate(msg)
    adPods = msg.GetData()
    m.playerUI.adPods = adPods
end function
