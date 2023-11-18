#include <jni.h>
#include <objc/objc-runtime.h>

typedef void (*send_type)(void*, SEL, void*);

void showNotification(const char* title, const char* subtitle, const char* message) {
    // Get the Objective-C class for NSUserNotification
    Class NSUserNotificationClass = objc_getClass("NSUserNotification");
    
    // Create an instance of NSUserNotification
    id notification = class_createInstance(NSUserNotificationClass, 0);
    
    send_type func = (send_type)objc_msgSend;
    // Set the title, subtitle, and message of the notification
    func(notification, sel_registerName("setTitle:"), func(objc_getClass("NSString"), sel_registerName("stringWithUTF8String:"), title));
    func(notification, sel_registerName("setSubtitle:"), func(objc_getClass("NSString"), sel_registerName("stringWithUTF8String:"), subtitle));
    func(notification, sel_registerName("setInformativeText:"), func(objc_getClass("NSString"), sel_registerName("stringWithUTF8String:"), message));
    
    // Get the Objective-C class for NSUserNotificationCenter
    Class NSUserNotificationCenterClass = objc_getClass("NSUserNotificationCenter");
    
    // Get the default notification center
    id notificationCenter = func(NSUserNotificationCenterClass, sel_registerName("defaultUserNotificationCenter"));
    
    // Deliver the notification
    func(notificationCenter, sel_registerName("deliverNotification:"), notification);
}

JNIEXPORT void JNICALL Java_com_example_MyClass_showNotification(JNIEnv* env, jobject obj, jstring jTitle, jstring jSubtitle, jstring jMessage) {
    const char* title = env->GetStringUTFChars(jTitle, NULL);
    const char* subtitle = env->GetStringUTFChars(jSubtitle, NULL);
    const char* message = env->GetStringUTFChars(jMessage, NULL);
    
    showNotification(title, subtitle, message);
    
    env->ReleaseStringUTFChars(jTitle, title);
    env->ReleaseStringUTFChars(jSubtitle, subtitle);
    env->ReleaseStringUTFChars(jMessage, message);
}
