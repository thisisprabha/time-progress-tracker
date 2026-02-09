import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register custom fonts
        FontHelper.registerFonts()
        
        // Create window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create SwiftUI view
        let appState = AppState()
        let contentView = ContentView()
            .environmentObject(appState)
        
        // Set root view controller
        window?.rootViewController = UIHostingController(rootView: contentView)
        window?.makeKeyAndVisible()
        
        return true
    }
}
