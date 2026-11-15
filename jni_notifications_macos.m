#import <Foundation/Foundation.h>
#import <Foundation/NSUserNotification.h>
#import <objc/runtime.h>
#import <jni.h>

// ----------- version -----------
// ----------- version -----------
#define VERSION_MAJOR 0
#define VERSION_MINOR 99
#define VERSION_PATCH 2
static const char global_version_string[] = "0.99.2";
// ----------- version -----------
// ----------- version -----------

// macOS needs a bundle identifier that is registered with LaunchServices,
// a plain JVM process has none, so we borrow the one from Terminal.app
static NSString *const fake_bundle_identifier = @"com.apple.Terminal";

@interface NSBundle (jninotifications)
- (NSString *)jninotifications_bundleIdentifier;
@end

@implementation NSBundle (jninotifications)
- (NSString *)jninotifications_bundleIdentifier {
    if (self == [NSBundle mainBundle]) {
        return fake_bundle_identifier;
    }
    return [self jninotifications_bundleIdentifier];
}
@end

// without a delegate that returns YES here the notification is only put into
// the notification center and never shown as a banner
@interface JNINotificationsDelegate : NSObject <NSUserNotificationCenterDelegate>
@end

@implementation JNINotificationsDelegate
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}
@end

static void jninotifications_init_once(void) {
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        Class bundle_class = objc_getClass("NSBundle");
        if (bundle_class != NULL) {
            method_exchangeImplementations(
                class_getInstanceMethod(bundle_class, @selector(bundleIdentifier)),
                class_getInstanceMethod(bundle_class, @selector(jninotifications_bundleIdentifier)));
        }
        static JNINotificationsDelegate *delegate = nil;
        delegate = [[JNINotificationsDelegate alloc] init];
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = delegate;
    });
}

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
        @autoreleasepool {
            jninotifications_init_once();

            NSString *nsTitle = [NSString stringWithUTF8String:title_cstr];
            NSString *nsMessage = [NSString stringWithUTF8String:message_cstr];

            NSUserNotification *userNotification = [[NSUserNotification alloc] init];
            userNotification.identifier = [[NSUUID UUID] UUIDString];
            userNotification.title = nsTitle;
            userNotification.informativeText = nsMessage;

            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];

            // delivery is asynchronous, give it a chance to reach the notification center
            // before the calling (java) process goes away
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
        }
    }

    if (title_cstr != NULL) {
        (*env)->ReleaseStringUTFChars(env, title, title_cstr);
    }
    if (message_cstr != NULL) {
        (*env)->ReleaseStringUTFChars(env, message, message_cstr);
    }

    // NSLog(@"jninotifications:Objective-C");

    return 0;
}
