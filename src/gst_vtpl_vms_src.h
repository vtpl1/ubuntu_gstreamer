#ifndef __GST_VTPL_VMS_PLUGIN_H__
#define __GST_VTPL_VMS_PLUGIN_H__
#include <gio/gio.h>
#include <gst/base/gstpushsrc.h>
#include <gst/gst.h>

#define GST_TYPE_VTPL_VMS_SRC (gst_vtpl_vms_src_get_type())

#define GST_VTPL_VMS_SRC(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), GST_TYPE_VTPL_VMS_SRC, GstVtplVmsSrc))

#define GST_VTPL_VMS_SRC_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), GST_TYPE_VTPL_VMS_SRC, GstVtplVmsSrcClass))

#define GST_IS_VTPL_VMS_SRC(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), GST_TYPE_VTPL_VMS_SRC))

#define GST_IS_VTPL_VMS_SRC_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), GST_TYPE_VTPL_VMS_SRC))

typedef struct _GstVtplVmsSrc GstVtplVmsSrc;
typedef struct _GstVtplVmsSrcClass GstVtplVmsSrcClass;

typedef enum {

  GST_VTPL_VMS_SRC_OPEN = (GST_BASE_SRC_FLAG_LAST << 0),
  GST_VTPL_VMS_SRC_FLAG_LAST = (GST_BASE_SRC_FLAG_LAST << 2)

} GstVtplVmsSrcFlags;

struct _GstVtplVmsSrc {
  GstPushSrc element;

  /* server information */
  int port;
  gchar *host;
  guint timeout;

  /* socket */
  GSocket *socket;
  GCancellable *cancellable;

  guint64 bytes_received;
  GstStructure *stats;
};

struct _GstVtplVmsSrcClass {
  GstPushSrcClass parent_class;
};

GType gst_vtpl_vms_src_get_type(void);

G_END_DECLS

#endif /* __GST_VTPL_VMS_PLUGIN_H__ */