//
//  File.swift
//  JarJa
//
//  Created by Mac Book on 01/01/2020.
//  Copyright © 2020 Code Creators. All rights reserved.
//

import Foundation
import UIKit

struct BookingTabBarOption {
    var label = ""
    var count = 0
    var isSelected = false
}
struct TabBarOption {
    var label = ""
    var count = 0
    var index = 0
    var icon: UIImage?
    var selectedIcon: UIImage?
    var isSelected = false
}
struct HeaderOption {
    var label = ""
    var icon: UIImage?
}
struct EventHeaderOptions {
    var label = ""
    var isSelected = false
}
struct AddressAttributes{
  var compactAddress: String?
  var country: String?
  var state: String?
  var city: String?
  var latitude: Double?
  var longitude: Double?
}
struct OrderCells{
    var flag = false
}
struct MenuCells{
    var flag = false
}
struct BookingsDataSet {
    var brand: UIImage?
    var bookingName: String?
    var performerCover: UIImage?
    var isTicket = false
    var date: String?
    var status: BookingStatusType?
}
struct StatusAndRewardDataSet {
    var brand: UIImage?
    var eventCover: UIImage?
    var isPerformer = false
    var isTable = false
    var isGroupInvite = false
    var isTicket = false
    var venueName: String?
    var performerName: String?
    var ticketDescription: String?
    var date: String?
    var rewardDescription: String?
}

struct OthersInvites{
    var image: UIImage?
    var name: String?
    var percentage: String?
    var isVerified: Bool?
}
