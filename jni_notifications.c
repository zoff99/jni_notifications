#define _GNU_SOURCE

#include <jni.h>

#include <libnotify/notify.h>
#include <stdio.h>
#include <string.h>

// ----------- version -----------
// ----------- version -----------
#define VERSION_MAJOR 0
#define VERSION_MINOR 99
#define VERSION_PATCH 2
static const char global_version_string[] = "0.99.2";
static const char global_version_asan_string[] = "0.99.2-ASAN";
// ----------- version -----------
// ----------- version -----------

#ifdef __cplusplus
extern "C" {
#endif

JNIEnv *jnienv;
JavaVM *cachedJVM = NULL;

// Guard against repeated notify_init() calls.
// Plain static int is sufficient: worst case two threads both see 0 and
// both call notify_init(), which libnotify handles safely after the first
// successful init. Subsequent calls see 1 and skip entirely.
static int notify_init_done = 0;

/**
 * Validates an icon path for safe use with libnotify/D-Bus.
 * Rejects: relative paths, path traversal (".."), embedded null bytes.
 * Returns 1 if safe, 0 if dangerous or NULL.
 */
static int validate_icon_path(const char *path)
{
    if (path == NULL || path[0] == '\0')
    {
        return 0;
    }
    // Reject relative paths — must be absolute
    if (path[0] != '/')
    {
        return 0;
    }
    // Reject path traversal components
    if (strstr(path, "/../") != NULL)
    {
        return 0;
    }
    // Reject trailing "/.."
    size_t len = strlen(path);
    if (len >= 3 && strcmp(path + len - 3, "/..") == 0)
    {
        return 0;
    }
    // Reject bare ".."
    if (strcmp(path, "..") == 0)
    {
        return 0;
    }
    return 1;
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *jvm, void *reserved)
{
    JNIEnv *env_this;
    cachedJVM = jvm;
    if((*jvm)->GetEnv(jvm, (void **) &env_this, JNI_VERSION_1_6))
    {
        return JNI_ERR;
    }
    return JNI_VERSION_1_6;
}

JNIEnv *jni_getenv()
{
    JNIEnv *env_this;
    (*cachedJVM)->GetEnv(cachedJVM, (void **) &env_this, JNI_VERSION_1_6);
    return env_this;
}

int java_find_class_global(char *name, jclass *ret)
{
    JNIEnv *jnienv2;
    jnienv2 = jni_getenv();
    if (jnienv2 == NULL)
    {
        return 0;
    }
    *ret = (*jnienv2)->FindClass(jnienv2, name);
    if(!*ret)
    {
        return 0;
    }
    *ret = (*jnienv2)->NewGlobalRef(jnienv2, *ret);
    return 1;
}


JNIEXPORT jstring JNICALL
Java_com_zoffcc_applications_jninotifications_NTFYActivity_jninotifications_1version(JNIEnv *env, jobject thiz)
{
#if defined(__SANITIZE_ADDRESS__)
    return (*env)->NewStringUTF(env, global_version_asan_string);
#else
    return (*env)->NewStringUTF(env, global_version_string);
#endif
}

JNIEXPORT jint JNICALL
Java_com_zoffcc_applications_jninotifications_NTFYActivity_jninotifications_1notify(JNIEnv *env, jobject thiz,
    jstring application, jstring title, jstring message, jstring icon_filename_fullpath)
{
    int ret = 0;

    if ((application == NULL) || (title == NULL) || (message == NULL))
    {
        return (jint)-1;
    }

    const char *application_cstr = (*env)->GetStringUTFChars(env, application, NULL);
    const char *title_cstr = (*env)->GetStringUTFChars(env, title, NULL);
    const char *message_cstr = (*env)->GetStringUTFChars(env, message, NULL);

    // Guard against OOM: GetStringUTFChars returns NULL under memory pressure
    if ((application_cstr == NULL) || (title_cstr == NULL) || (message_cstr == NULL))
    {
        if (application_cstr != NULL) (*env)->ReleaseStringUTFChars(env, application, application_cstr);
        if (title_cstr != NULL) (*env)->ReleaseStringUTFChars(env, title, title_cstr);
        if (message_cstr != NULL) (*env)->ReleaseStringUTFChars(env, message, message_cstr);
        return (jint)-1;
    }

    const char *icon_filename_fullpath_cstr = NULL;
    int icon_valid = 0;
    if (icon_filename_fullpath != NULL)
    {
        icon_filename_fullpath_cstr = (*env)->GetStringUTFChars(env, icon_filename_fullpath, NULL);
        if (icon_filename_fullpath_cstr != NULL && validate_icon_path(icon_filename_fullpath_cstr))
        {
            icon_valid = 1;
        }
        // Invalid or NULL icon is non-fatal: notification shows without icon
    }

    // Initialize libnotify exactly once. The flag prevents repeated calls
    // after the first successful init. A benign race on the very first calls
    // is acceptable: libnotify handles concurrent notify_init() safely.
    if (!notify_init_done)
    {
        notify_init(application_cstr);
        notify_init_done = 1;
    }

    NotifyNotification* notification = NULL;
    if (icon_valid)
    {
        notification = notify_notification_new(title_cstr, message_cstr, icon_filename_fullpath_cstr);
    }
    else
    {
        notification = notify_notification_new(title_cstr, message_cstr, NULL);
    }

    if (notification == NULL)
    {
        ret = -2;
    }
    else
    {
        notify_notification_set_timeout(notification, NOTIFY_EXPIRES_DEFAULT);
        GError *error = NULL;
        if (!notify_notification_show(notification, &error))
        {
            ret = -2;
            if (error != NULL)
            {
                g_error_free(error);
            }
        }
        // Prevent native memory leak: unref the GObject
        g_object_unref(notification);
    }

    (*env)->ReleaseStringUTFChars(env, application, application_cstr);
    (*env)->ReleaseStringUTFChars(env, title, title_cstr);
    (*env)->ReleaseStringUTFChars(env, message, message_cstr);
    if (icon_filename_fullpath != NULL && icon_filename_fullpath_cstr != NULL)
    {
        (*env)->ReleaseStringUTFChars(env, icon_filename_fullpath, icon_filename_fullpath_cstr);
    }

    return (jint)ret;
}

#ifdef __cplusplus
}
#endif
