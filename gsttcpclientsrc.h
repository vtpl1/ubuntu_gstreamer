#ifndef __GST_VTPL_TCP_CLIENT_SRC_H__
#define __GST_VTPL_TCP_CLIENT_SRC_H__

#include <gst/gst.h>
#include <gst/base/gstpushsrc.h>

#include <gio/gio.h>

G_BEGIN_DECLS

#define GST_TYPE_VTPL_TCP_CLIENT_SRC \
  (gst_tcp_client_src_get_type())
#define GST_VTPL_TCP_CLIENT_SRC(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj),GST_TYPE_VTPL_TCP_CLIENT_SRC,GstVTPLTCPClientSrc))
#define GST_VTPL_TCP_CLIENT_SRC_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass),GST_TYPE_VTPL_TCP_CLIENT_SRC,GstVTPLTCPClientSrcClass))
#define GST_IS_VTPL_TCP_CLIENT_SRC(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj),GST_TYPE_VTPL_TCP_CLIENT_SRC))
#define GST_IS_VTPL_TCP_CLIENT_SRC_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass),GST_TYPE_VTPL_TCP_CLIENT_SRC))

typedef struct _GstVTPLTCPClientSrc GstVTPLTCPClientSrc;
typedef struct _GstVTPLTCPClientSrcClass GstVTPLTCPClientSrcClass;

typedef enum {
  GST_VTPL_TCP_CLIENT_SRC_OPEN       = (GST_BASE_SRC_FLAG_LAST << 0),

  GST_VTPL_TCP_CLIENT_SRC_FLAG_LAST  = (GST_BASE_SRC_FLAG_LAST << 2)
} GstVTPLTCPClientSrcFlags;

struct _GstVTPLTCPClientSrc {
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

struct _GstVTPLTCPClientSrcClass {
  GstPushSrcClass parent_class;
};

GType gst_tcp_client_src_get_type (void);

G_END_DECLS

#endif /* __GST_VTPL_TCP_CLIENT_SRC_H__ */