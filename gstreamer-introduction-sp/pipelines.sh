gst-launch-1.0 videotestsrc num-buffers=1 ! "video/x-raw,width=640,height=480,format=I420" ! jpegenc ! filesink location=test.jpeg
gst-launch-1.0 filesrc location= test.jpeg ! jpegdec ! video/x-raw,format=I420 ! filesink location = test-i420
gst-launch-1.0 filesrc location= test-i420 ! videoparse format=i420 width=640 height=480 ! imagefreeze ! decodebin ! videoconvert ! ximagesink
gst-launch-1.0 filesrc location= test.jpeg ! jpegdec ! videoconvert ! video/x-raw,format=RGB ! filesink location = test-rgb
gst-launch-1.0 filesrc location= test-rgb ! videoparse format=rgb width=640 height=480 ! imagefreeze ! decodebin ! videoconvert ! ximagesink
