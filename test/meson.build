# FIXME(mdegans): the way gstweb.h is included is hacky and wrong
#  fix is probably to get the name from the target
# a list of dicts describing tests
tests = [
  {
    'description': 'Test webserverbin element using GstCheck ',
    'filename': 'test_webserverbin',
    'sources': ['test_webserverbin.c'],
  },
]

# build and run tests (on ninja test)
foreach t: tests
  exe = executable(t['filename'], t['sources'],
    dependencies: [gst_web_deps, dependency('gstreamer-check-1.0')],
    link_with: gst_web_lib,
  )
  test(t['description'], exe,
    is_parallel: false,
    # TODO(mdegans): research if there is a dedicated parent directory function
    env: [
      'GST_DEBUG=4',
      'GST_PLUGIN_PATH=' + meson.current_build_dir() + '/../gst-web',
      'GST_REGISTRY_UPDATE=yes',
    ],
  )
endforeach