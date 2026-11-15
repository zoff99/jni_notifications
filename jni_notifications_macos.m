#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <jni.h>

// ----------- version -----------
// ----------- version -----------
#define VERSION_MAJOR 0
#define VERSION_MINOR 99
#define VERSION_PATCH 2
static const char global_version_string[] = "0.99.2";
// ----------- version -----------
// ----------- version -----------

// Delegate required to show notifications when the app is in the foreground
@interface JNINotificationsDelegate : NSObject <UNUserNotificationCenterDelegate>
@end

@implementation JNINotificationsDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
}
@end

static JNINotificationsDelegate *g_delegate = nil;
static UNUserNotificationCenter *g_center = nil;
static BOOL g_init_failed = NO;

static void jninotifications_init_once(void) {
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        // Stage 1: CFBundle checks (no exceptions possible)
        CFBundleRef mainBundle = CFBundleGetMainBundle();
        if (mainBundle == NULL) {
            g_init_failed = YES;
            return;
        }
        CFStringRef bundleId = CFBundleGetIdentifier(mainBundle);
        if (bundleId == NULL || CFStringGetLength(bundleId) == 0) {
            g_init_failed = YES;
            return;
        }

        // Stage 2: Verify the bundle is actually registered with LaunchServices.
        // The JDK java binary has an embedded Info.plist with a bundle identifier,
        // so CFBundleGetIdentifier returns non-NULL even for bare JVM processes.
        // But LaunchServices has no bundle proxy for it, causing
        // UNUserNotificationCenter to throw NSInternalInconsistencyException.
        // LSFindApplicationForInfo returns kApplicationNotFound for unregistered bundles.
        CFURLRef appURL = NULL;
        OSStatus status = LSFindApplicationForInfo(kLSUnknownCreator, bundleId, NULL, NULL, &appURL);
        if (status != noErr || appURL == NULL) {
            g_init_failed = YES;
            return;
        }
        CFRelease(appURL);

        // Only reached for genuinely registered .app bundles
        g_delegate = [[JNINotificationsDelegate alloc] init];
        g_center = [UNUserNotificationCenter currentNotificationCenter];
        g_center.delegate = g_delegate;
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

    // Guard against OOM / invalid strings from JNI
    if ((title_cstr == NULL) || (message_cstr == NULL)) {
        if (title_cstr != NULL) {
            (*env)->ReleaseStringUTFChars(env, title, title_cstr);
        }
        if (message_cstr != NULL) {
            (*env)->ReleaseStringUTFChars(env, message, message_cstr);
        }
        return -1;
    }

    // Copy to C strings immediately so we can release JNI refs before async work
    char *title_copy = strdup(title_cstr);
    char *message_copy = strdup(message_cstr);

    (*env)->ReleaseStringUTFChars(env, title, title_cstr);
    (*env)->ReleaseStringUTFChars(env, message, message_cstr);

    if ((title_copy == NULL) || (message_copy == NULL)) {
        free(title_copy);
        free(message_copy);
        return -1;
    }

    @autoreleasepool {
        jninotifications_init_once();

        // Guard: not running inside a valid registered app bundle
        if (g_init_failed || g_center == nil) {
            free(title_copy);
            free(message_copy);
            return -1;
        }

        NSString *nsTitle = [NSString stringWithUTF8String:title_copy];
        NSString *nsMessage = [NSString stringWithUTF8String:message_copy];

        free(title_copy);
        free(message_copy);

        // Use cached center reference — never call currentNotificationCenter again
        UNUserNotificationCenter *center = g_center;

        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
            void (^deliverBlock)(void) = ^{
                UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                content.title = nsTitle;
                content.body = nsMessage;
                content.sound = [UNNotificationSound defaultSound];

                NSString *identifier = [[NSUUID UUID] UUIDString];
                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                      content:content
                                                                                      trigger:nil];

                [center addNotificationRequest:request withCompletionHandler:^(NSError *error) {
                    // Delivery is async; errors logged but not returned to JNI
                }];
            };

            switch (settings.authorizationStatus) {
                case UNAuthorizationStatusAuthorized:
                case UNAuthorizationStatusProvisional:
                    deliverBlock();
                    break;

                case UNAuthorizationStatusNotDetermined:
                    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                                          completionHandler:^(BOOL granted, NSError *error) {
                        if (granted) {
                            deliverBlock();
                        }
                    }];
                    break;

                case UNAuthorizationStatusDenied:
                default:
                    // User denied; nothing to do
                    break;
            }
        }];
    }

    // NSLog(@"jninotifications:Objective-C");

    return 0;
}
