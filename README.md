# gst-web

!!!WIP CODE!!!

Gst-web is a set of plugins for GStreamer to test web streaming. Currently gst-web includes:
* webserverbin - a HLS sink bin that launches an nginx subprocess.

## FAQ
- **isn't it bass ackwards to launch NginX from a GStreamer plugin?**
Yes it absolutely is. It's mostly meant for test puposes. Ideally, GStreamer should run as one user in one process, and nginx in another as another user -- however that requires a lot of setup and/or container orchestration that doesn't always play well with the hardware (eg. gpus). This provides a simple, straightforward way to test pipelines without having to bother with all that. Just stick the plugin after a supported encoder and point your browser at the machine (supplying a custom nginx.conf if necessary).