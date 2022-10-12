import Foundation
import UIKit
import Alamofire
import SwiftyJSON

class UsersAPIManager: APIManagerBase {
    
    //MARK: LOGIN
    func Login(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.LOGIN.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: false)
    }
    //MARK: Logout
    func Logout(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.LOGOUT.rawValue)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: DeviceToken
    func DeviceToken(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.DEVICE_TOKEN.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: REGISTER
    func Register(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.REGISTER.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: false)
    }
    //MARK: ACCOUNT VERIFY
    func AccountVerify(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.ACCOUNT_VERIFY.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: false)
    }
    //MARK: FORGOT PASSWORD
    func ForgotPassword(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.FORGOT_PASSWORD.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: false)
    }
    //MARK: FORGOT VERIFY
    func ForgotVerify(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.FORGOT_VERIFY.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: false)
    }
    //MARK: FORGOT RESEND
    func ForgotResend(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.FORGOT_RESEND.rawValue)!
        self.putDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: false)
    }
    //MARK: VERIFICATION RESEND
    func VerificationResend(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.VERIFICATION_RESEND.rawValue)!
        self.putDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: false)
    }
    //MARK: TERM AND CONDITION
    func TermAndCondition(success: @escaping DefaultStringResultAPISuccesClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.TERM_AND_CONDITION.rawValue)!
        self.getStringResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: PRIVACY POLICY
    func PrivacyPolicy(success: @escaping DefaultStringResultAPISuccesClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.PRIVACY_POLICY.rawValue)!
        self.getStringResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: GET DRIVERS
    func Drivers(showLoader: Bool, params: Parameters,success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        if showLoader{ Utility.showLoader() }
        let route: URL = URLforRoute(route: Route.DRIVERS.rawValue, params: params)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: GET CART ITEMS
    func GetCartItems(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.CART_ITEMS.rawValue)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: ADD TO CART
    func AddToCartItem(showLoader: Bool,params: Parameters,success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        if showLoader { Utility.showLoader() } 
        let route: URL = POSTURLforRoute(route: Route.CART_ITEMS.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: GET ALLERGIES
    func GetAllergies(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.ALLERGIES.rawValue)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: GET INVITED USERS
    func GetInvitedUsers(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.INVITED_USERS.rawValue)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: NOTIFY USERS
    func NudgeUser(id: String,success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.NUDGE_USERS.rawValue+id)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Post ALLERGIES
    func postAllergies(showLoader: Bool, params: Parameters,success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        if showLoader {Utility.showLoader()}
        let route: URL = POSTURLforRoute(route: Route.ALLERGIES.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: UPDATE FORGOTTEN PASSWORD
    func UpdateForgottenPassword(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.UPDATE_FORGOTTEN_PASSWORD.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: CHANGE PASSWORD
    func changePassword(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.CHANGE_PASSWORD.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: USER NOTIFICATIONS
    func getUserNotification(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = URLforRoute(route: Route.USER_NOTIFICATIONS.rawValue, params: params)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: UNREAD NOTIFICATIONS COUNT
    func getNotificationCount(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.UNREAD_NOTIFICATIONS_COUNT.rawValue)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: CARD LIST
    func getCardList(success: @escaping DefaultArrayResultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.CARD_LIST.rawValue)! as URL
        self.getArrayResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: CUSTOMER WALLET
    func getCustomerWallet(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.CUSTOMER_WALLET.rawValue)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: CUSTOMER WALLET TRANSACTIONS
    func getCustomerWalletTransactions(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = URLforRoute(route: Route.CUSTOMER_TRANSACTIONS.rawValue, params: [:])! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: DELETE CARD
    func deleteCardWithID(id: String,success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.DELETE_CARD.rawValue+id)!
        self.deleteDictionaryResponseWith(route: route, parameters: [:], success: success, failure: failure, withHeader: true)
    }
    //MARK: Admin Previous Chat
    func adminChat(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = URLforRoute(route: Route.ADMIN_CHAT.rawValue, params: params)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Customer Send Message To Admin
    func customerSendMessageToAdmin(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTChatURLforRoute(route: Route.ADMIN_CHAT.rawValue)! as URL
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: UPDATE PROFILE IMAGE
    func UpdateProfileImage(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.PROFILE_IMAGE_UPDATE.rawValue)!
        self.postMultipartDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: UPDATE PROFILE
    func UpdateProfile(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.PROFILE.rawValue)!
        self.putDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: UPDATE CARD
    func MakeCardMarkDefault(id: String,success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.UPDATE_CARD_MAKE_DEFAULT.rawValue+id)!
        self.putDictionaryResponseWith(route: route, parameters: [:], success: success, failure: failure, withHeader: true)
    }
    //MARK: GET CUISINES
    func Cuisines(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.CUISINES.rawValue)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: false)
    }
    //MARK: GET TIPS
    func GetTips(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.TIPS.rawValue)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: POST CUISINES
    func postCuisines(showLoader: Bool, params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        if showLoader {Utility.showLoader()}
        let route: URL = POSTURLforRoute(route: Route.CUISINES.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: POST CARD
    func AddCard(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.Customers_ADD_CARD.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: POST RECHARGE WALLET
    func RechargeWallet(params: Parameters, success: @escaping DefaultDoubleResultAPISuccesClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.RECHARGE_WALLET.rawValue)!
        self.postDoubleResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: GET ORDER HISTORY
    func getOrderHistory(params: Parameters,success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = URLforRoute(route: Route.ORDER_HISTORY.rawValue, params: params)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: UPDATE PROFILE
    func notificationSettings(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.NOTIFICATION_SETTING.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: CUSTOMER_DELIVERY_ADDRESS
    func CustomerDeliveryAddress(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTChatURLforRoute(route: Route.CUSTOMER_DELIVERY_ADDRESS.rawValue)! as URL
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: ESTABLISHMENT PAYMENT METHOD
    func getEstablishmentPaymentMethods(id: String, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.ESTABLISHMENT_PAYMENT_METHOD.rawValue+id)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: PLACE Order
    func PlaceOrder(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTChatURLforRoute(route: Route.PLACE_ORDER.rawValue)! as URL
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: REVIEW YOUR DRIVER
    func reviewToDriver(id: String, params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.REVIEW_DRIVER.rawValue+id)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: GET CURRENT ORDER
    func GetCurrentOrder(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.CURRENT_ORDER.rawValue)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: CANCEL ORDER
    func cancelOrder(id: String, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.CANCEL_ORDER.rawValue+id)!
        self.postDictionaryResponseWith(route: route, parameters: [:], success: success, failure: failure, withHeader: true)
    }
    //MARK: CUISINE REMINDER
    func cuisineReminder(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.CUISINE_REMINDER.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: Order Previous Chat
    func orderChat(query: String, params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = URLforRoute(route: Route.ORDER_CHAT.rawValue+query, params: params)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Customer Send Message To Driver
    func customerSendMessageToDriver(query: String, params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTChatURLforRoute(route: Route.ORDER_CHAT.rawValue+query)! as URL
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: Is On Boarded
    func isOnBoarded(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.IS_ON_BOARDED.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: CountriesAndAreas
    func CountriesAndAreas(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.COUNTRIES_AREAS.rawValue)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: false)
    }
    //MARK: - UploadFile
    func UploadFile(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.FILE_UPLOAD.rawValue)!
        self.postMultipartDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: - UploadAudio
    func UploadAudio(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.FILE_UPLOAD.rawValue)!
        self.postMultipartAudioDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: - UploadFiles
    func UploadFiles(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.FILES_UPLOAD.rawValue)!
        self.postMultipartDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: UnreadCounts
    func UnreadCounts(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.UNREAD_COUNTS.rawValue)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Customer Order
    func CustomerOrder(id: String, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.CUSTOMER_ORDER.rawValue+id)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: GET GUEST DRIVERS
    func GuestDrivers(showLoader: Bool, params: Parameters,success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        if showLoader{ Utility.showLoader() }
        let route: URL = URLforRoute(route: Route.GUEST_DRIVERS.rawValue, params: params)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: false)
    }
    //MARK: CONNECT WITH AMAZON ASSISTANT
    func connectWithAmazonAssistant(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.CONNECT_WITH_AMAZON_ASSISTANT.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: DISCONNECT WITH AMAZON ASSISTANT
    func disconnectWithAmazonAssistant(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.DISCONNECT_WITH_AMAZON_ASSISTANT.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: Submit Refund Request
    func SubmitRefundRequest(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.ADD_REFUND.rawValue)!
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: Get Refund History
    func getRefundHistory(params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = URLforRoute(route: Route.REFUNDS_LIST.rawValue, params: params)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Get User Profile
    func getUserProfile(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.PROFILE.rawValue)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Refund Previous Chat
    func refundPreviousChat(query: String, params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = URLforRoute(route: Route.REFUNDS_CHAT.rawValue+query, params: params)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Customer Send Message To Refund Agent
    func customerSendMessageToRefundAgent(query: String, params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTChatURLforRoute(route: Route.REFUNDS_SEND_MESSAGE.rawValue+query)! as URL
        self.postDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: Get Vouchers
    func getVouchers(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.VOUCHERS.rawValue)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Get Influencer Earnings
    func getInfluencerEarnings(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.INFLUENCER_EARNINGS.rawValue)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Get Influencer Payout
    func getInfluencerPayout(success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.INFLUENCER_PAYOUT.rawValue)! as URL
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Review Agent
    func reviewAgent(query: String, params: Parameters, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.REFUND.rawValue+query)!
        self.putDictionaryResponseWith(route: route, parameters: params, success: success, failure: failure, withHeader: true)
    }
    //MARK: Refund Detail
    func RefundDetail(query: String, success: @escaping DefaultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        Utility.showLoader()
        let route: URL = POSTURLforRoute(route: Route.REFUND.rawValue+query)!
        self.getDictionaryResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
    //MARK: Pending Refund Chat Count
    func PendingRefundChatCount(success: @escaping DefaultArrayResultAPISuccessClosure, failure: @escaping DefaultAPIFailureClosure){
        let route: URL = POSTURLforRoute(route: Route.PENDING_REFUNDS_CHAT_COUNT.rawValue)!
        self.getArrayResponseWith(route: route, success: success, failure: failure, withHeader: true)
    }
}
