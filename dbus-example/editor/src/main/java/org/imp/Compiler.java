package org.imp;

import org.freedesktop.dbus.interfaces.DBusInterface;

public interface Compiler extends DBusInterface {
    String CompileIMP(String source);
    String ParseIMP(String source);
}
