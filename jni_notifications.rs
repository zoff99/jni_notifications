const GLOBAL_VERSION_STRING: &'static str = "0.99.2-RS";

use jni::JNIEnv;
use jni::objects::{JClass, JString};
use jni::sys::jint;

#[no_mangle]
pub extern "system" fn Java_com_zoffcc_applications_jninotifications_NTFYActivity_jninotifications_1version<'local>(
    env: JNIEnv<'local>,
    _class: JClass<'local>,
) -> JString<'local> {
    env.new_string(GLOBAL_VERSION_STRING)
        .expect("Couldn't create java string!")
}

#[no_mangle]
pub extern "system" fn Java_com_zoffcc_applications_jninotifications_NTFYActivity_jninotifications_1notify<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    application: JString<'local>,
    title: JString<'local>,
    message: JString<'local>,
    icon_filename_fullpath: JString<'local>,
) -> jint {
    if application.is_null() {
        eprintln!("JString application was null!");
        return -1;
    }
    if title.is_null() {
        eprintln!("JString title was null!");
        return -1;
    }
    if message.is_null() {
        eprintln!("JString message was null!");
        return -1;
    }

    let app_name: String = match env.get_string(&application) {
        Ok(v) => v.into(),
        Err(e) => {
            eprintln!("couldn't read JString application! {e}");
            return -1;
        }
    };
    let summary: String = match env.get_string(&title) {
        Ok(v) => v.into(),
        Err(e) => {
            eprintln!("couldn't read JString title! {e}");
            return -1;
        }
    };
    let body: String = match env.get_string(&message) {
        Ok(v) => v.into(),
        Err(e) => {
            eprintln!("couldn't read JString message! {e}");
            return -1;
        }
    };

    let mut ret = 0;

    // Init libnotify
    if let Err(e) = libnotify::init(&app_name) {
        eprintln!("libnotify::init failed! {e}");
        ret = -3;
    }

    let n: libnotify::Notification;

    if !icon_filename_fullpath.is_null() {
        let icon: String = match env.get_string(&icon_filename_fullpath) {
            Ok(v) => v.into(),
            Err(_) => return -1,
        };
        n = libnotify::Notification::new(&summary, Some(body.as_str()), Some(icon.as_str()));
    } else {
        n = libnotify::Notification::new(&summary, Some(body.as_str()), None);
    }

    // Show the notification
    if let Err(e) = n.show() {
        eprintln!("libnotify::Notification::show failed! {e}");
        ret = -2;
    }

    // We are done, deinit
    libnotify::uninit();

    ret
}
