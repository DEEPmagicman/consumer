//
//  Booking.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 28/04/23.
//

import Foundation

struct Booking: Codable {

    var venueObject: ClipVenue?
    var id: String
    var venueId: String?
    var eventId: String?
    var paymentType: String?
    var totalPrice: Double?
    var note: String?
    var consumerUserId: [String]?
    var bookingStartTime: String?
    var bookingEndTime: String?
    var paymentIntent: String?
    var isCompedTicket: Bool?
    var bookingExpireDateTime: String?
    var createdAt: String
    var isDeleted: Bool?
    var bookingType: String?
    var bookingHasItem: [BookingHasItem]
    var event: Event?
    var ticketDetails: [TicketDetails]?
    var floorPlanTimeSlotBooking: [TimeSlot]?
    var inviteLink: InviteLink?
    var inviteLinkId: String?
    var fees: PaymentDetail?
    var guestList: GuestList?
    var addOnsBookingId: String?
    var bookingHasCheckIn: [BookingHasCheckIn]?
    var bookingDetails: BookingDetails?
    
    // MARK: app side parameters
    var uniqueTickets: [BookingHasItem] {
        var tickets = [BookingHasItem]()
        bookingHasItem.forEach { ticket in
            if let index = tickets.firstIndex(where: { $0.ticketId == ticket.ticketId }), let quantity = tickets[index].selectedQuantity {
                tickets[index].selectedQuantity = quantity + 1
                if bookingHasCheckIn?.first?.bookingItemCheckIn.contains(where: { $0.bookingHasItemId == ticket.id }) == true {
                    let alreadyCheckInCount = tickets[index].checkedInQuantity ?? 0
                    tickets[index].checkedInQuantity = alreadyCheckInCount + 1
                }
            } else {
                var ticket = ticket
                ticket.selectedQuantity = 1
                if bookingHasCheckIn?.first?.bookingItemCheckIn.contains(where: { $0.bookingHasItemId == ticket.id }) == true {
                    ticket.checkedInQuantity = 1
                } else {
                    ticket.checkedInQuantity = 0
                }
                tickets.append(ticket)
            }
        }
        return tickets
    }
    var isCheckedIn: Bool {
        bookingHasCheckIn?.first?.bookingItemCheckIn.count ?? 0 == 0 ? false : true
    }
    
    private enum CodingKeys: String, CodingKey {
        case venueObject = "venue"
        case id = "id"
        case venueId = "venueId"
        case eventId = "eventId"
        case paymentType = "paymentType"
        case totalPrice = "totalPrice"
        case note
        case consumerUserId = "consumerUserId"
        case bookingStartTime = "bookingStartTime"
        case bookingEndTime = "bookingEndTime"
        case paymentIntent = "paymentIntent"
        case isCompedTicket = "isCompedTicket"
        case bookingExpireDateTime = "bookingExpireDateTime"
        case createdAt = "createdAt"
        case isDeleted = "isDeleted"
        case bookingType = "bookingType"
        case bookingHasItem = "bookingHasItem"
        case event = "event"
        case ticketDetails = "ticketDetails"
        case floorPlanTimeSlotBooking = "FloorPlanTimeSlotBooking"
        case inviteLink
        case inviteLinkId
        case fees
        case guestList
        case addOnsBookingId
        case bookingHasCheckIn
        case bookingDetails
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(venueObject, forKey: .venueObject)
        try container.encode(id, forKey: .id)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(paymentType, forKey: .paymentType)
        try container.encodeIfPresent(totalPrice, forKey: .totalPrice)
        try container.encode(note, forKey: .note)
        try container.encode(consumerUserId, forKey: .consumerUserId)
        try container.encode(bookingStartTime, forKey: .bookingStartTime)
        try container.encode(bookingEndTime, forKey: .bookingEndTime)
        try container.encode(paymentIntent, forKey: .paymentIntent)
        try container.encode(isCompedTicket, forKey: .isCompedTicket)
        try container.encode(bookingExpireDateTime, forKey: .bookingExpireDateTime)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(bookingType, forKey: .bookingType)
        try container.encode(bookingHasItem, forKey: .bookingHasItem)
        try container.encode(event, forKey: .event)
        try container.encode(ticketDetails, forKey: .ticketDetails)
        try container.encode(floorPlanTimeSlotBooking, forKey: .floorPlanTimeSlotBooking)
        try container.encodeIfPresent(inviteLink, forKey: .inviteLink)
        try container.encodeIfPresent(inviteLinkId, forKey: .inviteLinkId)
        try container.encodeIfPresent(fees, forKey: .fees)
        try container.encodeIfPresent(guestList, forKey: .guestList)
        try container.encode(addOnsBookingId, forKey: .addOnsBookingId)
        try container.encodeIfPresent(bookingHasCheckIn, forKey: .bookingHasCheckIn)
        try container.encodeIfPresent(bookingDetails, forKey: .bookingDetails)
    }
}

struct FeeDisplayItem {
    var title: String
    var amount: Double
}

struct BookingHasItem: Codable {

    var id: String
    var ticketId: String
    var ticketName: String?
    var ticketPrice: Double
    var bookingId: String
    var isDeleted: Bool?
    var createdAt: String
    var updatedAt: String
    var ticketCustomName: String?
    // MARK: app side parameters
    var selectedQuantity: Int?
    var checkedInQuantity: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case ticketId
        case ticketName
        case ticketPrice
        case bookingId
        case isDeleted
        case createdAt
        case updatedAt
        case ticketCustomName
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ticketId, forKey: .ticketId)
        try container.encode(ticketName, forKey: .ticketName)
        try container.encode(ticketPrice, forKey: .ticketPrice)
        try container.encode(bookingId, forKey: .bookingId)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(ticketCustomName, forKey: .ticketCustomName)
    }
}

struct TicketDetails: Codable {

    var ticketName: String?
    var ticketId: String?
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
    var date: String?
    var name: String
    var guestList: GuestList?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uniqueId, forKey: .uniqueId)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(guestList, forKey: .guestList)
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
    var extraFees: Double?
    var status: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    var addOns: AddOns?
    // MARK: app side parameters
    var selectedQuantity: Int?
    var calculatedNetPrice: Double {
            let fees = extraFees ?? 0
            return price - fees
        }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(doormanId, forKey: .doormanId)
        try container.encode(addOnsId, forKey: .addOnsId)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(extraFees, forKey: .extraFees)
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
    var bookingId: String?
    var addOnsBookingHasItem: [AddOnsBookingHasItem]?
    var venue: AddOnVenue?
    var createdAt: String
    var addOnsBookingHasCheckIn: [AddOnsBookingHasCheckIn]?
    
    // MARK: app side parameters
    var uniqueTickets: [AddOnsBookingHasItem] {
        var tickets = [AddOnsBookingHasItem]()
        addOnsBookingHasItem?.forEach { ticket in
            if let index = tickets.firstIndex(where: { $0.addOnsId == ticket.addOnsId }), let quantity = tickets[index].selectedQuantity {
                tickets[index].selectedQuantity = quantity + 1
                if addOnsBookingHasCheckIn?.first?.addOnsBookingItemCheckIn?.contains(where: { $0.addOnsBookingHasItemId == ticket.id }) == true {
                    let alreadyCheckInCount = tickets[index].checkedInQuantity ?? 0
                    tickets[index].checkedInQuantity = alreadyCheckInCount + 1
                }
            } else {
                var ticket = ticket
                ticket.selectedQuantity = 1
                if addOnsBookingHasCheckIn?.first?.addOnsBookingItemCheckIn?.contains(where: { $0.addOnsBookingHasItemId == ticket.id }) == true {
                    ticket.checkedInQuantity = 1
                } else {
                    ticket.checkedInQuantity = 0
                }
                tickets.append(ticket)
            }
        }
        return tickets
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
    
    var id: String
    var addOns: AddOns
    var addOnsBookingId: String
    var addOnsId: String
    // MARK: app side parameters
    var selectedQuantity: Int?
    var checkedInQuantity: Int?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(addOns, forKey: .addOns)
        try container.encode(addOnsBookingId, forKey: .addOnsBookingId)
        try container.encode(addOnsId, forKey: .addOnsId)
    }
}

struct AddOnVenue: Codable {
    var bookingCode: String
    var id: String
    var uniqueId: String
    var timezone: String?
    var name: String?
    var venueAttachment: [VenueAttachmentClip]?
}

struct AddOnsBookingHasCheckIn: Codable {
    
    var id: String
    var addOnsBookingId: String
    var consumerUserId: String
    var lastCheckIn: String?
    var status: String?
    var createdAt: String?
    var updatedAt: String?
    var isDeleted: Bool?
    var addOnsBookingItemCheckIn: [AddOnsBookingItemCheckIn]?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(addOnsBookingId, forKey: .addOnsBookingId)
        try container.encode(consumerUserId, forKey: .consumerUserId)
        try container.encodeIfPresent(lastCheckIn, forKey: .lastCheckIn)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(isDeleted, forKey: .isDeleted)
        try container.encodeIfPresent(addOnsBookingItemCheckIn, forKey: .addOnsBookingItemCheckIn)
    }
}

struct AddOnsBookingItemCheckIn: Codable {
    
    var id: String
    var addOnsBookingHasCheckInId: String
    var addOnsBookingHasItemId: String
    var checkInDate: String?
    var createdAt: String?
    var updatedAt: String?
    var isDeleted: Bool?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(addOnsBookingHasCheckInId, forKey: .addOnsBookingHasCheckInId)
        try container.encode(addOnsBookingHasItemId, forKey: .addOnsBookingHasItemId)
        try container.encodeIfPresent(checkInDate, forKey: .checkInDate)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(isDeleted, forKey: .isDeleted)
    }
}

struct BookingHasCheckIn: Codable {
    
    var id: String
    var bookingId: String
    var consumerUserId: String
    var lastCheckIn: String
    var status: String
    var createdAt: String
    var updatedAt: String
    var isDeleted: Bool
    var bookingItemCheckIn: [BookingCheckIn]
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(bookingId, forKey: .bookingId)
        try container.encode(consumerUserId, forKey: .consumerUserId)
        try container.encode(lastCheckIn, forKey: .lastCheckIn)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(bookingItemCheckIn, forKey: .bookingItemCheckIn)
    }
}

struct BookingCheckIn: Codable {
    
    var id: String
    var bookingHasCheckInId: String
    var bookingHasItemId: String
    var checkInDate: String
    var createdAt: String
    var updatedAt: String
    var isDeleted: Bool
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(bookingHasCheckInId, forKey: .bookingHasCheckInId)
        try container.encode(bookingHasItemId, forKey: .bookingHasItemId)
        try container.encode(checkInDate, forKey: .checkInDate)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isDeleted, forKey: .isDeleted)
    }
}

struct Questions: Codable {
    
    var id: String
    var eventId: String
    var question: String
    var order: Int
    var isOptional: Bool
    var questionType: String
    var status: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    var eventQuestionHasOption: [EventQuestionHasOption]?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(question, forKey: .question)
        try container.encode(order, forKey: .order)
        try container.encode(isOptional, forKey: .isOptional)
        try container.encode(questionType, forKey: .questionType)
        try container.encode(status, forKey: .status)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(eventQuestionHasOption, forKey: .eventQuestionHasOption)
    }
}

struct EventQuestionHasOption: Codable {
    
    var id: String
    var eventQuestionId: String
    var option: String
    var status: String
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(eventQuestionId, forKey: .eventQuestionId)
        try container.encode(option, forKey: .option)
        try container.encode(status, forKey: .status)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

struct BookingDetails: Codable {
    
    var id: String
    var bookingId: String
    var eventTicketSettings: EventTicketSettings?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(bookingId, forKey: .bookingId)
        try container.encode(eventTicketSettings, forKey: .eventTicketSettings)
    }
}
