# dependencies
gst_dep = dependency('gstreamer-1.0')
gst_ver = gst_dep.version().split('.')
gst_web_deps = [
  gst_dep,
  dependency('gio-2.0'),
  dependency('glib-2.0'),
  dependency('gstreamer-video-1.0'),
  meson.get_compiler('vala').find_library('posix'),
]
nginx = find_program('nginx', required: true)

# so yeah, using meson as a preprocessor here
# since the vala preprocessor is intentionally limited
plugin_vala = configure_file(
  input: 'plugin.vala',
  output: 'plugin.vala',
  configuration: {
  'version': prog_ver_short,
  'gst_major_version': gst_ver[0].to_int(),
  'gst_minor_version': gst_ver[1].to_int(),
  'project_name': meson.project_name(),
  'project_description': project_description,
  'license': ','.join(meson.project_license()),
  'project_url': project_url,
  'package_name': package_name,
  'origin': origin,
  # global constants:
  'nginx_bin': nginx.path(),
  'nginx_conf': 'nginx.conf',
  }
)

gst_web_sources = [
  plugin_vala,
  'webserverbin.vala',
  'utils.vala',
]

gst_web_libname = meson.project_name() + '-' + prog_ver_short
gst_web_vapi = gst_web_libname + '.vapi'
gst_web_gir = gst_web_libname + '.gir'
gst_web_typelib = gst_web_libname + '.typelib'
gst_web_lib = library(meson.project_name(), gst_web_sources,
  vala_header: meson.project_name() + '.h',
  vala_vapi: gst_web_vapi,
  vala_gir: gst_web_gir,
  vala_args : '--vapi-comments',
  dependencies: gst_web_deps,
  install: true,
  install_dir: [plugins_install_dir, true, true, true],
)

# FIXME(mdegans): so this fails to build in Docker
#  (presumably a dependency issue)
# g_ir_compiler = find_program('g-ir-compiler')
# custom_target(meson.project_name() + ' typelib',
#   command: [g_ir_compiler, '--output', '@OUTPUT@', '@INPUT@'],
#   input: meson.current_build_dir() / gst_web_gir,
#   output: gst_web_typelib,
#   depends: gst_web_lib,
#   install: true,
#   install_dir: get_option('libdir') / 'girepository-1.0',
# )
