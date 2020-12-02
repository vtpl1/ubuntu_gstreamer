
#ifndef __GST_I18N_PLUGIN_H__
#define __GST_I18N_PLUGIN_H__

#include <locale.h>  /* some people need it and some people don't */
#include "gettext.h" /* included with gettext distribution and copied */

#ifndef GETTEXT_PACKAGE
#error You must define GETTEXT_PACKAGE before including this header.
#endif

/* we want to use shorthand _() for translating and N_() for marking */
#define _(String) dgettext (GETTEXT_PACKAGE, String)
#define N_(String) gettext_noop (String)
/* FIXME: if we need it, we can add Q_ as well, like in glib */

#endif /* __GST_I18N_PLUGIN_H__ */