#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

//#include "gstsocketsrc.h"
#include "gsttcpclientsrc.h"
//#include "gsttcpclientsink.h"
//#include "gsttcpserversrc.h"
//#include "gsttcpserversink.h"
//#include "gstmultifdsink.h"
//#include "gstmultisocketsink.h"

GST_DEBUG_CATEGORY (tcp_debug);

static gboolean
plugin_init (GstPlugin * plugin)
{
  // if (!gst_element_register (plugin, "socketsrc", GST_RANK_NONE,
  //         GST_TYPE_SOCKET_SRC))
  //   return FALSE;
  // if (!gst_element_register (plugin, "tcpclientsink", GST_RANK_NONE,
  //         GST_TYPE_TCP_CLIENT_SINK))
  //   return FALSE;
  if (!gst_element_register (plugin, "tcpclientsrc", GST_RANK_NONE,
          GST_TYPE_TCP_CLIENT_SRC))
    return FALSE;
//   if (!gst_element_register (plugin, "tcpserversink", GST_RANK_NONE,
//           GST_TYPE_TCP_SERVER_SINK))
//     return FALSE;
//   if (!gst_element_register (plugin, "tcpserversrc", GST_RANK_NONE,
//           GST_TYPE_TCP_SERVER_SRC))
//     return FALSE;
// #ifdef HAVE_SYS_SOCKET_H
//   if (!gst_element_register (plugin, "multifdsink", GST_RANK_NONE,
//           GST_TYPE_MULTI_FD_SINK))
//     return FALSE;
// #endif
//   if (!gst_element_register (plugin, "multisocketsink", GST_RANK_NONE,
//           GST_TYPE_MULTI_SOCKET_SINK))
//     return FALSE;

  GST_DEBUG_CATEGORY_INIT (tcp_debug, "tcp", 0, "TCP calls");

  return TRUE;
}

GST_PLUGIN_DEFINE (GST_VERSION_MAJOR,
    GST_VERSION_MINOR,
    tcp,
    "transfer data over the network via TCP",
    plugin_init, VERSION, GST_LICENSE, GST_PACKAGE_NAME, GST_PACKAGE_ORIGIN)