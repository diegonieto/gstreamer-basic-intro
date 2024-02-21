# GStreamer quick overview tutorial
This is part of a 90min GStreamer introduction to showcase the benefits of
GStreamer. This will be distributed with a VirtualBox machine with Ubuntu 22.04.

## Environment
We are gonna use a GStreamer build v1.22.0. We need to load the environment.
All the GStreamer commands should be executed in the shell where we loaeded
our environment
```
cd $HOME/gstreamer
./gst-env.py
```
Export our media to test and generate a short version of it.
`FILE` can be replaced by another, but the following tutorial expects
to have an MP4 with at least one video and one audio streams
```
export FILE="$(realpath ~/Descargas/edsheeran-shapeofyou)"
export FILE30="${FILE}-30"  # Use only first 30s for our tests
ffmpeg -i ${FILE}.mp4 -c copy -t 30 ${FILE30}.mp4 -y
```

# Basics
Let's play with our custom GStreamer build
```
GST_DEBUG_DUMP_DOT_DIR=/tmp \
	gst-launch-1.0 videotestsrc ! waylandsink

# xdot /tmp/*gst-launch.PAUSED_PLAYING.dot # In another shell
```
Understand the plugin properties:
```
gst-inspect-1.0 videotestsrc
```
Modify the resolution parameters:
```
rm /tmp/*.dot
GST_DEBUG_DUMP_DOT_DIR=/tmp \
	gst-launch-1.0 videotestsrc \
	! "video/x-raw,width=640,height=480" \
	! waylandsink
# xdot /tmp/*gst-launch.PAUSED_PLAYING.dot # In another shell
```
Add a custom filter in the middle. Play with `sigma` value, set
also `0` and `10` and check the results.
```
rm /tmp/*.dot
GST_DEBUG_DUMP_DOT_DIR=/tmp \
	gst-launch-1.0 videotestsrc \
	! "video/x-raw,width=640,height=480" \
	! videoconvert \
	! gaussianblur sigma=-10 \
	! videoconvert \
	! waylandsink
# xdot /tmp/*gst-launch.PAUSED_PLAYING.dot # In another shell
```

# Encoding. Understanding why encode it's important
## Checking our resources
Use `gst-discoverer-1.0` to show the media file properties
```
gst-discoverer-1.0 ~/Descargas/edsheeran-shapeofyou.mp4
```

## Demux the file and save only the h264 data
Check we now generated a file with only the video stream from our original MP4 file
```
# 24FPS, only 30 first seconds
rm /tmp/*.dot;
GST_DEBUG_DUMP_DOT_DIR=/tmp \
gst-launch-1.0 \
	  filesrc location=${FILE30}.mp4 \
	! qtdemux name=mydemux \
	  mydemux.video_0 \
	! qtmux \
	! filesink location=${FILE30}-only-video.mp4
```
Check the generated file only has the video stream
```
gst-discoverer-1.0 ${FILE30}-only-video.mp4

```
Check the size
```
ls -lh ${FILE30}-only-video.mp4
```
Play the video
```
gst-launch-1.0 filesrc location= ${FILE30}-only-video.mp4 ! decodebin ! videoconvert ! waylandsink
```

## Demux and decode the file, then save the video data
Check now how the raw size it's huge compared with the h264 encoded one.
`SIZE(i420) = (width*height+2*(width/2*height/2))*framerate*seconds`
`SIZE(i420) = (width*height*3/2)*framerate*seconds`
`SIZE(i420,width=1280,height=720) = (1280*720+2*(1280/2*720/2))*24*30`
```
rm /tmp/*.dot
GST_DEBUG_DUMP_DOT_DIR=/tmp \
gst-launch-1.0 -v \
	  filesrc location=${FILE30}.mp4 \
	! qtdemux name=mydemux \
	  mydemux.video_0 \
	! decodebin \
	! videoconvert \
	! "video/x-raw(format=I420,framerate=24/1)" \
	! filesink location=${FILE30}-only-video.raw
# xdot /tmp/*gst-launch.PAUSED_PLAYING.dot # In another shell
```
Check the size
```
ls -lh ${FILE30}-only-video.raw
```
Play the raw video
```
gst-launch-1.0 filesrc location= ${FILE30}-only-video.raw \
	! videoparse format=i420 width=1280 height=720 \
	! decodebin \
	! videoconvert \
	! waylandsink
```

## Decode and reencode the video
The following decodes the video and encodes the video with
a higher bitrate the original has
```
rm /tmp/*.dot;
GST_DEBUG_DUMP_DOT_DIR=/tmp \
gst-launch-1.0 \
	  filesrc location=${FILE30}.mp4 \
	! qtdemux name=mydemux \
	  mydemux.video_0 \
	! decodebin \
	! x264enc \
		speed-preset=veryslow \
	! qtmux \
	! filesink location=${FILE30}-encode.mp4
# xdot /tmp/*gst-launch.PAUSED_PLAYING.dot # In another shell
```

# Network
## Send webcam video through the network
The following is the command of the sends. In the clients, the IP addresses and
the ports of clients must be specified.
```
echo "Encoding and sending through UDP"
rm /tmp/*.dot
GST_DEBUG_DUMP_DOT_DIR=/tmp \
    gst-launch-1.0 v4l2src device=/dev/video0 \
		! videoconvert \
		! openh264enc \
		! rtph264pay \
		! udpsink clients=192.168.1.13:5005,192.168.1.82:5005
# xdot /tmp/*gst-launch.PAUSED_PLAYING.dot # In another shell
```
This is the command all the clients must execute to receive the data
```
echo "Receiver"
rm /tmp/*.dot
GST_DEBUG_DUMP_DOT_DIR=/tmp \
    gst-launch-1.0 \
	udpsrc port=5005 \
	! application/x-rtp,media=video,clock-rate=90000,encoding-name=H264,payload=96 \
	! rtph264depay \
	! h264parse \
	! openh264dec \
	! videoconvert \
	! waylandsink
# xdot /tmp/*gst-launch.PAUSED_PLAYING.dot # In another shell
```
## Send video file through the network
The following is the command of the sends. In the clients, the IP addresses and
the ports of clients must be specified. This exercise can be done in pairs.
```
rm /tmp/*.dot
GST_DEBUG_DUMP_DOT_DIR=/tmp \
 gst-launch-1.0 filesrc location=${FILE30}.mp4  \
        ! qtdemux name=mydemux mydemux.video_0 \
        ! queue ! decodebin ! videoconvert ! openh264enc \
        ! rtph264pay \
        ! udpsink clients=192.168.1.82:5005,192.168.1.13:5005

# xdot /tmp/*gst-launch.PAUSED_PLAYING.dot # In another shell
```

# Python
Use python binding to play the video with GStreamer
```
cd ~/workspace
python3 gst-play-file.py

```

# Whisper
Whisper is an on development plugin based on OpenAI technology that help us
to transcribe the audio. Check it for an audio file
```
cd $HOME
git clone https://github.com/fluendo/flu-plugins-oss.git -b whisper
cd ~/flu-plugins-oss
export GST_PLUGIN_PATH=`pwd`/builddir/whisper:$GST_PLUGIN_PATH
gst-launch-1.0 -v \
	  filesrc location=${FILE}.mp4 \
	! qtdemux name=mydemux \
	  mydemux.audio_0 \
	! queue \
	! fdkaacdec \
	! audioconvert \
	! audioresample \
	! "audio/x-raw,format=S16LE,channels=1,rate=16000" \
	! audioconvert \
	! wavenc \
	! filesink location=${FILE}.wav

gst-launch-1.0 -v \
	  filesrc location=${FILE}.wav \
         ! decodebin \
         ! audioconvert \
         ! "audio/x-raw,format=F32LE" \
         ! whisper \
         	model-path=${HOME}/whisper.cpp/models/ggml-small.bin \
         	silent=false \
         ! fakesink
```

# Annex. GStreamer quick overview tutorial setup
1.- Run `update.sh` in your Ubuntu 22.04 machine to install all the needed tools

2.- Run `gstreamer-update.sh` to clone GStreamer sources

3.- Copy `build.sh` into GStreamer folder and run it to build the sources
