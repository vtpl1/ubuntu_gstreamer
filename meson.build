project('gst-vtpl-vms-source-element', 'c',
  version : '1.15.0.0',
  meson_version : '>= 0.54',
  default_options : [ 'warning_level=1',
                      'buildtype=debugoptimized' ])

gst_version = meson.project_version()
version_arr = gst_version.split('.')
gst_version_major = version_arr[0].to_int()
gst_version_minor = version_arr[1].to_int()
gst_version_micro = version_arr[2].to_int()

gst_req = '>= @0@.@1@.0'.format(gst_version_major, gst_version_minor)

gst_vtpl_sources = [
  # 'gsttcpclientsrc.c',
  'gsttcpsrcstats.c',
  # 'gsttcpplugin.c',
  'src/gst_vtpl_vms_plugin.c',
  'src/gst_vtpl_vms_src.c'
]

gst_plugins_base_args = ['-DHAVE_CONFIG_H']


# GIO is used by the GIO plugin, and by the TCP, SDP, and RTSP plugins
gio_dep = dependency('gio-2.0', fallback: ['glib', 'libgio_dep'])

gst_base_dep = dependency('gstreamer-base-1.0', version : gst_req,
  fallback : ['gstreamer', 'gst_base_dep'])
gst_net_dep = dependency('gstreamer-net-1.0', version : gst_req,
  fallback : ['gstreamer', 'gst_net_dep'])

subdir('gst-libs')
configinc = include_directories('.', './src')
libsinc = include_directories('gst-libs')
# 'Monotosh' +  gst_base_dep
# libsinc = include_directories('gst_base_dep')


library('vtpl',
    gst_vtpl_sources,
    c_args : gst_plugins_base_args,
    include_directories: [configinc, libsinc],
    dependencies : [gio_dep, gst_base_dep, gst_net_dep]
)
