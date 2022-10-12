//
//  ProjectEnums.swift
//  Quick Delivery
//
//  Created by macbook on 16/07/2019.
//  Copyright © 2019 Seller. All rights reserved.
//

import Foundation

enum HungaryNotification: String{
    case Push = "push"
    case Email = "email"
    case Both = "both"
}
enum AddCardFor {
    case AddCard
    case RechargeWallet
    case Order
}

enum NudgeStatus: String{
    case Started = "started"
    case AlmostThere = "almost there"
    case Done = "done"
}

//enum: ['started', 'almost there', 'done']
enum Receipt: String{
    case Push = "push"
    case Email = "email"
    case Both = "both"
}
enum NewMessage: String{
    case Push = "push"
    case Email = "email"
    case Both = "both"
}
enum LocalizationType: String{
    case EN = "en"
    case UR = "ur"
}
enum BookingType: String{
    case pending = "pending"
    case inProgress = "in-progress"
    case accepted = "accepted"
    case completed = "completed"
    case rejected = "rejected"
    case cancelled = "cancelled"
}
enum CMSType{
    case privacyPolicy
    case termsAndCondition
}
enum MileType: String{
    case pending = "pending"
    case inProgress = "in-progress"
    case arrived = "arrived"
    case departed = "departed"
    case completed = "completed"
}
enum MileStatusType: String{
    case pickUpArrived = "PICK_UP_ARRIVED"
    case pickUpDeparture = "PICK_UP_DEPARTED"
    case dropOffArrived = "DROP_OFF_ARRIVED"
    case dropOffDeparture = "DROP_OFF_DEPARTED"
}
enum isCommingFrom {
    case AddCard
    case RechargeWallet
}
enum ChatSenderType: String{
    case Customer = "customer"
    case Admin = "admin"
}
enum MessageType: String {
    case Text = "text"
    case Image = "image"
    case Video = "video"
    case Audio = "audio"
}
enum VerificationCodeType {
    case signUp
    case forgotPassword
}
enum CustomAlertType: String {
    case success = "Success"
    case error = "Error"
    case warning = "Warning"
}
enum CustomerAddressType {
    case DefaultDeliveryAddress
    case OrderDeliveryAddress
}
enum TipDriverOnPlaceOrderType {
    case JustPlaceOrder
    case TipDriver
}
enum PreferredPaymentMethodType: String {
    case SelectPaymentType = ""
    case CreditDebitCard = "Card"
    case CashOnDelivery = "Cash"
}
enum AdditionalPaymentMethodType: String {
    case EWallet = "EWallet"
    case Voucher = "Voucher"
}
enum CreditCardType: String {
    case MasterCard = "MasterCard"
    case JCB = "JCB"
    case UnionPay = "UnionPay"
    case Visa = "Visa"
}
enum NotificationStatusType: String {
    case OrderCompleted = "Order Completed"
}
enum OrderStatusType: String {
    case OrderCompleted = "Complete"
    case OrderPending = "Pending"
    case OrderAccepted = "Accept"
    case OrderCancelled = "Cancel"
}
enum PermissionAlertType:String {
    case Closed = "Closed"
    case Logout = "Logout"
    case Emoji = "Emoji"
}
enum NotificationsType: String{
    case NEW_MESSAGE_DRIVER = "NEW_MESSAGE_DRIVER"
    case NEW_MESSAGE_ADMIN = "NEW_MESSAGE_ADMIN"
    case ESTABLISHMENT_DRIVER_RETURN = "ESTABLISHMENT_DRIVER_RETURN"
    case CANCEL_FLOAT = "CANCEL_FLOAT"
    case ACCEPT_FLOAT = "ACCEPT_FLOAT"
    case ITEM_SOLD = "ITEM_SOLD"
    case DRIVER_REQUEST_TO_JOIN = "DRIVER_REQUEST_TO_JOIN"
    case ORDER_PLACED = "ORDER_PLACED"
    case ORDER_COMPLETED = "ORDER_COMPLETE"
    case ORDER_CANCEL = "ORDER_CANCEL"
    case DRIVER_AVAILABLE = "DRIVER_AVAILABLE"
    case DRIVER_UNAVAILABLE = "DRIVER_UNAVAILABLE"
    case ADMIN_APPROVAL = "ADMIN_APPROVAL"
    case SEND_MARKETING = "SEND_MARKETING"
    case ACCEPT_INTERVIEW_REQUEST = "ACCEPT_INTERVIEW_REQUEST"
    case MENU_ITEMS = "MENU_ITEMS"
    case CANCEL_DRIVER_REQUEST = "CANCEL_DRIVER_REQUEST"
    case ORDER_ACCEPT = "ORDER_ACCEPT"
    case EATER_RATING = "EATER_RATING"
    case DRIVER_LEFT = "DRIVER_LEFT"
    case NEW_MESSAGE_DRIVER_FROM_INTERVIEW = "NEW_MESSAGE_DRIVER_FROM_INTERVIEW"
    case REJECTED_BY_DRIVER = "REJECTED_BY_DRIVER"
    case REJECT_INTERVIEW_REQUEST = "REJECT_INTERVIEW_REQUEST"
    case DRIVER_ACCEPT_OFFER = "DRIVER_ACCEPT_OFFER"
    case REJECT_JOB_OFFER = "REJECT_JOB_OFFER"
    case AVAILABLE_NOW = "AVAILABLE_NOW"
    case SMART_ORDER = "SMART_ORDER"
    case REVIEW_AGENT_SERVICE = "REVIEW_AGENT_SERVICE"
    case NEW_REFUND_MESSAGE_ADMIN = "NEW_REFUND_MESSAGE_ADMIN"
    case REFUND_REQUEST = "REFUND_REQUEST"
}
enum RecordViewState {
    case Recording
    case None
}

enum SignUpType {
    case WithoutReferral
    case WithReferral
}

//enum EventType: String {
//   case INSTALL_TO_PURCHASE = "Install_To_Purchase"
//   case USER_IS_EATER = "User_Is_Eater"
//   case ADD_TO_CART = "Add_To_Cart"
//   case PURCHASED = "Purchased"
//   case NOT_PURCHASED = "Not_Purchased"
//   case AVERAGE_PURCHASE_VALUE = "Average_Purchase_Value"
//   case AVERAGE_PURCHASE_PER_ORDER = "Average_Purchased_Menu_Item_Per_Order"
//   case AVERAGE_ORDER_VALUE = "Average_Order_Value"
//   case PAYMENT_METHOD = "Payment_Method"
//
//}
enum AccountLinkWith: String {
    case Amazon = "Amazon"
    case Assistant = "Assistant"
}
enum RefundHistoryType: String {
    case Pending = "pending"
    case Completed = "completed"
}
enum RefundStatusType: String {
    case Pending = "pending"
    case InProgress = "in-progress"
    case Completed = "completed"
    case Denied = "denied"
}
enum PersonaVerificationType: String {
    case Completed = "completed"
}
enum CustomerType: String {
    case customer = "customer"
    case influencer = "influencer"
}
enum VenuePatronsDisplayType {
    case small
    case full
}
enum TableStatusType {
    case available
    case occupied
    case reserved
    case none
}
enum VacantTableStatusType {
    case current
    case edit
}
enum RewardType {
    case discountedCover
    case discountedEvent
    case discountedTable
    case customReward
    case none
}
enum NewEventDateType {
    case eventTime
    case expirationDate
}
enum OutstandingRequestFilterType {
    case thisWeek
    case allTime
    case custom
}
enum DisountType {
    case free
    case custom
    case none
}
enum FloorStatusType {
    case today
    case old
    case new
}
enum EventType {
    case generalAdmission
    case performance_DJSet
    case none
}
enum TicketConfigType {
    case add
    case edit
}
enum BookingStatusType: String {
    case PurchaseConfirmed = "Purchase Confirmed"
    case AwaitingApproval = "Awaiting Approval"
    case TicketPurchasedConfirmed = "Ticket purchased confirmed"
    case AwaitingVenueApproval = "Awaiting venue approval"
    case SubmitRequest = "Submit Request"
    case BookingConfirmation = "Booking Confirmation"
}
enum TicketRecipientsType {
    case MaleGeneral
    case FemaleGeneral
    case CompletePurchase
}

enum TicketConfirmationType {
    case FromBooking
    case FromHome
}

