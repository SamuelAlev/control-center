#include "my_application.h"

#include <epoxy/egl.h>
#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

static FlMethodChannel* app_method_channel = nullptr;

// The engine's OpenGL view renderer mixes two OpenGL APIs on the GTK thread:
// it presents each view through a GdkGLContext (GLX on X11) and deliberately
// leaves that current after drawing, and it builds each view's compositor in
// the engine's own EGL contexts, leaving the render context current too. Only
// the implicit view releases it (realize_cb in fl_view.cc), and this app never
// draws into the implicit view: every window it shows is a windowing-API view.
// glvnd allows one window-system API per thread and EGL one thread per
// context, so on X11 the second compositor cannot make its context current,
// the raster thread cannot take the render context back (every window stays
// empty), and GTK's next GLX call can raise a synthetic BadAccess that aborts
// the process. Wrapping the renderer's realize and finalize releases GLX before
// the engine reaches for EGL and EGL once it is done. Upstream Flutter (master
// as of 2026-09) still has both leaks; drop this when the engine releases them.
static void (*engine_renderer_realize)(GtkWidget* widget) = nullptr;
static void (*engine_renderer_finalize)(GObject* object) = nullptr;

static void release_egl_context() {
  if (eglGetCurrentContext() != EGL_NO_CONTEXT) {
    eglMakeCurrent(eglGetCurrentDisplay(), EGL_NO_SURFACE, EGL_NO_SURFACE,
                   EGL_NO_CONTEXT);
  }
}

static void renderer_realize(GtkWidget* widget) {
  gdk_gl_context_clear_current();
  engine_renderer_realize(widget);
  release_egl_context();
}

static void renderer_finalize(GObject* object) {
  // The raster thread can drop the last reference; GDK and Xlib are only
  // called from the GTK thread.
  const gboolean on_gtk_thread =
      g_main_context_is_owner(g_main_context_default());
  if (on_gtk_thread) {
    gdk_gl_context_clear_current();
  }
  engine_renderer_finalize(object);
  if (on_gtk_thread) {
    release_egl_context();
  }
}

// The renderer type is private to the engine and registered with the first
// FlView, so this runs after fl_view_new() and before any view is realized.
// Wayland and the software renderer never register it and need no wrapping.
static void wrap_engine_renderer() {
  GType type = g_type_from_name("FlViewRendererOpenGL");
  if (type == 0 || engine_renderer_realize != nullptr) {
    return;
  }
  // Held for the life of the process, so the patched class is never freed.
  gpointer klass = g_type_class_ref(type);
  engine_renderer_realize = GTK_WIDGET_CLASS(klass)->realize;
  GTK_WIDGET_CLASS(klass)->realize = renderer_realize;
  engine_renderer_finalize = G_OBJECT_CLASS(klass)->finalize;
  G_OBJECT_CLASS(klass)->finalize = renderer_finalize;
}

// Shows the implicit view's window once Flutter draws into it. The app renders
// only into windowing-API windows, so this window stays hidden instead of
// sitting empty beside them.
static void first_frame_cb(GtkWidget* window, FlView* view) {
  gtk_widget_show(window);
}

static void app_method_channel_response_cb(GObject* object,
                                           GAsyncResult* result,
                                           gpointer user_data) {}

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  // The implicit view's window, created by the first activate().
  GtkWindow* window;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  // A re-launch or a forwarded deep link activates the running instance again.
  // Building another FlView here would start a second engine (and run main()
  // again); raise the windows the app already shows instead.
  if (self->window != nullptr) {
    GList* toplevels = gtk_window_list_toplevels();
    for (GList* l = toplevels; l != nullptr; l = l->next) {
      GtkWindow* toplevel = GTK_WINDOW(l->data);
      if (toplevel != self->window &&
          gtk_widget_get_visible(GTK_WIDGET(toplevel)) &&
          gtk_window_get_transient_for(toplevel) == nullptr) {
        gtk_window_present(toplevel);
      }
    }
    g_list_free(toplevels);
    return;
  }

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  self->window = window;

  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Control Center");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Control Center");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  wrap_engine_renderer();
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window only when Flutter renders into it, as Flutter's template
  // does. Realizing the view is what starts the engine.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           window);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  if (app_method_channel == nullptr) {
    FlEngine* engine = fl_view_get_engine(view);
    if (engine != nullptr) {
      FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
      g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
      app_method_channel = fl_method_channel_new(
          messenger, "com.controlcenter/app", FL_METHOD_CODEC(codec));
    }
  }

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

static void my_application_open(GApplication* application, GFile** files,
                                gint n_files, const gchar* hint) {
  if (n_files > 0 && app_method_channel != nullptr) {
    gchar* uri = g_file_get_uri(files[0]);
    g_autoptr(FlValue) args = fl_value_new_string(uri);
    fl_method_channel_invoke_method(app_method_channel, "openUrl", args,
                                    nullptr, app_method_channel_response_cb,
                                    nullptr);
    g_free(uri);
  }

  g_application_activate(application);
}

// Returns the first argument that looks like one of our custom-scheme deep
// links (the `control-center://` app scheme or the reversed-client-id Google
// OAuth redirect `com.googleusercontent.apps.<client>:/…`), or nullptr.
static const gchar* find_deep_link_url(gchar** arguments) {
  for (gchar** a = arguments; a != nullptr && *a != nullptr; a++) {
    if (g_str_has_prefix(*a, "control-center://") ||
        g_str_has_prefix(*a, "com.googleusercontent.apps.")) {
      return *a;
    }
  }
  return nullptr;
}

static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  // When a primary instance already owns the bus name (the app is running and a
  // protocol launch spawned this secondary process), hand any deep-link URL to
  // it over D-Bus via open() — that is how the in-flight OAuth/PR flow in the
  // running app receives the redirect. A plain re-launch just raises the
  // existing window. The primary's *own* first launch is not remote, so it
  // falls through to activate() and builds its window as before (cold-start
  // URLs still reach Dart via dart_entrypoint_arguments).
  if (g_application_get_is_remote(application)) {
    const gchar* url = find_deep_link_url(*arguments + 1);
    if (url != nullptr) {
      g_autoptr(GFile) file = g_file_new_for_uri(url);
      GFile* files[1] = {file};
      g_application_open(application, files, 1, "");
    } else {
      g_application_activate(application);
    }
    *exit_status = 0;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->open = my_application_open;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);

  // NOT G_APPLICATION_NON_UNIQUE: uniqueness is what lets a protocol-launched
  // second process forward its deep-link URL to the already-running instance
  // over D-Bus (see my_application_local_command_line). HANDLES_OPEN routes
  // those URLs to my_application_open.
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", static_cast<GApplicationFlags>(G_APPLICATION_HANDLES_OPEN),
                                     nullptr));
}
