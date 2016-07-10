//
//  AppearanceProvider.swift
//  swift-2048
//
//  Created by Austin Zheng on 6/3/14.
//  Copyright (c) 2014 Austin Zheng. Released under the terms of the MIT license.
//

import UIKit

protocol AppearanceProviderProtocol: class {
  func tileColor(value: Int) -> UIColor
  func numberColor(value: Int) -> UIColor
  func fontForNumbers() -> UIFont
}

class AppearanceProvider: AppearanceProviderProtocol {
  // Type properties for the UIColors used in this class. (language reference) "Stored type properties
  // are lazily initialized on their first access. They are guaranteed to be initialized only once, even when 
  // accessed by multiple threads simultaneously, and they do not need to be marked with the lazy modifier.
  static let color2 = UIColor(red: 238.0/255.0, green: 228.0/255.0, blue: 218.0/255.0, alpha: 1.0)
  static let color4 = UIColor(red: 237.0/255.0, green: 224.0/255.0, blue: 200.0/255.0, alpha: 1.0)
  static let color8 = UIColor(red: 242.0/255.0, green: 177.0/255.0, blue: 121.0/255.0, alpha: 1.0)
  static let color16 = UIColor(red: 245.0/255.0, green: 149.0/255.0, blue: 99.0/255.0, alpha: 1.0)
  static let color32 = UIColor(red: 246.0/255.0, green: 124.0/255.0, blue: 95.0/255.0, alpha: 1.0)
  static let color64 = UIColor(red: 246.0/255.0, green: 94.0/255.0, blue: 59.0/255.0, alpha: 1.0)
  static let color128up = UIColor(red: 237.0/255.0, green: 207.0/255.0, blue: 114.0/255.0, alpha: 1.0)
  static let textColor = UIColor(red: 119.0/255.0, green: 110.0/255.0, blue: 101.0/255.0, alpha: 1.0)

  // Provide a tile color for a given value
  func tileColor(value: Int) -> UIColor {
    switch value {
    case 2:
      return AppearanceProvider.color2
    case 4:
      return AppearanceProvider.color4
    case 8:
      return AppearanceProvider.color8
    case 16:
      return AppearanceProvider.color16
    case 32:
      return AppearanceProvider.color32
    case 64:
      return AppearanceProvider.color64
    case 128, 256, 512, 1024, 2048:
      return AppearanceProvider.color128up
    default:
      return UIColor.whiteColor()
    }
  }
  
  // Provide a numeral color for a given value
  func numberColor(value: Int) -> UIColor {
    switch value {
    case 2, 4:
      return AppearanceProvider.textColor
    default:
      return UIColor.whiteColor()
    }
  }

  // Provide the font to be used on the number tiles
  func fontForNumbers() -> UIFont {
    return UIFont(name: "HelveticaNeue-Bold", size: 20) ?? UIFont.systemFontOfSize(20)
  }
}
