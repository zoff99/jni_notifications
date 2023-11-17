package com.zoffcc.applications.jninotifications;

import java.nio.ByteBuffer;

public class NTFYActivity {
    private static final String TAG = "NTFYActivity";
    static final String Version = "0.99.9";

    public static native String jninotifications_version();
    public static native int jninotifications_notify(String application, String title, String message);
}