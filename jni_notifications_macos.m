#import <Foundation/Foundation.h>
#import <Foundation/NSUserNotification.h>
#import <jni.h>

// ----------- version -----------
// ----------- version -----------
#define VERSION_MAJOR 0
#define VERSION_MINOR 99
#define VERSION_PATCH 2
static const char global_version_string[] = "0.99.2";
// ----------- version -----------
// ----------- version -----------

JNIEXPORT jstring JNICALL
Java_com_zoffcc_applications_jninotifications_NTFYActivity_jninotifications_1version(JNIEnv *env, jobject thiz) {
    return (*env)->NewStringUTF(env, global_version_string);
}

JNIEXPORT jint JNICALL
Java_com_zoffcc_applications_jninotifications_NTFYActivity_jninotifications_1notify(JNIEnv *env, jobject thiz,
    jstring application, jstring title, jstring message, jstring icon_filename_fullpath)
{
    if (title == NULL) {
        return -1;
    }
    if (message == NULL) {
        return -1;
    }
    const char *title_cstr = (*env)->GetStringUTFChars(env, title, NULL);
    const char *message_cstr = (*env)->GetStringUTFChars(env, message, NULL);
    if ((title_cstr != NULL) && (message_cstr != NULL)) {
        NSString *nsTitle = [NSString stringWithUTF8String:title_cstr];
        NSString *nsMessage = [NSString stringWithUTF8String:message_cstr];
    
        NSUserNotification *userNotification = [[NSUserNotification alloc] init];
        userNotification.title = nsTitle;
        userNotification.informativeText = nsMessage;
    
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
    }

    (*env)->ReleaseStringUTFChars(env, title, title_cstr);
    (*env)->ReleaseStringUTFChars(env, message, message_cstr);

    // NSLog(@"jninotifications:Objective-C");

    return 0;
}
