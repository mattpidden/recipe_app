import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller = window?.rootViewController as? FlutterViewController
    if let controller = controller {
      let channel = FlutterMethodChannel(name: "share_bridge", binaryMessenger: controller.binaryMessenger)

      channel.setMethodCallHandler { call, result in
        let appGroupId = "group.com.mattpidden.recipeapp"
        let sharedKey = "shared_text_or_url"
        let defaults = UserDefaults(suiteName: appGroupId)

        switch call.method {
        case "getShared":
          result(defaults?.string(forKey: sharedKey))
        case "clearShared":
          defaults?.removeObject(forKey: sharedKey)
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
