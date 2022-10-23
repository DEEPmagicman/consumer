
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
    
    
    // Global Array
    
   // Events Array
   static var arrayTopEvents = [
        TopEventDataSet(imgEventCover: UIImage(named: "EventDetailsBG"), lblPerformerName: "Steve Aoki", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Tonight!", currentLiveEventFires: nil, isLive: true,location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel..."),
        TopEventDataSet(imgEventCover: UIImage(named: "TopEventBG2"), lblPerformerName: "Qrion", lblVenueName: "PRYSM Chicago", imgBrandLogo: UIImage(named: "TopEventBrandLogo2"), lblEventDate: "Friday, July 8", currentLiveEventFires: nil, isLive: false,location: "586 N. Dearborn St. Newyork", imgBrandLogoLarge:  UIImage(named: "PrysmLogoLarge"), lblSongName: "Your Love", lblSongArtist: "Qrion"),
        TopEventDataSet(imgEventCover: UIImage(named: "TopEventBG3"), lblPerformerName: "Worship Thursdays", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, July 21", currentLiveEventFires: nil, isLive: false,location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel...")
    ]
    
    // Featured Events Array
    static var arrayFeaturedEvents = [
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG1"), lblPerformerName: "Ferreck Dawn", lblVenueName: "SPYBAR CHICAGO",imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Saturday, June 18",location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "SpybarLogoLarge"), lblSongName: "Life", lblSongArtist: "Ferreck Dawn"),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG2"), lblPerformerName: "Valentino Khan", lblVenueName: "Soundbar", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Saturday, July 9",location: "586 N. Dearborn St. Newyork", imgBrandLogoLarge:  UIImage(named: "SoundbarLogoLarge"), lblSongName: "Pump", lblSongArtist: "Valentino Khan"),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG3"), lblPerformerName: "Nathan Scott", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, July 7",location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "The Heron", lblSongArtist: "Nathan Scott")
    ]
    
    // Upcomming Events Array
    static var arrayUpcomingEvents = [
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG1"), lblPerformerName: "NGHTMRE", lblVenueName: "TAO Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Saturday, July 2",location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "FEELING GUD", lblSongArtist: "NGHTMRE"),
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG2"), lblPerformerName: "Navic", lblVenueName: "Soundbar",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, June 7",location: "586 N. Dearborn St. Newyork", imgBrandLogoLarge:  UIImage(named: "SoundbarLogoLarge"), lblSongName: "2022 Rave", lblSongArtist: "Navic"),
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG3"), lblPerformerName: "DJ Daily", lblVenueName: "Bounce Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Friday, July 24",location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "BounceLogoLarge"), lblSongName: "Not in It", lblSongArtist: "DJ Daily")
    ]
    
    // General Admission Array
    static var arrayGeneralAdmission = [
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG1"), lblPerformerName: "TAO Fridays", lblVenueName: "TAO Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Friday, July 1",location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel..."),
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG2"), lblPerformerName: "Bonce Thrusdays", lblVenueName: "Bounce Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, June 7",location: "586 N. Dearborn St. Newyork", imgBrandLogoLarge:  UIImage(named: "BounceLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel..."),
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG3"), lblPerformerName: "Sundown Sundaze", lblVenueName: "PRYSM Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Sunday, July 3",location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "PrysmLogoLarge"), lblSongName: "The Business", lblSongArtist: "Tiesto")
    ]
    
    // Venue & VIP Array
    static var arrayHotVenueEvents = [
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG1"), lblPerformerName: "TAO Chicago", imgBrandLogo: UIImage(named:"VenueTao"), isLive: true, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 4:00 AM",location: "632 N. Dearborn St. chicago, IL",phoneNumber: "(224) 888-0388"),
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG2"), lblPerformerName: "The Underground", imgBrandLogo: UIImage(named:"HotVenueBrandLogo3"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 3:00 AM",location: "586 N. Dearborn St. Newyork",phoneNumber: "(224) 888-2345"),
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG3"), lblPerformerName: "Studio Paris", imgBrandLogo: UIImage(named:"HotVenueBrandLogo2"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 11:00 PM",location: "335 N. Dearborn St. California",phoneNumber: "(224) 888-576"),
    ]
    
    static var arrayRemainingHotVenueEvents = [
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenueRemainingBG1"), lblPerformerName: "Bounce Sporting Club", imgBrandLogo: UIImage(named:"HotVenueRemainingLogo1"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 2:00 AM",location: "335 N. Dearborn St. California",phoneNumber: "(224) 888-576"),
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenueRemainingBG2"), lblPerformerName: "PRYSM Chicago", imgBrandLogo: UIImage(named:"HotVenueRemainingLogo2"), isLive: true, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 4:00 AM",location: "586 N. Dearborn St. Newyork",phoneNumber: "(224) 888-2345"),
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenueRemainingBG3"), lblPerformerName: "RocBar", imgBrandLogo: UIImage(named:"HotVenueRemainingLogo3"), isLive: true, isFavourite: false, lblEventFees: "$35", lblEventWaitingTime: "15 mins", lblEventClosingTime: "Closes 3:00 AM",location: "632 N. Dearborn St. chicago, IL",phoneNumber: "(224) 888-0388"),
    ]
    
    // Attendees User Profile Array
    static var arrayAttendees = [
        AttendeeProfile(profileImgSmall: UIImage(named: "abby"), firstName: "Abby", fullName: "Abby S.", profileImgLarge: UIImage(named: "abbyLarge"), profession: "Consultant"),
        AttendeeProfile(profileImgSmall: UIImage(named: "you"), firstName: "Tamas", fullName: "Tamas A.", profileImgLarge: UIImage(named: "user1-others"), profession: "Software Engineer"),
        AttendeeProfile(profileImgSmall: UIImage(named: "annam"), firstName: "Anna", fullName: "Anna M.", profileImgLarge: UIImage(named: "annamLarge"), profession: "Nurse"),
        AttendeeProfile(profileImgSmall: UIImage(named: "conorm"), firstName: "Conor", fullName: "Conor M.G.", profileImgLarge: UIImage(named: "conormLarge"), profession: "UFC Fighter"),
        AttendeeProfile(profileImgSmall: UIImage(named: "danaw"), firstName: "Dana", fullName: "Dana W.", profileImgLarge: UIImage(named: "danawLarge"), profession: "President @ UFC"),
        AttendeeProfile(profileImgSmall: UIImage(named: "daves"), firstName: "Dave", fullName: "Dave S.", profileImgLarge: UIImage(named: "davesLarge"), profession: "CEO @ Goldman"),
        AttendeeProfile(profileImgSmall: UIImage(named: "gild"), firstName: "Gil", fullName: "Gil D.", profileImgLarge: UIImage(named: "gildLarge"), profession: "Real Estate Developer"),
        AttendeeProfile(profileImgSmall: UIImage(named: "gsp"), firstName: "Georges", fullName: "Georges S.P.", profileImgLarge: UIImage(named: "gspLarge"), profession: "Martial Artist"),
        AttendeeProfile(profileImgSmall: UIImage(named: "madisons"), firstName: "Madison", fullName: "Madison S.", profileImgLarge: UIImage(named: "madisonsLarge"), profession: "Lawyer"),
        AttendeeProfile(profileImgSmall: UIImage(named: "nguyenh"), firstName: "Hieu", fullName: "Hieu N.", profileImgLarge: UIImage(named: "nguyenhLarge"), profession: "Trader @ DSW"),
        AttendeeProfile(profileImgSmall: UIImage(named: "pauls"), firstName: "Paul", fullName: "Paul S.", profileImgLarge: UIImage(named: "paulsLarge"), profession: "Visionary"),
        AttendeeProfile(profileImgSmall: UIImage(named: "rachelj"), firstName: "Rachel", fullName: "Rachel J.", profileImgLarge: UIImage(named: "racheljLarge"), profession: "Museum Curator"),
        AttendeeProfile(profileImgSmall: UIImage(named: "raymondk"), firstName: "Raymond", fullName: "Raymond K.", profileImgLarge: UIImage(named: "raymondkLarge"), profession: "CEO @ McDonalds"),
        AttendeeProfile(profileImgSmall: UIImage(named: "rickieo"), firstName: "Rickie", fullName: "Rickie O.", profileImgLarge: UIImage(named: "rickieoLarge"), profession: "Comedian"),
        AttendeeProfile(profileImgSmall: UIImage(named: "robertm"), firstName: "Robert", fullName: "Robert M.", profileImgLarge: UIImage(named: "robertmLarge"), profession: "Businessman"),
        AttendeeProfile(profileImgSmall: UIImage(named: "virgils"), firstName: "Virgil", fullName: "Virgil S.", profileImgLarge: UIImage(named: "virgilsLarge"), profession: "Poker player"),
        AttendeeProfile(profileImgSmall: UIImage(named: "lilyp"), firstName: "Lily", fullName: "Lily P.", profileImgLarge: UIImage(named: "lilypLarge"), profession: "CMO @ Spekaeasy")
    ]
}
