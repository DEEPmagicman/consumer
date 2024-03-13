//
//  Booking.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 28/04/23.
//

import Foundation

struct Booking: Codable {

    var venueObject: ClipVenue?
    var id: Int
    var venueId: Int
//    var phone: String
    var eventId: Int?
//    var isAppClipUser: Bool
    var paymentType: String?
//    var appClipUserId: Any
//    var ticketName: Any
    var isCheckedIn: Bool?
//    var ticketPrice: Any
//    var ticketQuantity: Any
    var totalPrice: Int?
    var note: String?
    var consumerUserId: [String]?
//    var bookingDate: Any
    var bookingStartTime: String?
    var bookingEndTime: String?
    var paymentIntent: String?
//    var additionalSpent: Any
    var isCompedTicket: Bool?
//    var paymentStatus: String
    var bookingExpireDateTime: String?
//    var qrScannedDateTime: Any
    var createdAt: String
//    var updatedAt: String
    var isDeleted: Bool?
//    var isApproved: Bool
//    var eventTicketId: Any
//    var eventTicketHasTierId: Any
    var bookingType: String?
    var bookingHasItem: [BookingHasItem]
    var event: Event?
    var ticketDetails: [TicketDetails]?
    var floorPlanTimeSlotBooking: [TimeSlot]?
    var inviteLink: InviteLink?
    var fees: PaymentDetail?
    var guestList: GuestList?
    var addOnsBookingId: String?
    // MARK: app side parameters
    var uniqueTickets: [BookingHasItem] {
        var tickets = [BookingHasItem]()
        bookingHasItem.forEach { ticket in
            if let index = tickets.firstIndex(where: { $0.ticketId == ticket.ticketId }), let quantity = tickets[index].selectedQuantity {
                tickets[index].selectedQuantity = quantity + 1
            } else {
                var ticket = ticket
                ticket.selectedQuantity = 1
                tickets.append(ticket)
            }
        }
        return tickets
    }
    
    private enum CodingKeys: String, CodingKey {
        case venueObject
        case id = "id"
        case venueId = "venueId"
//        case phone = "phone"
        case eventId = "eventId"
//        case isAppClipUser = "isAppClipUser"
        case paymentType = "paymentType"
//        case appClipUserId = "appClipUserId"
//        case ticketName = "ticketName"
        case isCheckedIn = "isCheckedIn"
//        case ticketPrice = "ticketPrice"
//        case ticketQuantity = "ticketQuantity"
        case totalPrice = "totalPrice"
        case note
        case consumerUserId = "consumerUserId"
//        case bookingDate = "bookingDate"
        case bookingStartTime = "bookingStartTime"
        case bookingEndTime = "bookingEndTime"
        case paymentIntent = "paymentIntent"
//        case additionalSpent = "additionalSpent"
        case isCompedTicket = "isCompedTicket"
//        case paymentStatus = "paymentStatus"
        case bookingExpireDateTime = "bookingExpireDateTime"
//        case qrScannedDateTime = "qrScannedDateTime"
        case createdAt = "createdAt"
//        case updatedAt = "updatedAt"
        case isDeleted = "isDeleted"
//        case isApproved = "isApproved"
//        case eventTicketId = "eventTicketId"
//        case eventTicketHasTierId = "eventTicketHasTierId"
        case bookingType = "bookingType"
        case bookingHasItem = "bookingHasItem"
        case event = "event"
        case ticketDetails = "ticketDetails"
        case floorPlanTimeSlotBooking = "FloorPlanTimeSlotBooking"
        case inviteLink = "InviteLink"
        case fees
        case guestList
        case addOnsBookingId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(venueObject, forKey: .venueObject)
        try container.encode(id, forKey: .id)
        try container.encode(venueId, forKey: .venueId)
//        try container.encode(phone, forKey: .phone)
        try container.encode(eventId, forKey: .eventId)
//        try container.encode(isAppClipUser, forKey: .isAppClipUser)
        try container.encode(paymentType, forKey: .paymentType)
        // TODO: Add code for encoding `appClipUserId`, It was null at the time of model creation.
        // TODO: Add code for encoding `ticketName`, It was null at the time of model creation.
        try container.encodeIfPresent(isCheckedIn, forKey: .isCheckedIn)
        // TODO: Add code for encoding `ticketPrice`, It was null at the time of model creation.
        // TODO: Add code for encoding `ticketQuantity`, It was null at the time of model creation.
        try container.encodeIfPresent(totalPrice, forKey: .totalPrice)
        try container.encode(note, forKey: .note)
        try container.encode(consumerUserId, forKey: .consumerUserId)
        // TODO: Add code for encoding `bookingDate`, It was null at the time of model creation.
        try container.encode(bookingStartTime, forKey: .bookingStartTime)
        try container.encode(bookingEndTime, forKey: .bookingEndTime)
        try container.encode(paymentIntent, forKey: .paymentIntent)
        // TODO: Add code for encoding `additionalSpent`, It was null at the time of model creation.
        try container.encode(isCompedTicket, forKey: .isCompedTicket)
//        try container.encode(paymentStatus, forKey: .paymentStatus)
        try container.encode(bookingExpireDateTime, forKey: .bookingExpireDateTime)
        // TODO: Add code for encoding `qrScannedDateTime`, It was null at the time of model creation.
        try container.encode(createdAt, forKey: .createdAt)
//        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isDeleted, forKey: .isDeleted)
//        try container.encode(isApproved, forKey: .isApproved)
        // TODO: Add code for encoding `eventTicketId`, It was null at the time of model creation.
        // TODO: Add code for encoding `eventTicketHasTierId`, It was null at the time of model creation.
        try container.encode(bookingType, forKey: .bookingType)
        try container.encode(bookingHasItem, forKey: .bookingHasItem)
        try container.encode(event, forKey: .event)
        try container.encode(ticketDetails, forKey: .ticketDetails)
        try container.encode(floorPlanTimeSlotBooking, forKey: .floorPlanTimeSlotBooking)
        try container.encodeIfPresent(fees, forKey: .fees)
        try container.encodeIfPresent(guestList, forKey: .guestList)
        try container.encode(addOnsBookingId, forKey: .addOnsBookingId)
    }
}

struct BookingHasItem: Codable {

    var id: Int
    var ticketId: Int
    var ticketName: String?
    var ticketPrice: Int
    var isCheckedIn: Int?
    var bookingId: Int
    var isDeleted: Bool?
    var createdAt: String
    var updatedAt: String
    var ticketCustomName: String?
    // MARK: app side parameters
    var selectedQuantity: Int? = nil

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case ticketId = "ticketId"
        case ticketName = "ticketName"
        case ticketPrice = "ticketPrice"
        case isCheckedIn = "isCheckedIn"
        case bookingId = "bookingId"
        case isDeleted = "isDeleted"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case ticketCustomName
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ticketId, forKey: .ticketId)
        try container.encode(ticketName, forKey: .ticketName)
        try container.encode(ticketPrice, forKey: .ticketPrice)
        try container.encodeIfPresent(isCheckedIn, forKey: .isCheckedIn)
        try container.encode(bookingId, forKey: .bookingId)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(ticketCustomName, forKey: .ticketCustomName)
    }
}

struct TicketDetails: Codable {

    var ticketName: String?
    var ticketId: Int?
    var ticketDescription: String?
    var quantity: Int?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ticketName, forKey: .ticketName)
        try container.encode(ticketId, forKey: .ticketId)
        try container.encode(ticketDescription, forKey: .ticketDescription)
        try container.encode(quantity, forKey: .quantity)
    }
}

struct InviteLink: Codable {
    
    var id: String
    var uniqueId: String
    var date: String
    var name: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uniqueId, forKey: .uniqueId)
        try container.encode(date, forKey: .date)
        try container.encode(name, forKey: .name)
    }
}

struct GuestList: Codable {
    
    var id: String
    var name: String
    var startTime: String
    var endTime: String?
    var description: String?
    var category: String
    var venueId: String
    var createdAt: String
    var updatedAt: String
    var count: Int?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(count, forKey: .count)
    }
}

struct UpSellTicket: Codable {
    
    var id: String
    var doormanId: String
    var addOnsId: String
    var price: Double
    var status: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    var addOns: AddOns?
    // MARK: app side parameters
    var selectedQuantity: Int?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(doormanId, forKey: .doormanId)
        try container.encode(addOnsId, forKey: .addOnsId)
        try container.encode(price, forKey: .price)
        try container.encode(status, forKey: .status)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(addOns, forKey: .addOns)
    }
}

struct AddOns: Codable {
    
    var id: String
    var name: String
    var description: String
    var venueId: String
    var status: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(status, forKey: .status)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
}

struct AddOnsBooking: Codable {
    var fees: PaymentDetail?
    var id: String?
    var venueId: String?
    var bookingId: Int?
    var addOnsBookingHasItem: [AddOnsBookingHasItem]?
    var venue: AddOnVenue
    var createdAt: String
    // MARK: app side parameters
    var uniqueTickets: [AddOnsBookingHasItem] {
        var tickets = [AddOnsBookingHasItem]()
        addOnsBookingHasItem?.forEach { ticket in
            if let index = tickets.firstIndex(where: { $0.addonsId == ticket.addonsId }), let quantity = tickets[index].selectedQuantity {
                tickets[index].selectedQuantity = quantity + 1
            } else {
                var ticket = ticket
                ticket.selectedQuantity = 1
                tickets.append(ticket)
            }
        }
        return tickets
    }
    
    enum CodingKeys: String, CodingKey {
        case fees
        case id
        case venueId
        case bookingId
        case addOnsBookingHasItem = "AddOnsBookingHasItem"
        case venue
        case createdAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fees, forKey: .fees)
        try container.encode(id, forKey: .id)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(bookingId, forKey: .bookingId)
        try container.encode(addOnsBookingHasItem, forKey: .addOnsBookingHasItem)
        try container.encodeIfPresent(venue, forKey: .venue)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

struct AddOnsBookingHasItem: Codable {
    
    var addons: AddOns
    var addOnsBookingId: String
    var addonsId: String
    // MARK: app side parameters
    var selectedQuantity: Int? = nil
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(addons, forKey: .addons)
        try container.encode(addOnsBookingId, forKey: .addOnsBookingId)
        try container.encode(addonsId, forKey: .addonsId)
    }
}

struct AddOnVenue: Codable {
    var bookingCode: String
    var id: String
    var uniqueId: String
    var timezone: String?
}
