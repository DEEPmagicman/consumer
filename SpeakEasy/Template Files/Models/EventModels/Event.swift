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
    var venueId: String
    var title: String
    var date: String?
    var startDateTime: String
    var endDateTime: String?
    var isCover: Bool
    var eventType: String?
    var artistId: String?
    var isRecurring: Bool?
    var version: String
    var eventStatus: String
    var status: String
    var rejectReason: String?
    var recurringType: String?
    var recurringTo: String?
    var recurringFrom: String?
    var description: String
    var disclaimer: String?
    var isTieredTicket: Bool
    var upfront: Bool?
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String
    var floorPlanId: String?
    var eventTicket: [EventTicket]?
    var passwordProtrectedTickets: [EventTicket]?
    var venue: ClipVenue?
    var eventHasArtist: [ArtistData]?
    var showAddress: Bool?
    var totalTickets: Int?
    var allowGuestCheckin: Bool?
    var eventTicketSettings: EventTicketSettings?
    
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
    
    var isSoldOutAllTickets: Bool {
        if eventTicket?.count == 0 { return false }
        let allTickets = eventTicket?.filter { ($0.isDeleted == false) && ($0.sellingPaused == false) && (($0.endSale.toDate(withFormat: .yyyyMMddHHmmss) ?? Date()) > Date()) }
        let filterTicket = allTickets?.filter { (($0.issuedUnits ?? 0) <= ($0.soldUnits ?? 0)) }
        return filterTicket?.count == allTickets?.count
    }
    
    var modifiedPasswordProtectedTicket: [EventTicket] {
        var ticketData = [EventTicket]()
        
        passwordProtrectedTickets?.enumerated().forEach({ index, ticket in
            ticketData.append(ticket)
            
            let taxRate = Double(eventTicketSettings?.salesTax ?? 0) / 100.0
            let currentPrice = Double(ticket.price ?? 0)
            
            if eventTicketSettings?.isProcessingFeePassToCustomer == true {
                if eventTicketSettings?.isCustomFeeTaxable == true && eventTicketSettings?.isProcessingFeeTaxable == false {
                    let stripeFee = (0.029 * ((currentPrice + ticket.customFee1) * (1.0 + taxRate) + ticket.SEFee) + 0.3) / (1 - 0.029)
                    let totalProcessingFees = ticket.SEFee + stripeFee
                    let salesTax = ((currentPrice + ticket.customFee1) * taxRate)
                    let amountChargedToConsumer = (currentPrice + totalProcessingFees + ticket.customFee1 +  salesTax)
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                } else {
                    let stripeFee = (0.029 * (1 + taxRate) * (currentPrice + ticket.SEFee + ticket.customFee1) + 0.3) / (1 - (1 + taxRate) * 0.029)
                    let totalProcessingFees = ticket.SEFee + stripeFee
                    let salesTax = (currentPrice + totalProcessingFees + ticket.customFee1) * taxRate
                    let amountChargedToConsumer = (currentPrice + totalProcessingFees + ticket.customFee1 + salesTax)
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                }
            } else {
                let salesTax = ((currentPrice + ticket.customFee1) * taxRate)
                let amountChargedToConsumer = (currentPrice + ticket.customFee1 + salesTax)
                ticketData[index].price = round(amountChargedToConsumer * 100) / 100
            }
        })
        
        return ticketData
    }
    
    var modifiedEventTicket: [EventTicket] {
        var ticketData = [EventTicket]()
        
        eventTicket?.enumerated().forEach({ index, ticket in
            ticketData.append(ticket)
            
            let taxRate = Double(eventTicketSettings?.salesTax ?? 0) / 100.0
            let currentPrice = Double(ticket.price ?? 0)
            
            if eventTicketSettings?.isProcessingFeePassToCustomer == true {
                if eventTicketSettings?.isCustomFeeTaxable == true && eventTicketSettings?.isProcessingFeeTaxable == false {
                    let stripeFee = (0.029 * ((currentPrice + ticket.customFee1) * (1.0 + taxRate) + ticket.SEFee) + 0.3) / (1 - 0.029)
                    let totalProcessingFees = ticket.SEFee + stripeFee
                    let salesTax = ((currentPrice + ticket.customFee1) * taxRate)
                    let amountChargedToConsumer = (currentPrice + totalProcessingFees + ticket.customFee1 +  salesTax)
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                } else {
                    let stripeFee = (0.029 * (1 + taxRate) * (currentPrice + ticket.SEFee + ticket.customFee1) + 0.3) / (1 - (1 + taxRate) * 0.029)
                    let totalProcessingFees = ticket.SEFee + stripeFee
                    let salesTax = (currentPrice + totalProcessingFees + ticket.customFee1) * taxRate
                    let amountChargedToConsumer = (currentPrice + totalProcessingFees + ticket.customFee1 + salesTax)
                    ticketData[index].price = round(amountChargedToConsumer * 100) / 100
                }
            } else {
                let salesTax = ((currentPrice + ticket.customFee1) * taxRate)
                let amountChargedToConsumer = (currentPrice + ticket.customFee1 + salesTax)
                ticketData[index].price = round(amountChargedToConsumer * 100) / 100
            }
        })
        
        return ticketData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(flyer, forKey: .flyer)
        try container.encode(customVenue, forKey: .customVenue)
        try container.encode(id, forKey: .id)
        try container.encode(uniqueId, forKey: .uniqueId)
        try container.encode(venueId, forKey: .venueId)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(startDateTime, forKey: .startDateTime)
        try container.encode(endDateTime, forKey: .endDateTime)
        try container.encode(isCover, forKey: .isCover)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(artistId, forKey: .artistId)
        try container.encode(isRecurring, forKey: .isRecurring)
        try container.encode(version, forKey: .version)
        try container.encode(eventStatus, forKey: .eventStatus)
        try container.encode(status, forKey: .status)
        try container.encode(rejectReason, forKey: .rejectReason)
        try container.encode(recurringType, forKey: .recurringType)
        try container.encode(recurringTo, forKey: .recurringTo)
        try container.encode(recurringFrom, forKey: .recurringFrom)
        try container.encode(description, forKey: .description)
        try container.encode(disclaimer, forKey: .disclaimer)
        try container.encode(isTieredTicket, forKey: .isTieredTicket)
        try container.encode(upfront, forKey: .upfront)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(floorPlanId, forKey: .floorPlanId)
        try container.encode(eventTicket, forKey: .eventTicket)
        try container.encode(venue, forKey: .venue)
        try container.encode(eventHasArtist, forKey: .eventHasArtist)
        try container.encode(showAddress, forKey: .showAddress)
        try container.encode(totalTickets, forKey: .totalTickets)
        try container.encode(allowGuestCheckin, forKey: .allowGuestCheckin)
    }
}

struct ArtistData: Codable {
    var artist: Artists
}

struct EventTicketSettings: Codable {
    
    var isUpFront: Bool
    var isProcessingFeePassToCustomer: Bool
    var isEnableSalesTax: Bool
    var salesTaxName: String
    var salesTax: Int
    var subjectToTax: Bool
    var isCustomFeeTaxable: Bool
    var isProcessingFeeTaxable: Bool
}

struct Artists: Codable {

    var id: String
    var name: String
    var instagramUsername: String
    var status: String
    var createdAt: String
    var updatedAt: String
    var artistImage: Flyer?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(instagramUsername, forKey: .instagramUsername)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(artistImage, forKey: .artistImage)
    }
}

struct CustomVenue: Codable {
    
    var name: String
    var address: String
    var city: String?
    var pinCode: String?
    var lat: String?
    var lng: String?
    // MARK: App side parameter
    var latitude: Double {
        Double(lat ?? "0") ?? 0.0
    }
    var longitude: Double {
        Double(lng ?? "0") ?? 0.0
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(city, forKey: .city)
        try container.encode(pinCode, forKey: .pinCode)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
    }
}
