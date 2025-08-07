#include "flutter_embedder.h"
#include <stdexcept>
#include <iostream>

// GTK and X11 are needed for the Linux Flutter embedding
#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <QX11Info>

// The official Flutter embedding header
#include <flutter_linux/flutter_linux.h>

FlutterEmbedder::FlutterEmbedder(QObject *parent) : QObject(parent) {
    // It's crucial to initialize GTK for the embedding to work.
    if (!gtk_is_initialized()) {
        gtk_init(nullptr, nullptr);
    }
}

FlutterEmbedder::~FlutterEmbedder() {
    if (m_flutterViewController) {
        g_object_unref(m_flutterViewController);
    }
}

void FlutterEmbedder::embedFlutter(QWindow *window, const QString& projectPath, const QString& icuDataPath) {
    if (!window) {
        std::cerr << "Error: Cannot embed Flutter in a null window." << std::endl;
        return;
    }

    // This ensures the QWindow has a native X11 window handle.
    window->show();

    // 1. Create a GTK window and realize it.
    GtkWindow* gtk_window = GTK_WINDOW(gtk_window_new(GTK_WINDOW_TOPLEVEL));
    gtk_widget_realize(GTK_WIDGET(gtk_window));

    // 2. Reparent the GTK window into the QML QWindow using the X11 window ID.
    // This is the core of the embedding.
    Display* display = QX11Info::display();
    WId qwindow_id = window->winId();
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(gtk_window));
    WId gtk_xid = gdk_x11_window_get_xid(gdk_window);
    XReparentWindow(display, gtk_xid, qwindow_id, 0, 0);
    XFlush(display);

    // 3. Resize the GTK window to match the QWindow's size.
    gtk_window_resize(gtk_window, window->width(), window->height());

    // 4. Create a Flutter project handle.
    g_autoptr(FlDartProject) project = fl_dart_project_new();
    fl_dart_project_set_dart_entrypoint_arguments(project, nullptr); // No special entry arguments
    fl_dart_project_set_assets_path(project, projectPath.toStdString().c_str());
    fl_dart_project_set_icu_data_path(project, icuDataPath.toStdString().c_str());

    // 5. Create the Flutter view controller and attach it to the GTK window.
    FlView* flutter_view = fl_view_new(project);
    gtk_container_add(GTK_CONTAINER(gtk_window), GTK_WIDGET(flutter_view));
    m_flutterViewController = FL_VIEW_CONTROLLER(fl_view_controller_new(gtk_window, project));

    if (!m_flutterViewController) {
        std::cerr << "Error: Failed to create Flutter view controller." << std::endl;
        return;
    }

    // 6. Show the GTK window and its contents (the Flutter view).
    gtk_widget_show_all(GTK_WIDGET(gtk_window));
}