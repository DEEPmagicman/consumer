//
//  ClipVenue.swift
//  SpeakEasyClip
//
//  Created by Square Infosoft on 03/02/23.
//

import Foundation

struct ClipVenue: Codable {

    var logo: LogoClip?
    var bookingCode: String?
    var venueAttachment: [VenueAttachmentClip]?
    var venueHours: [VenueHoursClip]?
    var id: Int
    var uniqueId: String
    var name: String
    var address: String
    var dressCode: String?
    var city: String
    var pinCode: String?
    var code: String
    var phone: String
    var website: String
    var description: String?
    var status: String
    var bookingStatus: String?
    var venueVibes: [String]
    var isDeleted: Bool
    var isEnabledGenderBasedTicket: Bool?
    var createdAt: String
    var updatedAt: String
    var bookingWaiting: String?
    var lat: String
    var lng: String
    var appClipTicket: [AppClipTicket]?
    var checkInUser: Int?
    var timezone: String?
    var venueSettings: VenueSettings?
    var allowCC: Bool?
    var availableTimeSlot: Bool?
    var speakEasyCharges: String?
    var event: [Event]?
    // MARK: app side parameters
    var latitude: Double {
        Double(lat) ?? 0.0
    }
    var longitude: Double {
        Double(lng) ?? 0.0
    }
    var displayWaitTime: String {
        if let waitTime = bookingWaiting {
            if waitTime.contains("mins") || waitTime.contains("Hour") {
                return "\(waitTime.replacingOccurrences(of: "mins", with: "Minute")) Wait"
            } else {
                return waitTime
            }
        } else {
            return ""
        }
    }
    var openHours: [VenueHoursClip] {
        venueHours?.filter({ $0.venueStatus == "OPEN" }) ?? []
    }
    var lowestPriceTicket: AppClipTicket? {
        var filterTickets = appClipTicket?.filter({ $0.status == "ENABLED" })
        if venueSettings?.coverTicketFeesSettings?.isUpFront == true {
            filterTickets = modifiedAppClipTicket.filter({ $0.status == "ENABLED" && $0.isCustom != true })
            if let customTicket = appClipTicket?.first(where: { $0.status == "ENABLED" && $0.isCustom == true }) {
                filterTickets?.append(customTicket)
            }
        }
        let lowest = filterTickets?.min(by: { LHS, RHS in
            LHS.price < RHS.price
        })
        return lowest
    }
    
    var modifiedAppClipTicket: [AppClipTicket] {
        var ticketData = [AppClipTicket]()
        appClipTicket?.enumerated().forEach({ index, ticket in
            ticketData.append(ticket)
            
            if ticket.price < 2 {
                return
            }
            
            var taxRate = 0.0
            if venueSettings?.coverTicketFeesSettings?.isEnableSalesTax == true {
                taxRate = (venueSettings?.coverTicketFeesSettings?.salesTax ?? 0) / 100
            }
            
            var totalCustomFee = 0.0
            if venueSettings?.coverTicketFeesSettings?.isEnableCustomFee == true {
                if venueSettings?.coverTicketFeesSettings?.customFeeType == "PERCENTAGE" {
                    totalCustomFee = (ticketData[index].price * (venueSettings?.coverTicketFeesSettings?.customFee ?? 0) / 100)
                } else {
                    totalCustomFee = (venueSettings?.coverTicketFeesSettings?.customFee ?? 0)
                }
            }
            
            var totalProcessingFee = 0.0
            if venueSettings?.coverTicketFeesSettings?.isProcessingFeePassToCustomer == true {
                let stripeFee = (0.029 * (1 + taxRate) * (ticket.price + SEFee(ticket.price, ticketName: ticket.name) + totalCustomFee ) + 0.3) / (1 - (1 + taxRate) * 0.029)
                totalProcessingFee = stripeFee + SEFee(ticket.price, ticketName: ticket.name)
            }
            
            var salesTax = 0.0
            if venueSettings?.coverTicketFeesSettings?.isEnableSalesTax == true {
                salesTax = (ticket.price + totalProcessingFee + totalCustomFee) * taxRate
            }
            
            let amountChargedToConsumer = ticket.price + totalProcessingFee + totalCustomFee + salesTax
            ticketData[index].price = round(amountChargedToConsumer * 100) / 100
        })
        return ticketData
    }
    
    var useTimezone: String {
        timezone?.capitalized ?? ""
    }
    
    func SEFee(_ ticketPrice: Double, ticketName: String) -> Double {
        var amountTransferToSE = 0.0
        if speakEasyCharges == "SAME_PRICE" {
            amountTransferToSE = 1
        }
        if speakEasyCharges == "FREE" {
            amountTransferToSE = 0
        }
        if speakEasyCharges == "INCREMENTAL" {
            if ticketPrice <= 10 {
                amountTransferToSE = 0.5
            } else if (ticketPrice <= 20 && ticketPrice > 10) {
                amountTransferToSE = 1
            } else if (ticketPrice <= 100 && ticketPrice > 20) {
                amountTransferToSE = 2
            } else if (ticketPrice > 100) {
                amountTransferToSE = 5
            }
        }
        if speakEasyCharges == "DIFFRENT_PRICE" {
            if AppClipTicketGeneral.contains(ticketName) {
                amountTransferToSE = 1
            } else if AppClipTicketVIP.contains(ticketName) {
                amountTransferToSE = 2
            } else {
                amountTransferToSE = 0.5
            }
        }
        if speakEasyCharges == "TAO_PRICING" {
            if AppClipTicketGeneral.contains(ticketName) {
                amountTransferToSE = 0.29
            } else if AppClipTicketVIP.contains(ticketName) {
                amountTransferToSE = 2
            } else {
                amountTransferToSE = 0.5
            }
        }
        return amountTransferToSE
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(logo, forKey: .logo)
        try container.encode(bookingCode, forKey: .bookingCode)
        try container.encode(venueAttachment, forKey: .venueAttachment)
        try container.encode(venueHours, forKey: .venueHours)
        try container.encode(id, forKey: .id)
        try container.encode(uniqueId, forKey: .uniqueId)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(dressCode, forKey: .dressCode)
        try container.encode(city, forKey: .city)
        try container.encode(pinCode, forKey: .pinCode)
        try container.encode(code, forKey: .code)
        try container.encode(phone, forKey: .phone)
        try container.encode(website, forKey: .website)
        try container.encode(description, forKey: .description)
        try container.encode(status, forKey: .status)
        try container.encode(bookingStatus, forKey: .bookingStatus)
        try container.encode(venueVibes, forKey: .venueVibes)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(isEnabledGenderBasedTicket, forKey: .isEnabledGenderBasedTicket)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(bookingWaiting, forKey: .bookingWaiting)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
        try container.encode(checkInUser, forKey: .checkInUser)
        try container.encode(timezone, forKey: .timezone)
        try container.encode(venueSettings, forKey: .venueSettings)
        try container.encode(availableTimeSlot, forKey: .availableTimeSlot)
        try container.encode(speakEasyCharges, forKey: .speakEasyCharges)
        try container.encodeIfPresent(event, forKey: .event)
    }
}

struct LogoClip: Codable {

    var key: String
    var name: String
    var description: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
    }
}

struct VenueAttachmentClip: Codable {

    var key: String
    var name: String
    var description: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
    }
}

struct VenueHoursClip: Codable {

    var day: String
    var venueStatus: String
    var from: String
    var to: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(day, forKey: .day)
        try container.encode(venueStatus, forKey: .venueStatus)
        try container.encode(from, forKey: .from)
        try container.encode(to, forKey: .to)
    }
}

struct AppClipTicket: Codable {

    var id: String
    var venueId: String?
    var name: String
    var price: Double
    var parentId: String?
    var status: String?
    var description: String?
    var isDeleted: Bool?
    var createdAt: String?
    var updatedAt: String?
    var isCustom: Bool?
    // MARK: app side parameters
    var selectedQuantity: Int?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(parentId, forKey: .parentId)
        try container.encode(status, forKey: .status)
        try container.encode(description, forKey: .description)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isCustom, forKey: .isCustom)
    }
}

struct VenueSettings: Codable {

    var optedPolicy: Bool
    var policyText: String?
    var enabledCustomBookingSMS: Bool
    var bookingSMSText: String?
    var collectNameDuringBooking: Bool?
    var collectEmailDuringBooking: Bool?
    var collectEmailDuringBookingOptional: Bool?
    var currencySymbol: String?
    var currencyCode: String?
    var coverTicketFeesSettings: CoverTicketFeesSettings?
    var customCoverTicketFeesSettings: CoverTicketFeesSettings?
    var tableBookingFeesSettings: CoverTicketFeesSettings?
    var addOnsBookingFeesSettings: CoverTicketFeesSettings?
    var isOrganizer: Bool?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(optedPolicy, forKey: .optedPolicy)
        try container.encode(policyText, forKey: .policyText)
        try container.encode(enabledCustomBookingSMS, forKey: .enabledCustomBookingSMS)
        try container.encode(bookingSMSText, forKey: .bookingSMSText)
        try container.encodeIfPresent(collectNameDuringBooking, forKey: .collectNameDuringBooking)
        try container.encodeIfPresent(collectEmailDuringBooking, forKey: .collectEmailDuringBooking)
        try container.encodeIfPresent(collectEmailDuringBookingOptional, forKey: .collectEmailDuringBookingOptional)
        try container.encodeIfPresent(currencySymbol, forKey: .currencySymbol)
        try container.encodeIfPresent(currencyCode, forKey: .currencyCode)
        try container.encodeIfPresent(coverTicketFeesSettings, forKey: .coverTicketFeesSettings)
        try container.encodeIfPresent(customCoverTicketFeesSettings, forKey: .customCoverTicketFeesSettings)
        try container.encodeIfPresent(tableBookingFeesSettings, forKey: .tableBookingFeesSettings)
        try container.encodeIfPresent(addOnsBookingFeesSettings, forKey: .addOnsBookingFeesSettings)
        try container.encodeIfPresent(isOrganizer, forKey: .isOrganizer)
    }
}

struct CoverTicketFeesSettings: Codable {
    var isUpFront: Bool
    var isProcessingFeePassToCustomer: Bool
    var isEnableSalesTax: Bool
    var salesTax: Double?
    var isEnableCustomFee: Bool
    var customFeeType: String
    var customFee: Double
    var customFeeName: String?
    var pageTitle: String?
    var description: String?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isUpFront, forKey: .isUpFront)
        try container.encode(isProcessingFeePassToCustomer, forKey: .isProcessingFeePassToCustomer)
        try container.encode(isEnableSalesTax, forKey: .isEnableSalesTax)
        try container.encode(salesTax, forKey: .salesTax)
        try container.encode(isEnableCustomFee, forKey: .isEnableCustomFee)
        try container.encode(customFeeType, forKey: .customFeeType)
        try container.encode(customFee, forKey: .customFee)
        try container.encode(customFeeName, forKey: .customFeeName)
        try container.encodeIfPresent(pageTitle, forKey: .pageTitle)
        try container.encodeIfPresent(description, forKey: .description)
    }
}

enum TicketPriceType {
    case FREE
    case PAID
    case CUSTOM
}

let AppClipTicketGeneral = [
  "GENERALTICKET",
  "General Admission",
  "Female General Admission",
  "Male General Admission",
  "General Admission - Male",
  "General Admission - Female",
]

let AppClipTicketVIP = [
  "SKIPLINETICKET",
  "Skip The Line",
  "Skip The Line-Female",
  "Skip The Line-Male",
  "VIP Skip the Line",
  "Female VIP Skip the Line",
  "Male VIP Skip the Line",
  "Skip the Line - Male",
  "Skip the Line - Female",
  "VIP Skip Line",
  "VIP Skip Line - Male",
  "VIP Skip Line - Female",
];
