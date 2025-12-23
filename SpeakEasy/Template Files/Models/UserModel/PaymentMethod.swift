//
//  PaymentMethod.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 18/04/23.
//

import UIKit

struct PaymentMethod: Codable {

    var id: String
    var brand: String
    var expMonth: Int
    var expYear: Int
    var last4: String
//    var type: String

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case brand = "brand"
        case expMonth = "exp_month"
        case expYear = "exp_year"
        case last4 = "last4"
//        case type = "type"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(brand, forKey: .brand)
        try container.encode(expMonth, forKey: .expMonth)
        try container.encode(expYear, forKey: .expYear)
        try container.encode(last4, forKey: .last4)
//        try container.encode(type, forKey: .type)
    }
}

extension Int {
    var displayMonth: String {
        String(format: "%02d", self)
    }
}

extension Int {
    var displayYear: String {
        String("\(self)".dropFirst(2))
    }
}

extension String {
    var paymentImg: UIImage? {
        switch self {
        case "visa":
            return Constant.Card.visa
        case "mastercard":
            return Constant.Card.masterCard
        case "amex":
            return Constant.Card.amex
        case "discover":
            return Constant.Card.discover
        case "diners":
            return Constant.Card.diners
        case "jcb":
            return Constant.Card.jcb
        default:
            return Constant.Card.cardIc
        }
    }
}
