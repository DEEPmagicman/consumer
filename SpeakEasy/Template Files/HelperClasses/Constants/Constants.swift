
import Foundation
import UIKit

struct Global{
    static let LOGGED_IN_USER                = AppStateManager.sharedInstance.loggedInUser
    static var APP_MANAGER                   = AppStateManager.sharedInstance
    static var APP_REALM                     = APP_MANAGER.realm
    static let APP_COLOR                     = UIColor(red:29/255, green:29/255, blue:29/255, alpha:1.0)
    static let APP_COLOR_DISABLE             = UIColor(red:193/255, green:98/255, blue:115/255, alpha:1.0)
    static let APP_COLOR_DISABLE_TEXT        = UIColor(red:205/255, green:119/255, blue:128/255, alpha:1.0)
    static let APP_COLOR_DARK                = UIColor(red:185/255, green:13/255, blue:12/255, alpha:1.0)
    static let APP_COLOR_DARK_GREY           = UIColor(red:119/255, green:119/255, blue:119/255, alpha:1.0)
    static var APP_COLOR_GREY                = UIColor(red:49/255, green:49/255, blue:49/255, alpha:1.0)
    static var APP_COLOR_LIGHT_GREY          = UIColor(red:204/255, green:204/255, blue:204/255, alpha:1.0)
    static var APP_COLOR_BLUE                = UIColor(red:62/255, green:113/255, blue:210/255, alpha:1.0)
    static var APP_COLOR_GREEN               = UIColor(red:99/255, green:173/255, blue:52/255, alpha:1.0)
    static var APP_COLOR_DIM_PURPLE          = UIColor(red:46/255, green:32/255, blue:95/255, alpha:0.5)
    static var APP_COLOR_DIM_BLACK           = UIColor(red:0/255, green:0/255, blue:0/255, alpha:0.5)
    static var APP_COLOR_YELLOW              = UIColor(red:250/255, green:243/255, blue:128/255, alpha:1)
    static var APP_COLOR_GREY_GREEN          = UIColor(red:146/255, green:160/255, blue:158/255, alpha:1)
    static var APP_COLOR_DARK_BLUE           = UIColor(red:14/255, green:15/255, blue:132/255, alpha:1)
    static var APP_COLOR_DARK_PINK           = UIColor(red:220/255, green:68/255, blue:106/255, alpha:1)
    static var APP_COLOR_DARK_PURPLE         = UIColor(red:108/255, green:52/255, blue:154/255, alpha:1)
    static var APP_COLOR_LIGHT_PINK          = UIColor(red:237/255, green:185/255, blue:255/255, alpha:1)
    static var APP_COLOR_DIM_PINK            = UIColor(red:124/255, green:98/255, blue:138/255, alpha:1)
    static var APP_COLOR_CALENDAR_BG         = UIColor(red:27/255, green:27/255, blue:27/255, alpha:1)
    static var APP_COLOR_BUTTON_BORDER       = UIColor(red:84/255, green:84/255, blue:84/255, alpha:1)
    static var APP_COLOR_BUTTON_BORDER_DIM   = UIColor(red:40/255, green:40/255, blue:40/255, alpha:1)
    static var APP_COLOR_PINK                = UIColor(red:245/255, green:129/255, blue:254/255, alpha:1)
    static var APP_COLOR_GREY_LIGHT          = UIColor(red:143/255, green:143/255, blue:143/255, alpha:1)
}
//MARK: Base URL
struct Constants {
    //MARK:- Base URL
    
//    static let BaseURL                     = "http://192.168.0.178/api/v1"
//    static let BaseMessageSendingURL       = "http://192.168.0.178/api/v1"
//    static let BaseSocketChatURL           = "http://192.168.0.178/chat"
//    static let BaseSocketTrackingURL       = "http://192.168.0.178/tracking"
//
    static let BaseURL                   = "https://api.foodchoo.com/api/v1"
    static let BaseMessageSendingURL     = "https://api.foodchoo.com/api/v1"
    static let BaseSocketChatURL         = "https://api.foodchoo.com/chat"
    static let BaseSocketTrackingURL     = "https://api.foodchoo.com/tracking"
    
    static let BaseS3URL                   = "https://foodchooapp.s3.us-east-2.amazonaws.com/"
    static let chatNameSpace               = "/chat"
    static let trackingNameSpace           = "/tracking"
    
    static let APP_DELEGATE                = UIApplication.shared.delegate as! AppDelegate
    static let UIWINDOW                    = UIApplication.shared.delegate!.window!
    static let USER_DEFAULTS               = UserDefaults.standard
    static let SINGLETON                   = Singleton.sharedInstance
    static let DEFAULTS_USER_KEY           = "User"
    static var DeviceType                  = "ios"
    static var DeviceToken                 = "No certificates"
    static let serverDateFormat            = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    static let applicationDateFormat       = "MM/dd/yyyy"
    static let applicationMediumDateFormat = "EEEE, MMMM d"
    static let applicationTimeFormat       = "h:mm a"
    static let PAGINATION_PAGE_SIZE        = 20
    static let VERIFY_CODE_TIME_LIMIT      = 5*60
    static var adminPhone                  = "123456"
    static let apiKey                      = "AIzaSyA1b6fERg2kAB_sj_Qiq1M3rVNEQBsQFJw"
    static var apiMessage                  = ""
    static var accessToken                 = ""
    static var GoogleSignInClientID        = "809748310080-0mlsl24pgedskofhfmcqbgb5ksu4qgof.apps.googleusercontent.com"
    static var iTunesURL                   = "http://itunes.apple.com/us/lookup?bundleId="
    static var pagesCount                  = 0
    static var ordersCount                 = 0
    static let publishableKey              = "pk_test_51J2z3IRFnTSsDoMtXvQAuVpt6btuZ4v76dCcXjmb3PZtEl9uDSTofSYOmsUSAZLDKzt6jyU8cVz52uOTLp5fU7yV00GX4F5sqk"
    //"pk_test_97ITXRHK8xZovDEszT5vMx0f"
    static let biggestHeight:CGFloat       = 926.0
    static let imHungryTimeRange           = 20*60 //20 minutes
    static let CarouselScrollingSpeed      = 0.95
    static let templateId                  = "itmpl_U5EiAniKUzvefeUdFU7upMFv"
    static let currency                    = "$"
}
