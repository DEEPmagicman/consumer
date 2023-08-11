
import UIKit

struct Global{
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
//    static let BaseURL                   = "https://api.foodchoo.com/api/v1"
//    static let BaseMessageSendingURL     = "https://api.foodchoo.com/api/v1"
//    static let BaseSocketChatURL         = "https://api.foodchoo.com/chat"
//    static let BaseSocketTrackingURL     = "https://api.foodchoo.com/tracking"
    
//    static let BaseS3URL                   = "https://foodchooapp.s3.us-east-2.amazonaws.com/"
//    static let chatNameSpace               = "/chat"
//    static let trackingNameSpace           = "/tracking"
    
//    static let APP_DELEGATE                = UIApplication.shared.delegate as! AppDelegate
//    static let UIWINDOW                    = UIApplication.shared.delegate!.window!
//    static let USER_DEFAULTS               = UserDefaults.standard
//    static let SINGLETON                   = Singleton.sharedInstance
//    static let DEFAULTS_USER_KEY           = "User"
//    static var DeviceType                  = "ios"
//    static var DeviceToken                 = "No certificates"
//    static let serverDateFormat            = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
//    static let applicationDateFormat       = "MM/dd/yyyy"
//    static let applicationMediumDateFormat = "EEEE, MMMM d"
//    static let applicationTimeFormat       = "h:mm a"
//    static let PAGINATION_PAGE_SIZE        = 20
//    static let VERIFY_CODE_TIME_LIMIT      = 5*60
//    static var adminPhone                  = "123456"
    static let apiKey                      = "AIzaSyA1b6fERg2kAB_sj_Qiq1M3rVNEQBsQFJw"
//    static var apiMessage                  = ""
//    static var accessToken                 = ""
//    static var GoogleSignInClientID        = "809748310080-0mlsl24pgedskofhfmcqbgb5ksu4qgof.apps.googleusercontent.com"
//    static var iTunesURL                   = "http://itunes.apple.com/us/lookup?bundleId="
//    static var pagesCount                  = 0
//    static var ordersCount                 = 0
//    static let biggestHeight:CGFloat       = 926.0
//    static let imHungryTimeRange           = 20*60 //20 minutes
//    static let CarouselScrollingSpeed      = 0.95
//    static let templateId                  = "itmpl_U5EiAniKUzvefeUdFU7upMFv"
    static let currency                    = "$"
    
    
    // Global Array
    // Set Cleveland by default
    static var localizedCity = "Cleveland"
    static var localizedMap = "Miami, FL"
    
   // Events Array Chicago
   static var arrayTopEventsChicago = [
        TopEventDataSet(imgEventCover: UIImage(named: "EventDetailsBG"), lblPerformerName: "Steve Aoki", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Tonight!", currentLiveEventFires: nil, isLive: true,location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel..."),
        TopEventDataSet(imgEventCover: UIImage(named: "TopEventBG2"), lblPerformerName: "Qrion", lblVenueName: "PRYSM Chicago", imgBrandLogo: UIImage(named: "TopEventBrandLogo2"), lblEventDate: "Friday, July 8", currentLiveEventFires: nil, isLive: false,location: "586 N. Dearborn St. Newyork", imgBrandLogoLarge:  UIImage(named: "PrysmLogoLarge"), lblSongName: "Your Love", lblSongArtist: "Qrion"),
        TopEventDataSet(imgEventCover: UIImage(named: "TopEventBG3"), lblPerformerName: "Worship Thursdays", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, July 21", currentLiveEventFires: nil, isLive: false,location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel...")
    ]
    // Events Array Cleveland
    static var arrayTopEventsCleveland = [
         TopEventDataSet(imgEventCover: UIImage(named: "deadmau5"), lblPerformerName: "Deadmau5", lblVenueName: "FWD Day+Nightclub", imgBrandLogo: UIImage(named: "fwdLogo"), lblEventDate: "Tonight!", currentLiveEventFires: nil, isLive: true,location: "1176 Front Ave. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "fwdLogoLarge"), lblSongName: "Escape", lblSongArtist: "Deadmau5"),
         TopEventDataSet(imgEventCover: UIImage(named: "imanbek"), lblPerformerName: "Imanbek", lblVenueName: "FWD Day+Nightclub", imgBrandLogo: UIImage(named: "fwdLogo"), lblEventDate: "Saturday, September 10", currentLiveEventFires: nil, isLive: false,location: "1176 Front Ave. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "fwdLogoLarge"), lblSongName: "Belly Dancer", lblSongArtist: "Imanbek"),
         TopEventDataSet(imgEventCover: UIImage(named: "djPaulyD"), lblPerformerName: "DJ Pauly D", lblVenueName: "FWD Day+Nightclub", imgBrandLogo: UIImage(named: "fwdLogo"), lblEventDate: "Friday, August 26", currentLiveEventFires: nil, isLive: false,location: "1176 Front Ave. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "fwdLogoLarge"), lblSongName: "Back To Love", lblSongArtist: "DJ Pauly D")
     ]
    
    
    // Featured Events Array Chicago
    static var arrayFeaturedEventsChicago = [
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG1"), lblPerformerName: "Ferreck Dawn", lblVenueName: "SPYBAR CHICAGO",imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Saturday, June 18",location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "SpybarLogoLarge"), lblSongName: "Life", lblSongArtist: "Ferreck Dawn"),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG2"), lblPerformerName: "Valentino Khan", lblVenueName: "Soundbar", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Saturday, July 9",location: "586 N. Dearborn St. Newyork", imgBrandLogoLarge:  UIImage(named: "SoundbarLogoLarge"), lblSongName: "Pump", lblSongArtist: "Valentino Khan"),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG3"), lblPerformerName: "Nathan Scott", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, July 7",location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "The Heron", lblSongArtist: "Nathan Scott")
    ]
    // Featured Events Array Cleveland
    static var arrayFeaturedEventsCleveland = [
        TopEventDataSet(imgEventCover: UIImage(named: "duttonRanch"), lblPerformerName: "Dutton Ranch", lblVenueName: "Welcome to the Farm",imgBrandLogo: UIImage(named: "welcomeFarmLogo"), lblEventDate: "Friday, October 28",location: "1054 Old River Rd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "welcomeFarmLogoLarge"), lblSongName: "Country Girl", lblSongArtist: "Luke Bryan"),
        TopEventDataSet(imgEventCover: UIImage(named: "jakeDodds"), lblPerformerName: "Jake Dodds", lblVenueName: "Welcome to the Farm", imgBrandLogo: UIImage(named: "welcomeFarmLogo"), lblEventDate: "Saturday, July 9",location: "1054 Old River Rd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "welcomeFarmLogoLarge"), lblSongName: "American Night", lblSongArtist: "Jake Dodds"),
        TopEventDataSet(imgEventCover: UIImage(named: "mikeD"), lblPerformerName: "Mike D", lblVenueName: "The Ivy", imgBrandLogo: UIImage(named: "ivyLogo"), lblEventDate: "Thursday, November 3",location: "1212 W 6th St. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "ivyLogoLarge"), lblSongName: "That's a Bet", lblSongArtist: "God of Texas, Mike D")
    ]
    
    // Upcomming Events Array Chicago
    static var arrayUpcomingEventsChicago = [
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG1"), lblPerformerName: "NGHTMRE", lblVenueName: "TAO Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Saturday, July 2",location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "FEELING GUD", lblSongArtist: "NGHTMRE"),
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG2"), lblPerformerName: "Navic", lblVenueName: "Soundbar",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, June 7",location: "586 N. Dearborn St. Newyork", imgBrandLogoLarge:  UIImage(named: "SoundbarLogoLarge"), lblSongName: "2022 Rave", lblSongArtist: "Navic"),
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG3"), lblPerformerName: "DJ Daily", lblVenueName: "Bounce Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Friday, July 24",location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "BounceLogoLarge"), lblSongName: "Not in It", lblSongArtist: "DJ Daily")
    ]
    // Upcomming Events Array Cleveland
    static var arrayUpcomingEventsCleveland = [
        TopEventDataSet(imgEventCover: UIImage(named: "dalton"), lblPerformerName: "Dalton & Sheriffs", lblVenueName: "Welcome to the Farm",  imgBrandLogo: UIImage(named: "welcomeFarmLogo"), lblEventDate: "Saturday, October 15",location: "1054 Old River Rd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "welcomeFarmLogoLarge"), lblSongName: "Boston", lblSongArtist: "Dalton & the Sheriffs"),
        TopEventDataSet(imgEventCover: UIImage(named: "gameFive"), lblPerformerName: "Game 5 Watch Party", lblVenueName: "Good Night John Boy",  imgBrandLogo: UIImage(named: "johnBoyLogo"), lblEventDate: "Friday, October 28",location: "1167 Front Ave. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "johnBoyLogoLarge"), lblSongName: "Boston", lblSongArtist: "Dalton & the Sheriffs"),
        TopEventDataSet(imgEventCover: UIImage(named: "frankViera"), lblPerformerName: "Frank Vieira", lblVenueName: "Welcome to the Farm",  imgBrandLogo: UIImage(named: "welcomeFarmLogo"), lblEventDate: "Friday, October 21",location: "1054 Old River Rd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "welcomeFarmLogoLarge"), lblSongName: "Heart Broke", lblSongArtist: "Frank Vieira"),
        TopEventDataSet(imgEventCover: UIImage(named: "djMike"), lblPerformerName: "DJ Mike Filly", lblVenueName: "Twist Social Club",  imgBrandLogo: UIImage(named: "twistLogo"), lblEventDate: "Saturday, October 29",location: "11633 Clifton Blvd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "twistLogoLarge"), lblSongName: "Filly Mix", lblSongArtist: "DJ Mike Filly")
    ]
    
    // General Admission Array Chicago
    static var arrayGeneralAdmissionChicago = [
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG1"), lblPerformerName: "TAO Fridays", lblVenueName: "TAO Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Friday, July 1",location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel..."),
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG2"), lblPerformerName: "Bounce Thrusdays", lblVenueName: "Bounce Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, June 7",location: "586 N. Dearborn St. NewYork", imgBrandLogoLarge:  UIImage(named: "BounceLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel..."),
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG3"), lblPerformerName: "Sundown Sundaze", lblVenueName: "PRYSM Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Sunday, July 3",location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "PrysmLogoLarge"), lblSongName: "The Business", lblSongArtist: "Tiesto")
    ]
    // General Admission Array Cleveland
    static var arrayGeneralAdmissionCleveland = [
        TopEventDataSet(imgEventCover: UIImage(named: "gaFwd"), lblPerformerName: "FWD Saturdays", lblVenueName: "FWD Day+Nightclub",  imgBrandLogo: UIImage(named: "fwdLogo"), lblEventDate: "Saturday, October 29",location: "1176 Front Ave. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "fwdLogoLarge"), lblSongName: "Escape", lblSongArtist: "Deadmau5"),
        TopEventDataSet(imgEventCover: UIImage(named: "gaIvy"), lblPerformerName: "Ivy Fridays", lblVenueName: "The Ivy",  imgBrandLogo: UIImage(named: "ivyLogo"), lblEventDate: "Friday, October 28",location: "1212 W 6th St. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "ivyLogoLarge"), lblSongName: "That's a Bet", lblSongArtist: "God of Texas, Mike D"),
        TopEventDataSet(imgEventCover: UIImage(named: "gaTwist"), lblPerformerName: "Twist Fridays", lblVenueName: "Bounce Chicago",  imgBrandLogo: UIImage(named: "twistLogo"), lblEventDate: "Friday, October 28",location: "11633 Clifton Blvd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "twistLogoLarge"), lblSongName: "Filly Mix", lblSongArtist: "DJ Mike Filly")
    ]
    
    // Venue descriptions
    static var taoDescription = "TAO Chicago is an award-winning temple of nightlife in Chicago, featuring the hottest open format DJs, world-class performers, and A-list celebrities. TAO nightclub has been host to many of the city’s most memorable parties. Every Friday and Saturday incredible DJs headline the club, packing the dance floor."
    static var undergroundDescription = "The Underground is an award-winning temple of nightlife in Chicago, featuring the hottest open format DJs, world-class performers, and A-list celebrities. The Underground has been host to many of the city’s most memorable parties. Every Friday and Saturday incredible DJs headline the club, packing the dance floor."
    static var studioDescription = "Studio Paris is an award-winning temple of nightlife in Chicago, featuring the hottest open format DJs, world-class performers, and A-list celebrities. Studio Paris has been host to many of the city’s most memorable parties. Every Friday and Saturday incredible DJs headline the club, packing the dance floor."
    static var bounceDescription = "Bounce Sporting Club is an award-winning temple of nightlife in Chicago, featuring the hottest open format DJs, world-class performers, and A-list celebrities. Bounce Sporting Club has been host to many of the city’s most memorable parties. Every Friday and Saturday incredible DJs headline the club, packing the dance floor."
    static var prysmDescription = "Prysm is an award-winning temple of nightlife in Chicago, featuring the hottest open format DJs, world-class performers, and A-list celebrities. Prysm has been host to many of the city’s most memorable parties. Every Friday and Saturday incredible DJs headline the club, packing the dance floor."
    static var rocbarDescription = "RocBar is an award-winning temple of nightlife in Chicago, featuring the hottest open format DJs, world-class performers, and A-list celebrities. RocBar has been host to many of the city’s most memorable parties. Every Friday and Saturday incredible DJs headline the club, packing the dance floor."
    //Cleveland
    static var fwdDescription = "FWD Nightclub is Cleveland’s premier outdoor club. An experience unlike anything else in the country, nights at FWD are an open air party driven by our roster of world class artists and DJs set to a backdrop of Cleveland’s skyline, barges in the adjacent Cuyahoga river, and rattling of trains on the nearby tracks."
    static var ivyDescription = "The Ivy is Cleveland’s place to gather and features internationally inspired dining and signature cocktail menu that transitionally caters to the Warehouse District neighborhood and downtown Cleveland residents and professionals."
    static var twistDescription = "Twist Social Club is a neighborhood bar and night club focused on serving the LGBT community of greater Cleveland."
    static var johnDescription = "Cleveland's most unique nightlife destination. Funk 1970's era dive bar with dancing, pizza, cool beer, sports, and groovy vibes."
    static var farmDescription = "Cleveland's Live Music Bar from Chase Rice and Forward Hospitality Group in Flats East bank."
    
    // Hours
    static var taoHours = [
        HoursDataSet(day: "Thursday", time: "10:00 PM - 3:00 AM"),
        HoursDataSet(day: "Friday", time: "10:00 PM -       LATE"),
        HoursDataSet(day: "Saturday", time: "10:00 PM -       LATE")
    ]
    static var undergroundHours = [
        HoursDataSet(day: "Wednesday", time: "11:00 PM - 4:00 AM"),
        HoursDataSet(day: "Thursday", time: "10:00 PM - 4:00 AM"),
        HoursDataSet(day: "Friday", time: "10:00 PM - 4:00 AM"),
        HoursDataSet(day: "Saturday", time: "10:00 PM - 5:00 AM")
    ]
    static var studioHours = [
        HoursDataSet(day: "Saturday", time: "10:00 PM - 3:00 AM")
    ]
    static var bounceHours = [
        HoursDataSet(day: "Monday", time: "4:00 PM - 11:00 PM"),
        HoursDataSet(day: "Tuesday", time: "4:00 PM - 11:00 PM"),
        HoursDataSet(day: "Wednesday", time: "4:00 PM - 2:00 AM"),
        HoursDataSet(day: "Thursday", time: "4:00 PM - 2:00 AM"),
        HoursDataSet(day: "Friday", time: "4:00 PM - 2:00 AM"),
        HoursDataSet(day: "Saturday", time: "11:00 AM - 3:00 AM"),
        HoursDataSet(day: "Sunday", time: "11:00 AM - 2:00 AM")
    ]
    static var prysmHours = [
        HoursDataSet(day: "Monday", time: "10:00 PM - 4:00 AM"),
        HoursDataSet(day: "Wednesday", time: "10:00 PM - 4:00 AM"),
        HoursDataSet(day: "Friday", time: "10:00 PM - 4:00 AM"),
        HoursDataSet(day: "Saturday", time: "10:00 PM - 5:00 AM"),
        HoursDataSet(day: "Sunday", time: "10:00 PM - 4:00 AM")
    ]
    static var rocbarHours = [
        HoursDataSet(day: "Tuesday", time: "12:00 AM - 4:00 AM"),
        HoursDataSet(day: "Thursday", time: "10:00 PM - 4:00 AM"),
        HoursDataSet(day: "Friday", time: "10:00 PM - 4:00 AM"),
        HoursDataSet(day: "Saturday", time: "10:00 PM - 5:00 AM")
    ]
    static var fwdHours = [
        HoursDataSet(day: "Saturday", time: "9:30 PM - 2:00 AM")
    ]
    static var ivyHours = [
        HoursDataSet(day: "Thursday", time: "3:00 PM - 2:30 AM"),
        HoursDataSet(day: "Friday", time: "10:00 AM - 2:30 AM"),
        HoursDataSet(day: "Saturday", time: "10:00 AM - 2:30 AM")
    ]
    static var twistHours = [
        HoursDataSet(day: "Thursday", time: "3:00 PM - 2:30 AM"),
        HoursDataSet(day: "Friday", time: "10:00 AM - 2:30 AM"),
        HoursDataSet(day: "Saturday", time: "10:00 AM - 2:30 AM")
    ]
    static var johnHours = [
        HoursDataSet(day: "Thursday", time: "6:00 PM - LATE"),
        HoursDataSet(day: "Friday", time: "8:30 PM - LATE"),
        HoursDataSet(day: "Saturday", time: "12:00 PM - LATE")
    ]
    static var farmHours = [
        HoursDataSet(day: "Thursday", time: "4:00 PM - 11:00 PM"),
        HoursDataSet(day: "Friday", time: "4:00 PM - 2:00 AM"),
        HoursDataSet(day: "Saturday", time: "12:00 PM - 2:00 AM")
    ]
    
    static var undergroundEvent = TopEventDataSet(imgEventCover: UIImage(named: "undergroundHan"), lblPerformerName: "Mista Han", lblVenueName: "The Underground",  imgBrandLogo: UIImage(named: "HotVenueBrandLogo3"), lblEventDate: "Friday, October 28")
    static var parisEvent = TopEventDataSet(imgEventCover: UIImage(named: "parisPauly"), lblPerformerName: "DJ Pauly D", lblVenueName: "Studio Paris",  imgBrandLogo: UIImage(named: "HotVenueBrandLogo2"), lblEventDate: "Saturday, October 22")
    // Venue & VIP Array Chicago
    static var arrayHotVenueEventsChicago = [
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG1"), lblPerformerName: "TAO Chicago", imgBrandLogo: UIImage(named:"VenueTao"), isLive: true, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 4:00 AM",location: "632 N. Dearborn St. chicago, IL",phoneNumber: "(224) 888-0388", upcomingEvents: [arrayTopEventsChicago[0], arrayFeaturedEventsChicago[2], arrayUpcomingEventsChicago[0], arrayGeneralAdmissionChicago[0]], description: taoDescription, hours: taoHours),
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG2"), lblPerformerName: "The Underground", imgBrandLogo: UIImage(named:"HotVenueBrandLogo3"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 3:00 AM",location: "586 N. Dearborn St. Newyork",phoneNumber: "(224) 888-2345", upcomingEvents: [undergroundEvent], description: undergroundDescription, hours: undergroundHours),
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG3"), lblPerformerName: "Studio Paris", imgBrandLogo: UIImage(named:"HotVenueBrandLogo2"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 11:00 PM",location: "335 N. Dearborn St. California",phoneNumber: "(224) 888-576", upcomingEvents: [parisEvent], description: studioDescription, hours: studioHours)
    ]
    
    // Venue & VIP Array Cleveland
    static var arrayHotVenueEventsCleveland = [
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"fwd"), lblPerformerName: "FWD Day+Nightclub", imgBrandLogo: UIImage(named:"fwdLogo"), isLive: true, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 4:00 AM",location: "1176 Front Ave. Cleveland, OH",phoneNumber: "(216) 990-2300", upcomingEvents: [arrayTopEventsCleveland[0], arrayTopEventsCleveland[1], arrayTopEventsCleveland[2], arrayGeneralAdmissionCleveland[0]], description: fwdDescription, hours: fwdHours),
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"ivy"), lblPerformerName: "The Ivy", imgBrandLogo: UIImage(named:"ivyLogo"), isLive: true, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 2:30 AM",location: "1212 W 6th St. Cleveland, OH",phoneNumber: "(216) 505-5510", upcomingEvents: [arrayFeaturedEventsCleveland[2], arrayGeneralAdmissionCleveland[1]], description: ivyDescription, hours: ivyHours),
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"twist"), lblPerformerName: "Twist Social Club", imgBrandLogo: UIImage(named:"twistLogo"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 3:00 AM",location: "11633 Clifton Blvd, Cleveland, OH",phoneNumber: "(216) 221-2333", upcomingEvents: [arrayUpcomingEventsCleveland[2], arrayGeneralAdmissionCleveland[2]], description: twistDescription, hours: twistHours)
    ]
    
    static var rocbarEvent = TopEventDataSet(imgEventCover: UIImage(named: "RocbarNavic"), lblPerformerName: "Maximo x Navic", lblVenueName: "RocBar",  imgBrandLogo: UIImage(named: "HotVenueRemainingLogo3"), lblEventDate: "Friday, October 21")
    
    static var arrayRemainingHotVenueEventsChicago = [
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenueRemainingBG1"), lblPerformerName: "Bounce Sporting Club", imgBrandLogo: UIImage(named:"HotVenueRemainingLogo1"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 2:00 AM",location: "335 N. Dearborn St. California",phoneNumber: "(224) 888-576", upcomingEvents: [arrayUpcomingEventsChicago[2], arrayGeneralAdmissionChicago[1]], description: bounceDescription, hours: bounceHours),
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenueRemainingBG2"), lblPerformerName: "PRYSM Chicago", imgBrandLogo: UIImage(named:"HotVenueRemainingLogo2"), isLive: true, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 4:00 AM",location: "586 N. Dearborn St. Newyork",phoneNumber: "(224) 888-2345", upcomingEvents: [arrayTopEventsChicago[1], arrayGeneralAdmissionChicago[2]], description: prysmDescription, hours: prysmHours),
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenueRemainingBG3"), lblPerformerName: "RocBar", imgBrandLogo: UIImage(named:"HotVenueRemainingLogo3"), isLive: true, isFavourite: false, lblEventFees: "$35", lblEventWaitingTime: "15 mins", lblEventClosingTime: "Closes 3:00 AM",location: "632 N. Dearborn St. chicago, IL",phoneNumber: "(224) 888-0388", upcomingEvents: [rocbarEvent], description: rocbarDescription, hours: rocbarHours)
    ]
    
    static var arrayRemainingHotVenueEventsCleveland = [
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"johnBoy"), lblPerformerName: "Good Night John Boy", imgBrandLogo: UIImage(named:"johnboyLogo"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 2:00 AM",location: "1167 Front Ave. Cleveland, OH",phoneNumber: "(216) 440-3500", upcomingEvents: [arrayUpcomingEventsCleveland[1]], description: johnDescription, hours: johnHours),
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"welcomeFarm"), lblPerformerName: "Welcome to the Farm", imgBrandLogo: UIImage(named:"welcomeFarmLogo"), isLive: true, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 4:00 AM",location: "1054 Old River Rd. Cleveland, OH",phoneNumber: "(216) 399-9079", upcomingEvents: [arrayFeaturedEventsCleveland[0], arrayFeaturedEventsCleveland[1], arrayUpcomingEventsCleveland[0], arrayUpcomingEventsCleveland[1]], description: farmDescription, hours: farmHours)
    ]
    
    // See All Array Chicago and Cleveland
    static var arrayAllEventsChicago = [
        TopEventDataSet(imgEventCover: UIImage(named: "EventDetailsBG"), lblPerformerName: "Steve Aoki", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Tonight!", currentLiveEventFires: nil, isLive: true,location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel..."),
        TopEventDataSet(imgEventCover: UIImage(named: "TopEventBG2"), lblPerformerName: "Qrion", lblVenueName: "PRYSM Chicago", imgBrandLogo: UIImage(named: "TopEventBrandLogo2"), lblEventDate: "Friday, July 8", currentLiveEventFires: nil, isLive: false,location: "586 N. Dearborn St. Newyork", imgBrandLogoLarge:  UIImage(named: "PrysmLogoLarge"), lblSongName: "Your Love", lblSongArtist: "Qrion"),
        TopEventDataSet(imgEventCover: UIImage(named: "TopEventBG3"), lblPerformerName: "Worship Thursdays", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, July 21", currentLiveEventFires: nil, isLive: false,location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel..."),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG1"), lblPerformerName: "Ferreck Dawn", lblVenueName: "SPYBAR CHICAGO",imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Saturday, June 18",location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "SpybarLogoLarge"), lblSongName: "Life", lblSongArtist: "Ferreck Dawn"),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG2"), lblPerformerName: "Valentino Khan", lblVenueName: "Soundbar", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Saturday, July 9",location: "586 N. Dearborn St. Newyork", imgBrandLogoLarge:  UIImage(named: "SoundbarLogoLarge"), lblSongName: "Pump", lblSongArtist: "Valentino Khan"),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG3"), lblPerformerName: "Nathan Scott", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, July 7",location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "The Heron", lblSongArtist: "Nathan Scott"),
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG1"), lblPerformerName: "NGHTMRE", lblVenueName: "TAO Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Saturday, July 2",location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "FEELING GUD", lblSongArtist: "NGHTMRE"),
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG2"), lblPerformerName: "Navic", lblVenueName: "Soundbar",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, June 7",location: "586 N. Dearborn St. Newyork", imgBrandLogoLarge:  UIImage(named: "SoundbarLogoLarge"), lblSongName: "2022 Rave", lblSongArtist: "Navic"),
        TopEventDataSet(imgEventCover: UIImage(named: "UpcomingEventsBG3"), lblPerformerName: "DJ Daily", lblVenueName: "Bounce Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Friday, July 24",location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "BounceLogoLarge"), lblSongName: "Not in It", lblSongArtist: "DJ Daily"),
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG1"), lblPerformerName: "TAO Fridays", lblVenueName: "TAO Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Friday, July 1",location: "632 N. Dearborn St. chicago, IL", imgBrandLogoLarge:  UIImage(named: "TaoLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel..."),
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG2"), lblPerformerName: "Bounce Thrusdays", lblVenueName: "Bounce Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, June 7",location: "586 N. Dearborn St. NewYork", imgBrandLogoLarge:  UIImage(named: "BounceLogoLarge"), lblSongName: "Nataaoki", lblSongArtist: "Steve Aoki, Nathaniel..."),
        TopEventDataSet(imgEventCover: UIImage(named: "GeneralAdmissionBG3"), lblPerformerName: "Sundown Sundaze", lblVenueName: "PRYSM Chicago",  imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Sunday, July 3",location: "335 N. Dearborn St. California", imgBrandLogoLarge:  UIImage(named: "PrysmLogoLarge"), lblSongName: "The Business", lblSongArtist: "Tiesto")
    ]
    
    static var arrayAllEventsCleveland = [
        TopEventDataSet(imgEventCover: UIImage(named: "deadmau5"), lblPerformerName: "Deadmau5", lblVenueName: "FWD Day+Nightclub", imgBrandLogo: UIImage(named: "fwdLogo"), lblEventDate: "Tonight!", currentLiveEventFires: nil, isLive: true,location: "1176 Front Ave. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "fwdLogoLarge"), lblSongName: "Escape", lblSongArtist: "Deadmau5"),
        TopEventDataSet(imgEventCover: UIImage(named: "imanbek"), lblPerformerName: "Imanbek", lblVenueName: "FWD Day+Nightclub", imgBrandLogo: UIImage(named: "fwdLogo"), lblEventDate: "Saturday, September 10", currentLiveEventFires: nil, isLive: false,location: "1176 Front Ave. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "fwdLogoLarge"), lblSongName: "Belly Dancer", lblSongArtist: "Imanbek"),
        TopEventDataSet(imgEventCover: UIImage(named: "djPaulyD"), lblPerformerName: "DJ Pauly D", lblVenueName: "FWD Day+Nightclub", imgBrandLogo: UIImage(named: "fwdLogo"), lblEventDate: "Friday, August 26", currentLiveEventFires: nil, isLive: false,location: "1176 Front Ave. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "fwdLogoLarge"), lblSongName: "Back To Love", lblSongArtist: "DJ Pauly D"),
        TopEventDataSet(imgEventCover: UIImage(named: "duttonRanch"), lblPerformerName: "Dutton Ranch", lblVenueName: "Welcome to the Farm",imgBrandLogo: UIImage(named: "welcomeFarmLogo"), lblEventDate: "Friday, October 28",location: "1054 Old River Rd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "welcomeFarmLogoLarge"), lblSongName: "Country Girl", lblSongArtist: "Luke Bryan"),
        TopEventDataSet(imgEventCover: UIImage(named: "jakeDodds"), lblPerformerName: "Jake Dodds", lblVenueName: "Welcome to the Farm", imgBrandLogo: UIImage(named: "welcomeFarmLogo"), lblEventDate: "Saturday, July 9",location: "1054 Old River Rd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "welcomeFarmLogoLarge"), lblSongName: "American Night", lblSongArtist: "Jake Dodds"),
        TopEventDataSet(imgEventCover: UIImage(named: "mikeD"), lblPerformerName: "Mike D", lblVenueName: "The Ivy", imgBrandLogo: UIImage(named: "ivyLogo"), lblEventDate: "Thursday, November 3",location: "1212 W 6th St. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "ivyLogoLarge"), lblSongName: "That's a Bet", lblSongArtist: "God of Texas, Mike D"),
        TopEventDataSet(imgEventCover: UIImage(named: "dalton"), lblPerformerName: "Dalton & Sheriffs", lblVenueName: "Welcome to the Farm",  imgBrandLogo: UIImage(named: "welcomeFarmLogo"), lblEventDate: "Saturday, October 15",location: "1054 Old River Rd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "welcomeFarmLogoLarge"), lblSongName: "Boston", lblSongArtist: "Dalton & the Sheriffs"),
        TopEventDataSet(imgEventCover: UIImage(named: "gameFive"), lblPerformerName: "Game 5 Watch Party", lblVenueName: "Good Night John Boy",  imgBrandLogo: UIImage(named: "johnBoyLogo"), lblEventDate: "Friday, October 28",location: "1167 Front Ave. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "johnBoyLogoLarge"), lblSongName: "Boston", lblSongArtist: "Dalton & the Sheriffs"),
        TopEventDataSet(imgEventCover: UIImage(named: "frankViera"), lblPerformerName: "Frank Vieira", lblVenueName: "Welcome to the Farm",  imgBrandLogo: UIImage(named: "welcomeFarmLogo"), lblEventDate: "Friday, October 21",location: "1054 Old River Rd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "welcomeFarmLogoLarge"), lblSongName: "Heart Broke", lblSongArtist: "Frank Vieira"),
        TopEventDataSet(imgEventCover: UIImage(named: "djMike"), lblPerformerName: "DJ Mike Filly", lblVenueName: "Twist Social Club",  imgBrandLogo: UIImage(named: "twistLogo"), lblEventDate: "Saturday, October 29",location: "11633 Clifton Blvd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "twistLogoLarge"), lblSongName: "Filly Mix", lblSongArtist: "DJ Mike Filly"),
        TopEventDataSet(imgEventCover: UIImage(named: "gaFwd"), lblPerformerName: "FWD Saturdays", lblVenueName: "FWD Day+Nightclub",  imgBrandLogo: UIImage(named: "fwdLogo"), lblEventDate: "Saturday, October 29",location: "1176 Front Ave. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "fwdLogoLarge"), lblSongName: "Escape", lblSongArtist: "Deadmau5"),
        TopEventDataSet(imgEventCover: UIImage(named: "gaIvy"), lblPerformerName: "Ivy Fridays", lblVenueName: "The Ivy",  imgBrandLogo: UIImage(named: "ivyLogo"), lblEventDate: "Friday, October 28",location: "1212 W 6th St. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "ivyLogoLarge"), lblSongName: "That's a Bet", lblSongArtist: "God of Texas, Mike D"),
        TopEventDataSet(imgEventCover: UIImage(named: "gaTwist"), lblPerformerName: "Twist Fridays", lblVenueName: "Bounce Chicago",  imgBrandLogo: UIImage(named: "twistLogo"), lblEventDate: "Friday, October 28",location: "11633 Clifton Blvd. Cleveland, OH", imgBrandLogoLarge:  UIImage(named: "twistLogoLarge"), lblSongName: "Filly Mix", lblSongArtist: "DJ Mike Filly")
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
