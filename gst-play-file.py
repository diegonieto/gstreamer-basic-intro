import gi
gi.require_version('Gst','1.0')
from gi.repository import Gst, GObject, GLib

# Initialize GStreamer
Gst.init(None)

# Create a GStreamer pipeline
pipeline_str = "filesrc location=/home/gstreamer/Descargas/edsheeran-shapeofyou-30-only-video.mp4 ! decodebin ! videoconvert ! waylandsink"
pipeline = Gst.parse_launch(pipeline_str)

# Start the pipeline
pipeline.set_state(Gst.State.PLAYING)

# Wait until error or EOS (End Of Stream) is reached
bus = pipeline.get_bus()
msg = bus.timed_pop_filtered(Gst.CLOCK_TIME_NONE, Gst.MessageType.ERROR | Gst.MessageType.EOS)

# Parse the message
if msg:
    if msg.type == Gst.MessageType.ERROR:
        err, debug_info = msg.parse_error()
        print(f"Error: {err}, Debug Info: {debug_info}")
    elif msg.type == Gst.MessageType.EOS:
        print("End of Stream")

# Clean up
pipeline.set_state(Gst.State.NULL)
