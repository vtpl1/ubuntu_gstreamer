#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include <gst/gst-i18n-plugin.h>
#include <stdio.h>

#include "gst_vtpl_vms_src.h"
#include "gsttcpsrcstats.h"
#include "vtpl_vms_config.h"

GST_DEBUG_CATEGORY_STATIC(vtplvmssrc_debug);
#define GST_CAT_DEFAULT vtplvmssrc_debug

#define MAX_READ_SIZE 4 * 1024

static GstStaticPadTemplate srctemplate = GST_STATIC_PAD_TEMPLATE(
    "src", GST_PAD_SRC, GST_PAD_ALWAYS, GST_STATIC_CAPS_ANY);

enum {
  PROP_0,
  PROP_HOST,
  PROP_PORT,
  PROP_TIMEOUT,
  PROP_STATS,
};

#define gst_vtpl_vms_src_parent_class parent_class
G_DEFINE_TYPE(GstVtplVmsSrc, gst_vtpl_vms_src, GST_TYPE_PUSH_SRC);

static void gst_vtpl_vms_src_set_property(GObject *object, guint prop_id,
                                          const GValue *value,
                                          GParamSpec *pspec);

static void gst_vtpl_vms_src_get_property(GObject *object, guint prop_id,
                                          GValue *value, GParamSpec *pspec);

static void gst_vtpl_vms_src_finalize(GObject *gobject);

static GstStructure *gst_vtpl_vms_src_get_stats(GstVtplVmsSrc *this);

static GstCaps *gst_vtpl_vms_src_getcaps(GstBaseSrc *psrc, GstCaps *filter);

static GstFlowReturn gst_vtpl_vms_src_create(GstPushSrc *psrc,
                                             GstBuffer **outbuf);

static gboolean gst_vtpl_vms_src_stop(GstBaseSrc *bsrc);
static gboolean gst_vtpl_vms_src_start(GstBaseSrc *bsrc);
static gboolean gst_vtpl_vms_src_unlock(GstBaseSrc *bsrc);
static gboolean gst_vtpl_vms_src_unlock_stop(GstBaseSrc *bsrc);

static void gst_vtpl_vms_src_class_init(GstVtplVmsSrcClass *klass) {
  GObjectClass *gobject_class;
  GstElementClass *gstelement_class;
  GstBaseSrcClass *gstbasesrc_class;
  GstPushSrcClass *gstpush_src_class;
  gobject_class = (GObjectClass *)klass;
  gstelement_class = (GstElementClass *)klass;
  gstbasesrc_class = (GstBaseSrcClass *)klass;
  gstpush_src_class = (GstPushSrcClass *)klass;

  gobject_class->set_property = gst_vtpl_vms_src_set_property;
  gobject_class->get_property = gst_vtpl_vms_src_get_property;
  gobject_class->finalize = gst_vtpl_vms_src_finalize;

  g_object_class_install_property(
      gobject_class, PROP_HOST,
      g_param_spec_string(
          "host", "Host", "The host IP address to receive packets from",
          VMS_DEFAULT_HOST, G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));
  g_object_class_install_property(
      gobject_class, PROP_PORT,
      g_param_spec_int("port", "Port", "The port to receive packets from", 0,
                       VMS_HIGHEST_PORT, VMS_DEFAULT_PORT,
                       G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  g_object_class_install_property(
      gobject_class, PROP_TIMEOUT,
      g_param_spec_uint(
          "timeout", "timeout",
          "Value in seconds to timeout a blocking I/O. 0 = No timeout. ", 0,
          G_MAXUINT, VMS_DEFAULT_TIMEOUT,
          G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  /**
   * GstVtplVmsSrc::stats:
   *
   * Sends a GstStructure with statistics. We count bytes-received in a
   * platform-independent way and the rest via the tcp_info struct, if it's
   * available. The OS takes care of the TCP layer for us so we can't know it
   * from here.
   *
   * Struct members:
   *
   * bytes-received (uint64): Total bytes received (platform-independent)
   * reordering (uint): Amount of reordering (linux-specific)
   * unacked (uint): Un-acked packets (linux-specific)
   * sacked (uint): Selective acked packets (linux-specific)
   * lost (uint): Lost packets (linux-specific)
   * retrans (uint): Retransmits (linux-specific)
   * fackets (uint): Forward acknowledgement (linux-specific)
   *
   * Since: 1.18
   */
  g_object_class_install_property(
      gobject_class, PROP_STATS,
      g_param_spec_boxed("stats", "Stats", "Retrieve a statistics structure",
                         GST_TYPE_STRUCTURE,
                         G_PARAM_READABLE | G_PARAM_STATIC_STRINGS));

  gst_element_class_add_static_pad_template(gstelement_class, &srctemplate);

  gst_element_class_set_static_metadata(
      gstelement_class, "Vtpl Vms source", "Source/Network",
      "Receive data as a client from Vtpl Vms over the network via TCP",
      "Monotosh Das <monotosh.das at videonetics dot com>");

  gstbasesrc_class->get_caps = gst_vtpl_vms_src_getcaps;
  gstbasesrc_class->start = gst_vtpl_vms_src_start;
  gstbasesrc_class->stop = gst_vtpl_vms_src_stop;
  gstbasesrc_class->unlock = gst_vtpl_vms_src_unlock;
  gstbasesrc_class->unlock_stop = gst_vtpl_vms_src_unlock_stop;

  gstpush_src_class->create = gst_vtpl_vms_src_create;

  GST_DEBUG_CATEGORY_INIT(vtplvmssrc_debug, "vtplvmssrc", 0, "Vtpl Vms Source");
}

static void gst_vtpl_vms_src_init(GstVtplVmsSrc *this) {
  this->port = VMS_DEFAULT_PORT;
  this->host = g_strdup(VMS_DEFAULT_HOST);
  this->timeout = VMS_DEFAULT_TIMEOUT;
  this->socket = NULL;
  this->cancellable = g_cancellable_new();

  GST_OBJECT_FLAG_UNSET(this, GST_VTPL_VMS_SRC_OPEN);
}

static void gst_vtpl_vms_src_set_property(GObject *object, guint prop_id,
                                          const GValue *value,
                                          GParamSpec *pspec) {
  GstVtplVmsSrc *this = GST_VTPL_VMS_SRC(object);
  switch (prop_id) {
    case PROP_HOST:
      if (!g_value_get_string(value)) {
        g_warning("host property cannot be NULL");
        break;
      }
      g_free(this->host);
      this->host = g_value_dup_string(value);
      break;
    case PROP_PORT:
      this->port = g_value_get_int(value);
      break;
    case PROP_TIMEOUT:
      this->timeout = g_value_get_uint(value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void gst_vtpl_vms_src_get_property(GObject *object, guint prop_id,
                                          GValue *value, GParamSpec *pspec) {
  GstVtplVmsSrc *this = GST_VTPL_VMS_SRC(object);
  switch (prop_id) {
    case PROP_HOST:
      g_value_set_string(value, this->host);
      break;
    case PROP_PORT:
      g_value_set_int(value, this->port);
      break;
    case PROP_TIMEOUT:
      g_value_set_uint(value, this->timeout);
      break;
    case PROP_STATS:
      g_value_take_boxed(value, gst_vtpl_vms_src_get_stats(this));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
      break;
  }
}

static void gst_vtpl_vms_src_finalize(GObject *gobject) {
  GstVtplVmsSrc *this = GST_VTPL_VMS_SRC(gobject);
  if (this->cancellable) g_object_unref(this->cancellable);
  this->cancellable = NULL;
  if (this->socket) g_object_unref(this->socket);
  this->socket = NULL;
  g_free(this->host);
  this->host = NULL;
  gst_clear_structure(&this->stats);

  G_OBJECT_CLASS(parent_class)->finalize(gobject);
}

static GstStructure *gst_vtpl_vms_src_get_stats(GstVtplVmsSrc *this) {
  GstStructure *s;
  printf("+++++++++++++MONOTOSH++++++++");
  GST_ERROR("----------MONOTOSH---------");
  /* we can't get the values post stop so just return the saved ones */
  if (this->stats) return gst_structure_copy(this->stats);

  s = gst_structure_new("GstVtplVmsSrcStats", "bytes-received", G_TYPE_UINT64,
                        this->bytes_received, NULL);

  gst_tcp_stats_from_socket(s, this->socket);

  return s;
}

static GstFlowReturn gst_vtpl_vms_src_create(GstPushSrc *psrc,
                                             GstBuffer **outbuf) {
  GstVtplVmsSrc *this;
  GstFlowReturn ret = GST_FLOW_OK;
  gssize rret;
  GError *err = NULL;
  GstMapInfo map;
  gssize avail, read;
  this = GST_VTPL_VMS_SRC(psrc);
  if (!GST_OBJECT_FLAG_IS_SET(this, GST_VTPL_VMS_SRC_OPEN)) goto wrong_state;

  GST_LOG_OBJECT(this, "asked for a buffer");
  /* read the buffer header */
  avail = g_socket_get_available_bytes(this->socket);
  if (avail < 0) {
    goto get_available_error;
  } else if (avail == 0) {
    GIOCondition condition;
    if (!g_socket_condition_wait(this->socket,
                                 G_IO_IN | G_IO_PRI | G_IO_ERR | G_IO_HUP,
                                 this->cancellable, &err))
      goto select_error;
    condition = g_socket_condition_check(
        this->socket, G_IO_IN | G_IO_PRI | G_IO_ERR | G_IO_HUP);
    if ((condition & G_IO_ERR)) {
      GST_ELEMENT_ERROR(this, RESOURCE, READ, (NULL),
                        ("Socket in error state"));
      *outbuf = NULL;
      ret = GST_FLOW_ERROR;
      goto done;
    } else if ((condition & G_IO_HUP)) {
      GST_DEBUG_OBJECT(this, "Connection closed");
      *outbuf = NULL;
      ret = GST_FLOW_EOS;
      goto done;
    }
    avail = g_socket_get_available_bytes(this->socket);
    if (avail < 0) goto get_available_error;
  }
  if (avail > 0) {
    read = MIN(avail, MAX_READ_SIZE);
    *outbuf = gst_buffer_new_and_alloc(read);
    gst_buffer_map(*outbuf, &map, GST_MAP_READWRITE);
    rret = g_socket_receive(this->socket, (gchar *)map.data, read,
                            this->cancellable, &err);
  } else {
    /* Connection closed */
    *outbuf = NULL;
    read = 0;
    rret = 0;
  }
  if (rret == 0) {
    GST_DEBUG_OBJECT(this, "Connection closed");
    ret = GST_FLOW_EOS;
    if (*outbuf) {
      gst_buffer_unmap(*outbuf, &map);
      gst_buffer_unref(*outbuf);
    }
    *outbuf = NULL;
  } else if (rret < 0) {
    if (g_error_matches(err, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
      ret = GST_FLOW_FLUSHING;
      GST_DEBUG_OBJECT(this, "Cancelled reading from socket");
    } else {
      ret = GST_FLOW_ERROR;
      GST_ELEMENT_ERROR(this, RESOURCE, READ, (NULL),
                        ("Failed to read from socket: %s", err->message));
    }
    gst_buffer_unmap(*outbuf, &map);
    gst_buffer_unref(*outbuf);
    *outbuf = NULL;
  } else {
  }
  g_clear_error(&err);
done:
  return ret;
select_error : {
  if (g_error_matches(err, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
    GST_DEBUG_OBJECT(this, "Cancelled");
    ret = GST_FLOW_FLUSHING;
  } else {
    GST_ELEMENT_ERROR(this, RESOURCE, READ, (NULL),
                      ("Select failed: %s", err->message));
    ret = GST_FLOW_ERROR;
  }
  g_clear_error(&err);
  return ret;
}
get_available_error : {
  GST_ELEMENT_ERROR(this, RESOURCE, READ, (NULL),
                    ("Failed to get available bytes from socket"));
  return GST_FLOW_ERROR;
}
wrong_state : {
  GST_DEBUG_OBJECT(this, "connection closed, cannot read data");
  return GST_FLOW_FLUSHING;
}
}

static GstCaps *gst_vtpl_vms_src_getcaps(GstBaseSrc *bsrc, GstCaps *filter) {
  GstVtplVmsSrc *this;
  GstCaps *caps = NULL;
  this = GST_VTPL_VMS_SRC(bsrc);

  caps = (filter ? gst_caps_ref(filter) : gst_caps_new_any());
  GST_DEBUG_OBJECT(this, "returning caps %" GST_PTR_FORMAT, caps);
  g_assert(GST_IS_CAPS(caps));
  return caps;
}

static gboolean gst_vtpl_vms_src_stop(GstBaseSrc *bsrc) { return FALSE; }
static gboolean gst_vtpl_vms_src_start(GstBaseSrc *bsrc) { return FALSE; }
static gboolean gst_vtpl_vms_src_unlock(GstBaseSrc *bsrc) { return FALSE; }
static gboolean gst_vtpl_vms_src_unlock_stop(GstBaseSrc *bsrc) { return FALSE; }