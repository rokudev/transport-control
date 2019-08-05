
' ********** Copyright 2019 Roku Corp.  All Rights Reserved. **********

Function loadConfig() as Object
    arr = [
'##### Format for inputting stream info #####
'## For each channel, enclose in brackets ##
'{
'   Title: Channel Title
'   streamFormat: Channel stream type (ex. "hls", "ism", "mp4", etc..)
'   live: is this video live, if so it will start in the live/leftmost video position
'   seekRestrict: does the channel not support fastforward,rewind,resume from saved position (ie. twitch vs youtube)
'   Logo: Channel Logo (ex. "http://Roku.com/Roku.jpg)
'   Stream: URL to stream (ex. http://hls.Roku.com/talks/xxx.m3u8)
'}
{
    Title: "Roku Example Bip Bop"
    streamFormat: "hls"
    live: false
    seekRestrict: false
    Logo: "https://storage.needpix.com/rsynced_images/play-button-2138735_1280.png"
    Stream: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"
}
{
    Title: "Sintel the Movie"
    streamFormat: "mp4"
    live: false
    seekRestrict: false
    Logo: "https://durian.blender.org/wp-content/uploads/2010/04/Sintel1.png"
    Stream: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
}
'##### Make sure all Channel content is above this line #####
    ]
    return arr
End Function
