project('vtpl-gst-source-element', 'c',
  version : '1.16.2.0',
  meson_version : '>= 0.54',
  default_options : [ 'warning_level=1',
                      'buildtype=debugoptimized' ])
vtpl_gst_sources = [
  'vtplgsttcpclientsrc.c'
]
library('vtplgstsrc',
    vtpl_gst_sources
)
