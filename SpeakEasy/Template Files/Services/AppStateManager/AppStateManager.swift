import Foundation
import UIKit
import RealmSwift

class AppStateManager: NSObject {
    
    static let sharedInstance = AppStateManager()
    var loggedInUser: UserModel?
    var realm: Realm!
    
    override init() {
        super.init()
        // Inside your application(application:didFinishLaunchingWithOptions:)
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 2,
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                }
            })
         
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        if (!(realm != nil)) {
            let configuration = Realm.Configuration(schemaVersion:1, deleteRealmIfMigrationNeeded: true)
            realm = try? Realm(configuration: configuration)
        }
        loggedInUser = realm.objects(UserModel.self).last
    }
    
    func isUserLoggedIn() -> Bool{
        if (self.loggedInUser) != nil {
            if self.loggedInUser?.isInvalidated ?? false {
                return false
            }
            return true
        }
        return false
    }
    func loginUser(user: UserModel) {
        try! Global.APP_REALM?.write(){
            AppStateManager.sharedInstance.loggedInUser = user
            Global.APP_REALM?.add(user, update: .all)
        }
        AppDelegate.shared.changeRootViewController()
//        AppDelegate.shared.registerDeviceToken()
    }
//    func logoutUser() {
//        Utility.main.showPermissionCustomAlert(alertType: .Logout, message: Strings.ASK_LOGOUT.text, YES: Strings.YES.text, NO: Strings.NO.text) { Yes, No in
//            if Yes {
//                Utility.main.topViewController()?.dismiss(animated: true, completion: {
//                    self.processLogoutUser()
//                })
//            }
//            else{
//                Utility.main.topViewController()?.dismiss(animated: true, completion: nil)
//            }
//        }
//    }
//    func logoutGuestUser(){
//        Utility.main.showPermissionCustomAlert(alertType: .Emoji, message: Strings.ASK_GUEST_LOGOUT.text, YES: Strings.LOGIN.text, NO: Strings.CANCEL.text) { Yes, No in
//            if Yes {
//                Utility.main.topViewController()?.dismiss(animated: true, completion: {
//                    self.logoutUserAndChangeRootView()
//                })
//            }
//            else{
//                Utility.main.topViewController()?.dismiss(animated: true, completion: nil)
//            }
//        }
//    }
    func logoutUserOnly(){
        try! Global.APP_REALM?.write() {
            Global.APP_REALM?.deleteAll()
            
            self.deleteUser()
        }
    }
    func logoutUserAndChangeRootView(){
        try! Global.APP_REALM?.write() {
            Global.APP_REALM?.deleteAll()
            self.deleteUser()
            AppDelegate.shared.changeRootViewController()
        }
    }
    func saveUser(user:UserModel) {
        try! Global.APP_REALM?.write(){
            AppStateManager.sharedInstance.loggedInUser = user
            Global.APP_REALM?.add(user, update: .all)
        }
    }
    
    private func deleteUser(){
        self.loggedInUser = nil
        Constants.accessToken = ""
//        AppDelegate.shared.notificationCount = 0
    }
}
extension AppStateManager{
    private func processLogoutUser(){
        APIManager.sharedInstance.usersAPIManager.Logout(success: { (responseObject) in
            try! Global.APP_REALM?.write() {
                Global.APP_REALM?.deleteAll()
                
                self.deleteUser()
            }
            UserDefaults.standard.set(false, forKey: "imHungryStatus")
//            AppDelegate.shared.changeRootViewController(withSplash: true)
        }) { (error) in
            print(error)
        }
    }
}
