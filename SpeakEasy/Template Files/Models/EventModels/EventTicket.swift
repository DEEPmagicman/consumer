//
//  EventTicket.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 01/02/23.
//

import Foundation

struct EventTicket: Codable {

    var id: String?
    var eventId: String?
    var tierName: String
    var price: Double?
    var issuedUnits: Int?
    var beginSale: String
    var endSale: String
    var soldUnits: Int?
    var customFee: CustomFee?
    var status: String
    var tierDescription: String?
    var isDeleted: Bool
    var sellingPaused: Bool
    var createdAt: String
    var updatedAt: String
    var eventTicketHasTier: [EventTicketHasTier]?
    var selectedTicketCount: Int?
    var remainingQuantity: Int? {
        (issuedUnits ?? 0) - (soldUnits ?? 0)
    }
    var SEFee: Double {
        return ((price ?? 0) <= 10) ? (Double(price ?? 0) * 0.1) : 1
    }
    var priceWithFees: Double {
        priceWithFee(Double(price ?? 0))
    }
    
    var customFee1: Double {
        guard let customFee = customFee, let type = customFee.typeEnum else {
            return 0
        }
        switch type {
        case .FLAT:
            return Double(customFee.value)
        case .PERCENTAGE:
            return (Double(price ?? 0) * Double(customFee.value) / 100)
        }
    }
    
    func priceWithFee(_ price: Double) -> Double {
        let stripeFee = (0.029 * (1 + 0) * (price + 1 + customFee1 ) + 0.3) / (1 - 0.029)
        return price + stripeFee + SEFee + customFee1
    }
    
    
   /*
    stripeFee = parseFloat(
        (
            0.029 * (price + customFee1) * (1 + taxRate(sales tax)) + 0.3
        ).toFixed(2),
    );
    totalProcessingFees = parseFloat((SEFee + stripeFee).toFixed(2));
    salesTax = parseFloat(
        ((amountTransferToVenueTemp + totalCustomFees) * taxRate(sales tax)).toFixed(2),
    );
    amountChargedToConsumer = parseFloat(
        (
            (amountTransferToVenue + totalCustomFees + salesTax) *
            Number(CoverTicketDollar.HUNDERED)
        ).toFixed(2),
    );
    */
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(tierName, forKey: .tierName)
        try container.encode(price, forKey: .price)
        try container.encode(issuedUnits, forKey: .issuedUnits)
        try container.encode(beginSale, forKey: .beginSale)
        try container.encode(endSale, forKey: .endSale)
        try container.encode(soldUnits, forKey: .soldUnits)
        try container.encodeIfPresent(customFee, forKey: .customFee)
        try container.encode(status, forKey: .status)
        try container.encode(tierDescription, forKey: .tierDescription)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(sellingPaused, forKey: .sellingPaused)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(eventTicketHasTier, forKey: .eventTicketHasTier)
    }
}

struct EventTicketHasTier: Codable {

    var id: String
    var eventId: String
    var price: Double
    var issuedUnits: Int
    var isDeleted: Bool
    var createdAt: String
    var updatedAt: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(price, forKey: .price)
        try container.encode(issuedUnits, forKey: .issuedUnits)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

struct CustomFee: Codable {

    var title: String
    var type: String
    var value: Double
    var typeEnum: CustomFeeType? {
        CustomFeeType(rawValue: type)
    }
    
    private enum CodingKeys: String, CodingKey {
        case title
        case value
        case type
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
        value = try values.decodeIfPresent(Double.self, forKey: .value) ?? 0
        type = try values.decodeIfPresent(String.self, forKey: .type) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encode(value, forKey: .value)
    }
}

enum CustomFeeType: String {
    case FLAT
    case PERCENTAGE
}

struct PaymentDetail: Codable {

    var subTotal: Double
    var processingFee: Double
    var customFee: Double
    var salesTax: Double?
    var total: Double
    var customFeeName: String?
    var discount: Double?
    var salesTaxName: String?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(subTotal, forKey: .subTotal)
        try container.encode(processingFee, forKey: .processingFee)
        try container.encode(customFee, forKey: .customFee)
        try container.encodeIfPresent(salesTax, forKey: .salesTax)
        try container.encode(total, forKey: .total)
        try container.encode(customFeeName, forKey: .customFeeName)
        try container.encodeIfPresent(discount, forKey: .discount)
        try container.encodeIfPresent(salesTaxName, forKey: .salesTaxName)
    }
}

/*
if (eventTicketSettings.isProcessingFeePassToCustomer) {
    if (
        eventTicketSettings.isCustomFeeTaxable === true &&
        eventTicketSettings.isProcessingFeeTaxable === false
    ) {
        stripeFee = parseFloat(
            (
                (this.stripePerc *
                 ((amountTransferToVenueTemp + totalCustomFees) * (1 + taxRate) +
                  SEFee) +
                 this.stripeFlat) /
                (1 - this.stripePerc)
            ).toFixed(2),
        );
        
        totalProcessingFees = parseFloat((SEFee + stripeFee).toFixed(2));
        salesTax = parseFloat(
            ((amountTransferToVenueTemp + totalCustomFees) * taxRate).toFixed(
                2,
            ),
        );
        amountChargedToConsumer = parseFloat(
            (
                (amountTransferToVenue +
                 totalProcessingFees +
                 totalCustomFees +
                 salesTax) *
                Number(CoverTicketDollar.HUNDERED)
            ).toFixed(2),
        );
    } else {
        stripeFee = parseFloat(
            (
                (this.stripePerc *
                 (1 + taxRate) *
                 (amountTransferToVenueTemp + SEFee + totalCustomFees) +
                 this.stripeFlat) /
                (1 - (1 + taxRate) * this.stripePerc)
            ).toFixed(2),
        );
        totalProcessingFees = parseFloat((SEFee + stripeFee).toFixed(2));
        salesTax = parseFloat(
            (
                (amountTransferToVenueTemp +
                 totalProcessingFees +
                 totalCustomFees) *
                taxRate
            ).toFixed(2),
        );
        amountChargedToConsumer = parseFloat(
            (
                (amountTransferToVenue +
                 totalProcessingFees +
                 totalCustomFees +
                 salesTax) *
                Number(CoverTicketDollar.HUNDERED)
            ).toFixed(2),
        );
    }
} else {
    stripeFee = parseFloat(
        (
            this.stripePerc *
            (amountTransferToVenueTemp + totalCustomFees) *
            (1 + taxRate) +
            this.stripeFlat
        ).toFixed(2),
    );
    totalProcessingFees = parseFloat((SEFee + stripeFee).toFixed(2));
    salesTax = parseFloat(
        ((amountTransferToVenueTemp + totalCustomFees) * taxRate).toFixed(2),
    );
    amountChargedToConsumer = parseFloat(
        (
            (amountTransferToVenue + totalCustomFees + salesTax) *
            Number(CoverTicketDollar.HUNDERED)
        ).toFixed(2),
    );
}
*/
