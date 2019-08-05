# Transport controls

## **Overview**

This sample demonstrates how to handle voice commands in your channel. It shows you how to use the [**roInputEvent**](https://developer.roku.com/docs/references/brightscript/events/roinputevent.md) to listen for transport events and then process them. 

This sample includes standard and custom video player channels and a live channel: 

- The standard UI channel shows how the native Roku Media Player handles transport controls.  You can run this channel and use the [debug console](https://developer.roku.com/docs/developer-program/debugging/debugging-channels.md) to view output related to transport events. 

- The custom UI and live channels shows how your application can receive and process transport controls. This is especially important if your channel uses custom [trick mode](https://developer.roku.com/docs/developer-program/media-playback/trick-mode.md) or it is using a [server-side ad insertion (SSAI)](https://developer.roku.com/docs/developer-program/advertising/ssai-adapters.md) implementation of the [Roku Advertising Framework (RAF)](https://developer.roku.com/docs/developer-program/advertising/roku-advertising-framework.md) because your channel must explicitly handle "seek" and "start over" transport commands in these cases.   

### Transport control components

The **InputTask** component listens for **roInputEvent** events to check whether a transport control has been received. When one is received, it updates a global variable being monitored by the **ExtVideoPlayerUI** and **customVid** components in the custom UI and live channels, respectively. 

The **ExtVideoPlayerUI** component in the custom UI channel and the **customVid** component in the live channel take the transport event and pass it to a method that processes it based on its type. The channels explicitly handle "seek" and "start over" commands, which is required for implementing custom trick mode, while letting the Roku OS implicitly handle "fast forward", "rewind", and "replay" commands. The channels then display the updated position on the progress bar, and the control button corresponding to the event being executed.

### Video content components

The **FeedParser** component retrieves the video content items used in this sample from an XML feed and then indexes and transforms them into ContentNodes so they can be displayed in BrightScript components. This process is useful if you do not have a web service for pulling content IDs from your feed (for example, your feed is maintained in an Amazon S3 bucket).

Specifically, the **FeedParser** component stores the stream URLs and other meta data for each content item in the feed in an array of associative arrays. The captured meta data includes a thumbnail image (used for the channel&#39;s poster and background images), description, and title. Importantly, it stores the items&#39; GUIDs as content IDs and links them to the metadata. This enables you to pass the GUIDs in ECP cURL commands and deep link into the associated content. To display the content items on the screen, it formats the items into ContentNodes and then populates them in a RowItem.

The **HomeScene** component creates the scene used by the sample (a RowItem with four rows of Posters displaying the content&#39;s thumbnails), and it plays the video content item linked to the deep link it receives. The module contains an observer that listens for when a deep link is received. Upon receiving one, it validates the stream URL, content ID, and media type, and then launches the channel and plays the video specified by the content ID in the deep link.

## **Installation**

To run this sample, follow these steps:

1. Download and then extract the sample.

2. In the extracted **transport-control-master** folder, expand the folder containing the sample you wan to run:  **Transport_Control_NativeUI**,  **Transport_Control_CustomUI**, or **Transport_Control_LiveChannels**. Compress the contents in the expanded folder to a ZIP file.

3.  Follow the steps in [Loading and Running Your Application](https://developer.roku.com/en-gb/docs/developer-program/getting-started/developer-setup.md#step-1-set-up-your-roku-device-to-enable-developer-settings) to enable developer mode on your device and sideload the ZIP file containing the sample onto it.

4.  Optionally, you can launch the sample channel via the device UI to view the scene and video content items. The sample channel is named **TransportControlSample** (dev).

5.  Use a Roku voice remote or the Roku mobile app to issue voice commands such as such as "rewind 30 seconds", "forward 1 minute", or "start over". 

6.  Alternatively, you can run the following cURL commands to test transport controls via ECP POST requests. The syntax for an ECP request is as follows:

    ```
    http://<roku-device-ip-address>:8060/input/<channelId>?id <longInteger>type="transport"&command=<commandValue>
    ```

    For example, to send a "seek" command via an ECP request, you could run the following cURL command:

    ```
    curl -d '' 'http://192.168.1.114:8060/input/dev?id=8&type=transport&command=seek&direction=backward&duration=10'
    ```
