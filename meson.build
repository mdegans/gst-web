project('gstweb', ['c', 'vala'],
  version: run_command(
    'head', '-n', '1', files('VERSION'),
  ).stdout().strip(),
  meson_version: '>= 0.49.0',
  license: 'LGPL',
)
# split the project version
proj_ver = meson.project_version().split('.')
# version minus patch revision
prog_ver_short = proj_ver[0] + '.' + proj_ver[1]
# all of this is used by configure_file on plugin.vala
project_description = 'GStreamer web plugin extras.'
package_name = 'source'
origin = 'github'
# change this if you fork this
project_url = 'https://github.com/mdegans/gst-web'
# this is where the plugin will be installed:
plugins_install_dir = join_paths(get_option('libdir'), 'gstreamer-1.0')

subdir('gst-web')
