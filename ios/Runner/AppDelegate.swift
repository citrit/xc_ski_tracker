import UIKit
import Flutter
import GoogleMaps
    
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyDaPv6_DyIkij4lfO7Blc8VxjqY3g7iASE")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
