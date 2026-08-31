import UIKit
import Alamofire

final class AppDelegate: NSObject, UIApplicationDelegate {
    private static let bind = "com.travelhel.per"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _ = Self.bind
        APIConfig.apply()
        UIWindow.appearance().backgroundColor = LedgerPalette.backgroundUI
        return true
    }
}
