# dependencies
gst_dep = dependency('gstreamer-1.0')
gst_ver = gst_dep.version().split('.')
gst_web_deps = [
  gst_dep,
  dependency('glib-2.0'),
  dependency('gio-2.0'),
  meson.get_compiler('vala').find_library('posix'),
]
nginx = find_program('nginx', required: true)

# files that need configuring:
# (find and @replace@)
# so yeah, using meson as a preprocessor here
# since the vala preprocessor is intentionally limited
plugin_vala = configure_file(
  input: 'plugin.vala',
  output: 'plugin.vala',
  configuration: {
  'version': meson.project_version(),
  'gst_major_version': gst_ver[0].to_int(),
  'gst_minor_version': gst_ver[1].to_int(),
  'project_name': meson.project_name(),
  'project_description': project_description,
  'license': ','.join(meson.project_license()),
  'project_url': project_url,
  'package_name': package_name,
  'origin': origin,
  }
)
webserverbin_vala = configure_file(
  input: 'webserverbin.vala',
  output: 'webserverbin.vala',
  configuration: {
    # in Meson .55 .full_path() also works
    'nginx_path': nginx.path(),
  }
)

gst_web_sources = [
  plugin_vala,
  'webserverbin.vala',
]
ver_arr = meson.project_version().split('.')
gst_web_libname = meson.project_name() + '-' + ver_arr[0]+ '.' + ver_arr[1]
gst_web_lib = library(meson.project_name(), gst_web_sources,
  vala_header: meson.project_name() + '.h',
  vala_vapi: gst_web_libname + '.vapi',
  vala_gir: gst_web_libname + '.gir',
  dependencies: gst_web_deps,
  install: true,
  install_dir: [plugins_install_dir, true, true, true],
)
