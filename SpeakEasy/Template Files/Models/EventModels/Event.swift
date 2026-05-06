//
//  Event.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 16/01/23.
//

import Foundation

struct Event: Codable {

    var flyer: Flyer?
    var customVenue: CustomVenue?
    var id: String
    var uniqueId: String?
//    var venueId: String
    var title: String
//    var date: String?
    var startDateTime: String
    var endDateTime: String?
    var openTimeCustomText: String?
    var whiteLabelColor: String?
    var youtubeVideoLink: String?
//    var eventType: String?
//    var artistId: String?
//    var isRecurring: Bool?
//    var version: String
//    var eventStatus: String
//    var status: String
//    var recurringType: String?
//    var recurringTo: String?
//    var recurringFrom: String?
    var description: String
    var disclaimer: String?
    var upfront: Bool?
//    var isDeleted: Bool
//    var createdAt: String
//    var updatedAt: String
//    var floorPlanId: String?
    var eventTicket: [EventTicket]?
    var venue: ClipVenue?
    var additionalButtons: [AdditionalButton]?
    var eventHasArtist: [ArtistData]?
    var showAddress: Bool?
    var hideEventEnd: Bool?
    var eventTicketGroupHasTicket: EventTicketGroupHasTicket?
    var totalTickets: Int?
    var allowGuestCheckin: Bool?
    var eventTicketSettings: EventTicketSettings?
    var showEventAttendees: Bool?
    var protectedEventTicket: [EventTicket]?
    var isEnableOnlineTables: Bool
    var isEnable3DMap: Bool
    var isEnableReservationRequest: Bool
    var eventGallery: [EventGallery]?
    var eventAddOnTicket: [EventTicket]?
    var lowestPriceTicket: EventTicket? {
        if eventTicket?.count == 0 { return nil }
        let filterTicket = eventTicket?.filter { ($0.isDeleted == false) && ($0.sellingPaused == false) && (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date()) && (($0.issuedUnits ?? 0) > ($0.soldUnits ?? 0)) }
        return filterTicket?.min { $0.price ?? 0 < $1.price ?? 0}
    }
    
    var isPausedSellingAllTickets: Bool {
        if eventTicket?.count == 0 { return false }
        let allTickets = eventTicket?.filter { ($0.isDeleted == false)}
        let filterTicket = allTickets?.filter { ($0.sellingPaused == true) }
        return filterTicket?.count == allTickets?.count
    }
    
    var isSaleEndedAllTickets: Bool {
        if eventTicket?.count == 0 { return false }

        let allTickets = eventTicket?.filter {
            ($0.isDeleted == false) &&
            ($0.sellingPaused == false)
        }

        let filterTicket = allTickets?.filter {
            (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) < Date())
        }

        return filterTicket?.count == allTickets?.count
    }
    
    var isSoldOutAllTickets: Bool {
        if eventTicket?.count == 0 { return false }
        let allTickets = eventTicket?.filter { ($0.isDeleted == false) && ($0.sellingPaused == false) && (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date()) }
        let filterTicket = allTickets?.filter { (($0.issuedUnits ?? 0) <= ($0.soldUnits ?? 0)) }
        return filterTicket?.count == allTickets?.count
    }
    
    var modifiedPasswordProtectedTicket: [EventTicket] {
        var ticketData = [EventTicket]()
        
        protectedEventTicket?.enumerated().forEach({ index, ticket in
            ticketData.append(ticket)
            
            let taxRate = eventTicketSettings?.isEnableSalesTax == true ? Double(eventTicketSettings?.salesTax ?? 0) : 0 / 100.0
            let amountTransferToVenue = Double(ticket.price ?? 0)
            let SEFee = ticket.SEFee
            let stripePerc = 0.029
            let stripeFlat = 0.3
            let totalCustomFees = ticket.customFee1
            let amountTransferToVenueTemp = amountTransferToVenue
            
            if amountTransferToVenueTemp == 0 {
                return
            }
            
            if eventTicketSettings?.isProcessingFeePassToCustomer == true {
                if eventTicketSettings?.isCustomFeeTaxable == true && eventTicketSettings?.isProcessingFeeTaxable == false {
                    let stripeFee = (stripePerc * ((amountTransferToVenueTemp + totalCustomFees) * (1 + taxRate) + SEFee) + stripeFlat) / (1 - stripePerc)
                    let totalProcessingFees = SEFee + stripeFee
                    let salesTax = (amountTransferToVenueTemp + totalCustomFees) * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalProcessingFees + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                } else if eventTicketSettings?.isCustomFeeTaxable == true &&  eventTicketSettings?.isProcessingFeeTaxable == true {
                    let stripeFee = (stripePerc * (1 + taxRate) * (amountTransferToVenueTemp + SEFee + totalCustomFees) + stripeFlat) / (1 - (1 + taxRate) * stripePerc)
                    let totalProcessingFees = SEFee + stripeFee
                    let salesTax = (amountTransferToVenueTemp + totalProcessingFees + totalCustomFees) * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalProcessingFees + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                } else if eventTicketSettings?.isCustomFeeTaxable == false && eventTicketSettings?.isProcessingFeeTaxable == true {
                    let stripeFee = (stripePerc * ((1 + taxRate) * (amountTransferToVenueTemp + SEFee) + totalCustomFees) + stripeFlat) / (1 - (1 + taxRate) * stripePerc)
                    let totalProcessingFees = SEFee + stripeFee
                    let salesTax = (amountTransferToVenueTemp + totalProcessingFees) * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalProcessingFees + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                } else {
                    let stripeFee = (stripePerc * (amountTransferToVenueTemp * (1 + taxRate) + totalCustomFees + SEFee) + stripeFlat) / (1 - stripePerc)
                    let totalProcessingFees = SEFee + stripeFee
                    let salesTax = amountTransferToVenueTemp * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalProcessingFees + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                }
            } else {
                if eventTicketSettings?.isCustomFeeTaxable == true {
                    let salesTax = (amountTransferToVenueTemp + totalCustomFees) * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                } else {
                    let salesTax = amountTransferToVenueTemp * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                }
            }
        })
        
        return ticketData
    }
    
    var modifiedEventTicket: [EventTicket] {
        var ticketData = [EventTicket]()
        
        eventTicket?.enumerated().forEach({ index, ticket in
            ticketData.append(ticket)
            
            let taxRate = eventTicketSettings?.isEnableSalesTax == true ? Double(eventTicketSettings?.salesTax ?? 0) / 100 : 0
            let amountTransferToVenue = Double(ticket.price ?? 0)
            let SEFee = ticket.SEFee
            let stripePerc = 0.029
            let stripeFlat = 0.3
            let totalCustomFees = ticket.customFee1
            let amountTransferToVenueTemp = amountTransferToVenue
            
            if amountTransferToVenueTemp == 0 {
                return
            }
            
            if eventTicketSettings?.isProcessingFeePassToCustomer == true {
                if eventTicketSettings?.isCustomFeeTaxable == true && eventTicketSettings?.isProcessingFeeTaxable == false {
                    let stripeFee = (stripePerc * ((amountTransferToVenueTemp + totalCustomFees) * (1 + taxRate) + SEFee) + stripeFlat) / (1 - stripePerc)
                    let totalProcessingFees = SEFee + stripeFee
                    let salesTax = (amountTransferToVenueTemp + totalCustomFees) * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalProcessingFees + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                } else if eventTicketSettings?.isCustomFeeTaxable == true &&  eventTicketSettings?.isProcessingFeeTaxable == true {
                    let stripeFee = (stripePerc * (1 + taxRate) * (amountTransferToVenueTemp + SEFee + totalCustomFees) + stripeFlat) / (1 - (1 + taxRate) * stripePerc)
                    let totalProcessingFees = SEFee + stripeFee
                    let salesTax = (amountTransferToVenueTemp + totalProcessingFees + totalCustomFees) * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalProcessingFees + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                } else if eventTicketSettings?.isCustomFeeTaxable == false && eventTicketSettings?.isProcessingFeeTaxable == true {
                    let stripeFee = (stripePerc * ((1 + taxRate) * (amountTransferToVenueTemp + SEFee) + totalCustomFees) + stripeFlat) / (1 - (1 + taxRate) * stripePerc)
                    let totalProcessingFees = SEFee + stripeFee
                    let salesTax = (amountTransferToVenueTemp + totalProcessingFees) * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalProcessingFees + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                } else {
                    let stripeFee = (stripePerc * (amountTransferToVenueTemp * (1 + taxRate) + totalCustomFees + SEFee) + stripeFlat) / (1 - stripePerc)
                    let totalProcessingFees = SEFee + stripeFee
                    let salesTax = amountTransferToVenueTemp * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalProcessingFees + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                }
            } else {
                if eventTicketSettings?.isCustomFeeTaxable == true {
                    let salesTax = (amountTransferToVenueTemp + totalCustomFees) * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                } else {
                    let salesTax = amountTransferToVenueTemp * taxRate
                    let amountChargedToConsumer = amountTransferToVenue + totalCustomFees + salesTax
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                }
            }
        })
        
        return ticketData
    }
    
//    enum CodingKeys: String, CodingKey {
//        case flyer
//        case customVenue
//        case id
//        case uniqueId
//        case title
//        case startDateTime
//        case endDateTime
//        case openTimeCustomText
//        case whiteLabelColor
//        case youtubeVideoLink
//        case description
//        case disclaimer
//        case upfront
//        case eventTicket
//        case venue
//        case additionalButtons
//        case eventHasArtist
//        case showAddress
//        case hideEventEnd
//        case eventTicketGroupHasTicket
//        case totalTickets
//        case allowGuestCheckin
//        case eventTicketSettings
//        case showEventAttendees
//        case protectedEventTicket
//        case isEnableOnlineTables
//        case isEnable3DMap
//        case isEnableReservationRequest
//        case eventGallery
//        case eventAddOnTicket
//    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(flyer, forKey: .flyer)
        try container.encode(customVenue, forKey: .customVenue)
        try container.encode(id, forKey: .id)
        try container.encode(uniqueId, forKey: .uniqueId)
//        try container.encode(venueId, forKey: .venueId)
        try container.encode(title, forKey: .title)
//        try container.encode(date, forKey: .date)
        try container.encode(startDateTime, forKey: .startDateTime)
        try container.encode(endDateTime, forKey: .endDateTime)
        try container.encode(openTimeCustomText, forKey: .openTimeCustomText)
        try container.encode(whiteLabelColor, forKey: .whiteLabelColor)
        try container.encode(youtubeVideoLink, forKey: .youtubeVideoLink)
//        try container.encode(eventType, forKey: .eventType)
//        try container.encode(artistId, forKey: .artistId)
//        try container.encode(isRecurring, forKey: .isRecurring)
//        try container.encode(version, forKey: .version)
//        try container.encode(eventStatus, forKey: .eventStatus)
//        try container.encode(status, forKey: .status)
//        try container.encode(recurringType, forKey: .recurringType)
//        try container.encode(recurringTo, forKey: .recurringTo)
//        try container.encode(recurringFrom, forKey: .recurringFrom)
        try container.encode(description, forKey: .description)
        try container.encode(disclaimer, forKey: .disclaimer)
        try container.encode(upfront, forKey: .upfront)
        try container.encode(showEventAttendees, forKey: .showEventAttendees)
//        try container.encode(isDeleted, forKey: .isDeleted)
//        try container.encode(createdAt, forKey: .createdAt)
//        try container.encode(updatedAt, forKey: .updatedAt)
//        try container.encode(floorPlanId, forKey: .floorPlanId)
        try container.encode(eventTicket, forKey: .eventTicket)
        try container.encode(venue, forKey: .venue)
        try container.encode(eventHasArtist, forKey: .eventHasArtist)
        try container.encode(showAddress, forKey: .showAddress)
        try container.encode(totalTickets, forKey: .totalTickets)
        try container.encode(allowGuestCheckin, forKey: .allowGuestCheckin)
    }
}

struct EventResponse: Codable {
    let list: [Event]
    let hasMany: Bool
}

struct EventTicketGroupHasTicket: Codable {
    var id: String?
    var eventTicketGroupId: String?
    var eventTicketId: String?
    var createdAt: String?
    var updatedAt: String?
    var eventTicketGroup: EventTicketGroup?
}

struct EventTicketGroup: Codable {
    var id: String?
    var name: String?
    var order: Int?
    var eventId: String?
    var createdAt: String?
    var updatedAt: String?
}

struct AdditionalButton: Codable {
    let link: String
    let title: String
    let isEnable: Bool
}

struct AttendeesResponse: Codable {
    var total: Int?
    var list: [Attendee]?
    var hasMany: Bool?
    var count: Int?
}

struct Attendee: Codable {

    var id: String?
    var firstName: String?
    var lastName: String?
    var consumerUserImage: ImageData?
    let instagramUserId: String?
    var hasImage: Bool {
           guard let key = consumerUserImage?.key?
               .trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
           return !key.isEmpty
       }
    
    
    var fullName: String {
        let first = firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func parse(_ dict: [String: Any]) -> Attendee? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            return try JSONDecoder().decode(Attendee.self, from: data)
        } catch {
            print("Attendee parsing error:", error)
            return nil
        }
    }
    
}

struct ImageData: Codable {
    var id: String?
    var key: String?
}

struct EventGallery: Codable {
    let id: String
    let eventId: String
    let key: String
    let name: String?
    let description: String?
    let status: String
    let isDeleted: Bool
    let createdAt: String
    let updatedAt: String
}

struct EventFAQ: Codable {
    let id: String?
    let eventId: String?
    let title: String?
    let content: String?
    let order: Int?
    let status: String?
    let isDeleted: Bool?
    let createdAt: String?
    let updatedAt: String?
}

// struct Event: Codable {
//
//    let id: String
//    let uniqueId: String?
//    let venueId: String?
//    let title: String
//    let startDateTime: String
//    let endDateTime: String?
//
//    let description: String
//    let disclaimer: String?
//
//    let upfront: Bool?
//    let showAddress: Bool?
//    let allowGuestCheckin: Bool?
//
//    let totalTickets: Int?
//    let totalTicketIssued: Int?
//    let totalTicketSold: Int?
//    let totalSales: Double?
//
//    let coverImages: [String]?
//    let flyer: Flyer?
//
//    let customVenue: CustomVenue?
//    let venue: Venue?
//
//    let eventHasArtist: [EventHasArtist]?
//    let eventTicket: [EventTicket]?
//    let eventTicketSettings: EventTicketSettings?
//
//    let hasPurchasedTicket: Bool?
// }

struct ArtistData: Codable {
    var artist: Artists
}

struct EventTicketSettings: Codable {
    var isUpFront: Bool
    var isProcessingFeePassToCustomer: Bool
    var isEnableSalesTax: Bool
    var hideSoldOut: Bool
    var hideLowInventory: Bool
    var salesTax: Double
    var isCustomFeeTaxable: Bool
    var isProcessingFeeTaxable: Bool
    var showTicketListingOnMainScreen: Bool

    var isSoldOutTextEnabled: Bool?
    var soldOutText: String?
    var isSaleEndedTextEnabled: Bool?
    var saleEndedText: String?
    var collectShippingAddress: Bool?
    var shippingNote: String?
    var endSalesOnEventEnd: Bool?
    var stripePerc: Double?
    var stripeFlat: Double?
}
struct Artists: Codable {

//    var id: String
    var name: String
    var instagramUsername: String
    var status: String
//    var createdAt: String
//    var updatedAt: String
    var artistImage: Flyer?
//    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(instagramUsername, forKey: .instagramUsername)
        try container.encode(status, forKey: .status)
//        try container.encode(createdAt, forKey: .createdAt)
//        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(artistImage, forKey: .artistImage)
    }
}

struct CustomVenue: Codable {
    
    var id: String?
    var name: String?
    var address: String?
    var city: String?
    var pinCode: String?
    var region: String?
    var country: String?
    var lat: String?
    var lng: String?
    var latitude: Double?
    var longitude: Double?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id       = try container.decodeIfPresent(String.self, forKey: .id)
        name     = try container.decodeIfPresent(String.self, forKey: .name)
        address  = try container.decodeIfPresent(String.self, forKey: .address)
        city     = try container.decodeIfPresent(String.self, forKey: .city)
        pinCode  = try container.decodeIfPresent(String.self, forKey: .pinCode)
        region   = try container.decodeIfPresent(String.self, forKey: .region)
        country  = try container.decodeIfPresent(String.self, forKey: .country)
        lat      = try container.decodeIfPresent(String.self, forKey: .lat)
        lng      = try container.decodeIfPresent(String.self, forKey: .lng)
        
        // Parse lat/lng strings into Double
        if let latStr = lat { latitude = Double(latStr) }
        if let lngStr = lng { longitude = Double(lngStr) }
        
        // Also try decoding latitude/longitude directly if present
        if latitude == nil {
            latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        }
        if longitude == nil {
            longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        }
    }
}


//
//struct CustomVenue: Codable {
//    
//    var name: String
//    var address: String
////    var city: String?
////    var pinCode: String?
//    var lat: String?
//    var lng: String?
//    // MARK: App side parameter
//    var latitude: Double {
//        Double(lat ?? "0") ?? 0.0
//    }
//    var longitude: Double {
//        Double(lng ?? "0") ?? 0.0
//    }
//    
//    enum CodingKeys: String, CodingKey {
//         case name
//         case address
//         case lat     // map API key
//         case lng     // map API key
//     }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(name, forKey: .name)
//        try container.encode(address, forKey: .address)
////        try container.encode(city, forKey: .city)
////        try container.encode(pinCode, forKey: .pinCode)
//        try container.encode(lat, forKey: .lat)
//        try container.encode(lng, forKey: .lng)
//    }
//}

struct InstagramProfile: Codable {
    let instagramUserId: String?
    let profilePictureKey: String?
    let profilePictureFilename: String?
    let message: String?
}
