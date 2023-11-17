#define _GNU_SOURCE

#include <jni.h>

#include <libnotify/notify.h>
#include <stdio.h>

// ----------- version -----------
// ----------- version -----------
#define VERSION_MAJOR 0
#define VERSION_MINOR 99
#define VERSION_PATCH 0
static const char global_version_string[] = "0.99.0";
// ----------- version -----------
// ----------- version -----------

#ifdef __cplusplus
extern "C" {
#endif

JNIEnv *jnienv;
JavaVM *cachedJVM = NULL;

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
    return (*env)->NewStringUTF(env, global_version_string);
}

JNIEXPORT jint JNICALL
Java_com_zoffcc_applications_jninotifications_NTFYActivity_jninotifications_1notify(JNIEnv *env, jobject thiz,
    jstring application, jstring title, jstring message)
{
    int ret = 0;

    if ((application == NULL) || (title == NULL) || (message == NULL))
    {
        return (jint)-1;
    }

    const char *application_cstr = (*env)->GetStringUTFChars(env, application, NULL);
    const char *title_cstr = (*env)->GetStringUTFChars(env, title, NULL);
    const char *message_cstr = (*env)->GetStringUTFChars(env, message, NULL);

    notify_init(application_cstr);
    NotifyNotification* notification = notify_notification_new(title_cstr, message_cstr, 0);
    notify_notification_set_timeout(notification, 4000); // 4 seconds
    if (!notify_notification_show(notification, 0))
    {
        ret = -2;
    }

    if (application_cstr != NULL)
    {
        (*env)->ReleaseStringUTFChars(env, application, application_cstr);
    }
    if (title_cstr != NULL)
    {
        (*env)->ReleaseStringUTFChars(env, title, title_cstr);
    }
    if (message_cstr != NULL)
    {
        (*env)->ReleaseStringUTFChars(env, message, message_cstr);
    }

    return (jint)ret;
}

#ifdef __cplusplus
}
#endif