//
//  AppDelegate.swift
//  MacBryte
//
//  Created by Rahul Aggarwal on 2021-06-05.
//

import Cocoa
import Network
import UserNotifications
import ServiceManagement

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    @IBOutlet weak var openMainWindowButton: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {        
        setStatusItemImage(to: Constants.menuBarIconInternetGood)
        
        if (Constants.enviornment == "develop") {
            removeUserDefaults()
        }
        
        statusItem.button?.target = self
        statusItem.button?.action = #selector(showPopup)
        
        NotificationHandler.shared.getNotificationAuthorization() // Get authorization. This prevents bug where first notification does not send
        
        UNUserNotificationCenter.current().delegate = self
        
        RouterConnectionService.shared.startMeasuring()
        InternetConnectionService.shared.startMeasuring()
        
        // Auto-reopen
        let launcherAppId = "com.macbryte.LauncherApplication"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty

        SMLoginItemSetEnabled(launcherAppId as CFString, true)

        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        self.reopenWindow()
        
        return true
    }
    
    @objc func showPopup() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        guard let vc = storyboard.instantiateController(withIdentifier: "dropdownViewController") as? NSViewController else {
            fatalError(Constants.viewControllerFindFailed)
        }

        guard let button = statusItem.button else {
            fatalError(Constants.statusItemFindFailed)
        }

        let popoverView = NSPopover()
        popoverView.contentViewController = vc
        
        // when user clicks away popup will close itself
        popoverView.behavior = .transient
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        popoverView.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY) // show popup "relative" to menu item icon
    }
    
    func setStatusItemImage(to image: String) {
        let itemImage = NSImage(named: image)
        statusItem.button?.image = itemImage
    }
    
    @IBAction func openMainMenuButtonClicked(_ sender: Any) {
        self.reopenWindow()
    }
    
    func reopenWindow() {
        for window in NSApplication.shared.windows {
            // Ensures we have a windowController
            if(window.windowController != nil && window.windowController?.contentViewController != nil && window.className != "NSStatusBarWindow") {
                    
                let storyboard = NSStoryboard(name: "Main", bundle: nil) // Get storyboard
                
                // Set defualt value for our view
                var contentController: NSViewController = storyboard.instantiateController(withIdentifier: "authenticationTabViewController") as! NSTabViewController
                
                // Get actual view we need to display
                if (UserDefaults.standard.string(forKey: Constants.userIdStorageKey) != nil && UserDefaults.standard.bool(forKey: Constants.userIsAdminStorageKey)) {
                    contentController
                        = storyboard.instantiateController(withIdentifier: "adminViewController") as! NSViewController
                } else if (UserDefaults.standard.string(forKey: Constants.userIdStorageKey) != nil) {
                    contentController = storyboard.instantiateController(withIdentifier: "accountViewController") as! NSViewController
                }
                
                window.windowController?.contentViewController = contentController // Set view value
                
                window.makeKeyAndOrderFront(self) // Display view
            }
        }
    }
    
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        return completionHandler([.list, .sound])
    }
}

