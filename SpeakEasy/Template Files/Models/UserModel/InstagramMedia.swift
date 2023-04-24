//
//  InstagramMedia.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 02/01/23.
//

import Foundation
import UIKit

struct InstagramMedia {
   
    var name : String
    var url : String
    var image : UIImage? = nil
    var localIndex : Int = 0
    var isSelected = false
    
    enum CodingKeys: String, CodingKey {
        case NAME = "ImageName"
        case URL = "ImagesUrl"
        case IMAGE = "image"
        case IS_LOCAL = "is_local"
    }
    
    init() {
        name = ""
        url = ""
    }
}

extension InstagramMedia:Decodable, Encodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .NAME)
        url = try values.decode(String.self, forKey: .URL)
        if let imageData = try? values.decode(Data.self, forKey: .IMAGE) {
            image = UIImage(data: imageData)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var val = encoder.container(keyedBy: CodingKeys.self)
        try val.encode(name, forKey: .NAME)
        try val.encode(url, forKey: .URL)
        if let imageData = image?.sd_imageData() {
            try val.encode(imageData, forKey: .IMAGE)
        }
    }
}
