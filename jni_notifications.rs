use jni::sys::jint;
use jni::JNIEnv;
use jni::objects::{JClass, JString};

const GLOBAL_VERSION_STRING: &'static str = "0.99.2-RS";

// This `#[no_mangle]` keeps rust from "mangling" the name and making it unique
// for this crate. The name follow a strict naming convention so that the
// JNI implementation will be able to automatically find the implementation
// of a native method based on its name.
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
    let ret: jint = 0;

    if (application.is_null()) || (title.is_null()) || (message.is_null()) {
        return -1;
    }

    let app_name: String = match env.get_string(&application) {
        Ok(v) => v.into(),
        Err(_) => return -1,
    };
    let summary: String = match env.get_string(&title) {
        Ok(v) => v.into(),
        Err(_) => return -1,
    };
    let body: String = match env.get_string(&message) {
        Ok(v) => v.into(),
        Err(_) => return -1,
    };

    // Init libnotify
    libnotify::init(&app_name).unwrap();
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
    n.show().unwrap();

    // We are done, deinit
    libnotify::uninit();

    ret
}
