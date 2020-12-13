#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include "vtpl_config.h"
#include "gst_vtpl_vms_src.h"

GST_DEBUG_CATEGORY(vtpl_debug);

static gboolean plugin_init(GstPlugin* plugin) {
  if (!gst_element_register(plugin, "vtplvmssrc", GST_RANK_NONE,
                            GST_TYPE_VTPL_VMS_SRC))
    return FALSE;
  GST_DEBUG_CATEGORY_INIT(vtpl_debug, "vtpl", 0, "Vtpl VMS calls");
  return TRUE;
}
GST_PLUGIN_DEFINE (GST_VERSION_MAJOR,
    GST_VERSION_MINOR,
    vtpl,
    VTPL_DESCRIPTION,
    plugin_init, VTPL_VERSION, VTPL_LICENSE, VTPL_PACKAGE_NAME, VTPL_PACKAGE_ORIGIN)