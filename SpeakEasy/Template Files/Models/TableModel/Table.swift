//
//  Table.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 17/02/26.
//

import Foundation

enum BookingType: String, Codable {
    case `default` = "DEFAULT"
    case timeWise = "TIME_WISE"
}

struct SeatingAreaResponse: Codable {
    let total: Int?
    let list: [SeatingArea]?
    let hasMany: Bool?
    let count: Int?
}

struct SeatingArea: Codable {
    let id: String?
    let parentSeatingAreaId: String?
    let eventId: String?
    let venueId: String?
    let order: Int?

    let name: String?
    let highlight: String?
    let minimum: Double?
    let deposit: Double?
    let maxGuest: Int?
    let defaultGuest: Int?
    let description: String?

    let issuedInternalInventory: Int?
    let issuedPublicInventory: Int?
    let soldInternalInventory: Int?
    let soldPublicInventory: Int?
    let inCartPublicInventory: Int?

    let bookingType: BookingType?
    let minExtraPersons: Int?
    let extraPersonCharge: Double?
    let depositType: String?

    let beginSale: String?
    let endSale: String?
    let type: String?

    let inquiryEnabled: Bool?
    let hideCheckout: Bool?
    let hidePricing: Bool?
    let isDeleted: Bool?
    let status: String?

    let createdAt: String?
    let updatedAt: String?

    let timeSlots: [TableTimeSlot]?
    let depositWithFees: Double?
    let additionalFees: Double?
}

struct FeesSettings: Codable {
    var speakeasyFeePerc: Double?
    var speakeasyFeeFlat: Double?
    
    var isEnableSalesTax: Bool?
    var salesTax: Double?
    var salesTaxName: String?
    
    var isProcessingFeePassToCustomer: Bool?
    var isProcessingFeeTaxable: Bool?
    
    var stripePerc: Double?
    var stripeFlat: Double?
    
    var customFees: [CustomFee]?
    
    var isEnableGratuity: Bool?
    var gratuityFee: Double?
    var gratuityFeeType: String?
    var isGratuityFeeTaxable: Bool?
}

struct TableTimeSlot: Codable {
    let id: String?
    let startTime: String?
    let endTime: String?
    let minimum: Double?
    let deposit: Double?
    let depositType: String?
    let extraPersonCharge: Double?
    let depositWithFees: Double?

    let issuedPublicInventory: Int?
    let soldPublicInventory: Int?
}

struct SeatingAreaBookingResponse: Codable {
    let id: String
    let eventId: String
    let venueId: String
    let status: String
    let items: [BookingItem]
    let createdAt: Int64
    let clientIp: String?
    let position: Int
    let approxWait: Int
    let isSuccess: Bool
    let message: String?
    let content: QueueInnerContent?
}

struct BookingItem: Codable {
    let seatingAreaId: String
    let guests: Int
    let calculatedMinimum: Double?
    let calculatedDeposit: Double?
    let extraGuests: Int?
    let timeSlotId: String?
    let timeSlot: TableTimeSlot?

}

struct QueueInnerContent: Codable {
    let clientSecret: String?
    let ephemeralKey: String?
    let paymentHistoryId: String?
    let tableBooking: TableBooking?
}

struct TableBooking: Codable {
    let id: String
    let venueId: String
    let paymentIntent: String?
    let paymentId: String?
    let bookingSourceType: String?
    let bookingSource: String?
    let paymentStatus: String?
    let isDeleted: Bool?
    let createdAt: String
    let updatedAt: String
    let notes: String?
    let eventPromoCodeId: String?
    let spendAgreement: PriceBreakdown?
    let tableBookingPriceBreakdown: PriceBreakdown?
}

struct PriceBreakdown: Codable {

    let id: String?
    let base: Double?
    let discount: Double?
    let gratuity: Double?
    let gratuityName: String?
    let salesTax: Double?
    let salesTaxName: String?
    let seFees: Double?
    let stripeFees: Double?
    let total: Double?
    let tableBookingPriceBreakdownHasCustomFees: [TableCustomFee]?
    let customFees: [TableCustomFee]?
    let balanceDueAtVenue: Double?

    enum CodingKeys: String, CodingKey {
        case id, base, discount, gratuity, gratuityName, salesTax, salesTaxName
        case seFees, stripeFees, total
        case tableBookingPriceBreakdownHasCustomFees, customFees, balanceDueAtVenue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try? container.decode(String.self, forKey: .id)

        base = try container.decodeFlexibleDouble(forKey: .base)
        discount = try container.decodeFlexibleDouble(forKey: .discount)
        gratuity = try container.decodeFlexibleDouble(forKey: .gratuity)
        salesTax = try container.decodeFlexibleDouble(forKey: .salesTax)
        seFees = try container.decodeFlexibleDouble(forKey: .seFees)

        stripeFees = try container.decodeFlexibleDouble(forKey: .stripeFees)
        total = try container.decodeFlexibleDouble(forKey: .total)
        balanceDueAtVenue = try container.decodeFlexibleDouble(forKey: .balanceDueAtVenue)

        gratuityName = try? container.decode(String.self, forKey: .gratuityName)
        salesTaxName = try? container.decode(String.self, forKey: .salesTaxName)

        tableBookingPriceBreakdownHasCustomFees =
            try? container.decode([TableCustomFee].self,
                                  forKey: .tableBookingPriceBreakdownHasCustomFees)
        customFees = try? container.decode([TableCustomFee].self, forKey: .customFees)
    }
}

struct TableCustomFee: Codable {
    let id: String?
    let name: String?
    let fee: Double?
    let customFeeName: String?
    let customFee: Double?
    let createdAt: String?
    let tableBookingPriceBreakdownId: String?

    enum CodingKeys: String, CodingKey {
        case id, name, fee, customFeeName, customFee, createdAt, tableBookingPriceBreakdownId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try? container.decode(String.self, forKey: .id)
        name = try? container.decode(String.self, forKey: .name)
        fee = try container.decodeFlexibleDouble(forKey: .fee)
        customFeeName = try? container.decode(String.self, forKey: .customFeeName)
        customFee = try container.decodeFlexibleDouble(forKey: .customFee)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        tableBookingPriceBreakdownId =
            try? container.decode(String.self, forKey: .tableBookingPriceBreakdownId)
    }
}

struct QueueSocketResponse: Codable {
    let content: SeatingAreaBookingResponse
}

struct ConsumerLayoutResponse: Codable {
    let id: String?
    let venueId: String?
    let isDefault: Bool?
    let isDeleted: Bool?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
    let layoutHistories: [LayoutHistory]?
}

// MARK: - LayoutTableHistory
struct LayoutHistory: Codable {
    let id: String?
    let layoutId: String?
    let name: String?
    let url3dMap: String?
    let totalTables: Int?
    let createdAt: String?
    let layoutHistoryHas3DMaps: [Layout3DMap]?

    enum CodingKeys: String, CodingKey {
        case id
        case layoutId
        case name
        case url3dMap
        case totalTables
        case createdAt
        case layoutHistoryHas3DMaps
    }
}

struct Layout3DMap: Codable {
    let id: String?
    let layoutHistoryId: String?
    let name: String?
    let url3dMap: String?
    let metadata: String?

    let xPosition: Double?
    let yPosition: Double?
    let zPosition: Double?

    let fieldOfView: Double?
    let verticalRotationMin: Double?
    let verticalRotationMax: Double?
    let horizontalRotationMin: Double?
    let horizontalRotationMax: Double?

    let zoomMin: Double?
    let zoomMax: Double?
    let ratio: Double?

    let order: Int?
    let isDeleted: Bool?
    let status: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, layoutHistoryId, name, metadata
        case url3dMap = "url3dMap"
        case xPosition, yPosition, zPosition
        case fieldOfView
        case verticalRotationMin, verticalRotationMax
        case horizontalRotationMin, horizontalRotationMax
        case zoomMin, zoomMax, ratio
        case order, isDeleted, status, createdAt
    }
}
struct TableBookingConfirmResponse: Codable {
    let reservations: [Reservation]
    let tableBooking: ConfirmedTableBooking?
}

struct Reservation: Codable {
    let id: String?
    let uniqueId: String?
    let venueId: String?
    let date: String?
    let guests: ReservationGuests?
    let guestsTotal: Int?
    let minimumType: String?
    let comps: Double?
    let compsType: String?
    let minimum: Double?
    let time: String?
    let confirmationSMS: Bool?
    let note: String?
    let cancelNote: String?
    let bookedByType: String?
    let venueUserId: String?
    let microsEmployeeId: String?
    let assignedToUserId: String?
    let assignedToAt: String?
    let seatingArea: String?
    let seatingArrangementId: String?
    let timeSlotId: String?
    let extraPersons: Int?
    let seatedAt: String?
    let checkInAt: String?
//    let checkInGuests: Int?
    let reservationStatus: String?
    let isDeleted: Bool?
    let paymentStatus: String?
    let isAnyPaylinkRefunded: Bool?
    let paidPaylinkAmount: Double?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
    let posChecks: String?
    let tableBookingId: String?
    let lastMessage: String?
    let lastMessageAt: String?
    let isReadLastMessage: Bool?
    let lastMessageService: String?
    let totalSpend: Double?
    let requiredPayment: Bool?
    let sendReservationReminder: Bool?
    let subTotalSpend: Double?
    let timeSlot: TableTimeSlot?
    let tableBooking: ConfirmedTableBooking?
    let venue: ClipVenue?
    let event: Event?
    let consumerUserHasBooking: [ConsumerUserBooking]?
    let seatingArrangement: ReservationSeatingArrangement?
}

struct ReservationGuests: Codable {
    let male: Int?
    let total: Int?
    let female: Int?
}

struct ConsumerUserBooking: Codable {
    let id: String?
    let uniqueId: String?
    let firstName: String?
    let lastName: String?
    let gender: String?
    let dob: String?
    let birthYear: String?
    let birthDay: String?
    let birthMonth: String?
    let email: String?
    let receiveNotification: Bool?
    let instagramUserId: String?
    let linkedIn: String?
    let faceRecognitionConsent: Bool?
    let consumerState: String?
    let code: String?
    let phone: String?
    let phoneVerified: Bool?
    let timezone: String?
    let status: String?
    let isSocial: Bool?
    let isDeleted: Bool?
    let isProfileCompleted: Bool?
    let lastLogin: String?
    let createdAt: String?
    let updatedAt: String?
    let stripeCustId: String?
    let consumerUserTempPhoneId: String?
    let consumerUserTempEmailId: String?
    let consumerUserResetPasswordDataId: String?
    let consumerUserInvitationDataId: String?
    let consumerUserImageId: String?
    let consumerUserMongodbId: String?
    let appclipUserMongodbId: String?
    let firstNameLastName: String?
    let lastNameFirstName: String?
    let fullPhoneNumber: String?
    let consumerUserImage: ConsumerUserImage?
}

struct ConsumerUserImage: Codable {
    let id: String?
    let key: String?
    let name: String?
    let description: String?
}

struct ReservationSeatingArrangement: Codable {
    let eventId: String?
}

struct ConfirmedTableBooking: Codable {
    let id: String?
    let venueId: String?
    let notes: String?
    let paymentIntent: String?
    let paymentId: String?
    let bookingSourceType: String?
    let bookingSource: String?
    let paymentStatus: String?
    let isDeleted: Bool?
    let createdAt: String?
    let updatedAt: String?
    let eventPromoCodeId: String?
    let promotionLinkId: String?
    let isMigrated: Bool?
    let spendAgreement: PriceBreakdown?
    let reservations: [Reservation]?
    let tableBookingDetails: TableBookingDetails?
    let tableBookingHasItems: [TableBookingItem]?
    let tableBookingPriceBreakdown: PriceBreakdown?
}

struct TableBookingDetails: Codable {
    let id: String?
    let tableBookingId: String?
    let tableBookingSettings: TableBookingSettings?
    let ip: String?
    let holder: String?
    let comapny: String?
    let type: String?
    let card: String?
}

struct TableBookingSettings: Codable {
    var id: String?
    
    var isUpFront: Bool?
    var isProcessingFeePassToCustomer: Bool?
    
    var isEnableSalesTax: Bool?
    var salesTaxName: String?
    var salesTax: Double?
    
    var isEnableCustomFee: Bool?
    var customFees: [TableSettingCustomFee]?
    var salesTaxes: [TableSettingSalesTax]?
    
    var isEnableGratuity: Bool?
    var gratuityFeeType: String?
    var gratuityFeeName: String?
    var gratuityFee: Double?
    var isGratuityTaxable: Bool?
    
    var isProcessingFeeTaxable: Bool?
    
    var stripePerc: Double?
    var stripeFlat: Double?
    
    var speakeasyFeeFlat: Double?
    var speakeasyFeePerc: Double?
    
    var gratuityFeeRange: String?
}

struct SpendAgreementSettings: Codable {
    var id: String?
    
    var isUpFront: Bool?
    var isProcessingFeePassToCustomer: Bool?
    
    var isEnableSalesTax: Bool?
    var salesTaxName: String?
    var salesTax: Double?
    
    var isEnableCustomFee: Bool?
    var customFees: [TableSettingCustomFee]?
    var salesTaxes: [TableSettingSalesTax]?
    
    var isEnableGratuity: Bool?
    var gratuityFeeType: String?
    var gratuityFeeName: String?
    var gratuityFee: Double?
    var isGratuityTaxable: Bool?
    
    var isProcessingFeeTaxable: Bool?
    
    var stripePerc: Double?
    var stripeFlat: Double?
    
    var speakeasyFeeFlat: Double?
    var speakeasyFeePerc: Double?
    
    var gratuityFeeRange: String?
}

struct TableSettingCustomFee: Codable {
    var customFee: Double?
    var customFeeName: String?
    var customFeeType: String?
    var isEnableCustomFee: Bool?
    var isCustomFeeTaxable: Bool?
}

struct TableSettingSalesTax: Codable {
    var id: String?
    var salesTax: Double?
    var salesTaxName: String?
    var isEnableSalesTax: Bool?
}

struct BookingCustomFeeSetting: Codable {
    let customFee: Double?
    let customFeeName: String?
    let customFeeType: String?
    let isEnableCustomFee: Bool?
    let isCustomFeeTaxable: Bool?
}

struct TableBookingItem: Codable {
    let id: String?
    let tableBookingId: String?
    let seatingAreaId: String?
    let isDeleted: Bool?
    let createdAt: String?
    let updatedAt: String?
}


extension KeyedDecodingContainer {

    func decodeFlexibleDouble(forKey key: KeyedDecodingContainer<K>.Key) throws -> Double? {

        if let value = try? self.decodeIfPresent(Double.self, forKey: key) {
            return value
        }

        if let value = try? self.decodeIfPresent(Int.self, forKey: key) {
            return Double(value)
        }

        if let value = try? self.decodeIfPresent(String.self, forKey: key),
           let doubleValue = Double(value) {
            return doubleValue
        }

        return nil
    }
}
