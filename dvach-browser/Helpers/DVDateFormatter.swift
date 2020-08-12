//
//  DVDateFormatter.swift
//  dvach-browser
//
//  Created by Dmitry on 12.08.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation

@objc class DVDateFormatter: NSObject {
    @objc class func date(fromTimestamp timestamp: Int) -> String? {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))

        let units: Set<Calendar.Component> = [.second, .minute, .hour, .day, .month]
        let components = Calendar.current.dateComponents(
            units,
            from: date,
            to: Date())

        if let month = components.month, month > 0 {
            let formatter = DateFormatter()
            formatter.timeZone = NSTimeZone.system
            formatter.dateFormat = "dd.MM.yy"
            return formatter.string(from: date)
        } else if let day = components.day, day > 0 {
            return String(format: NSLS("DATE_FORMATTER_DAYS"), day)
        } else if let hour = components.hour, hour > 0 {
            return String(format: NSLS("DATE_FORMATTER_HOURS"), hour)
        } else if let minute = components.minute, minute > 0 {
            return String(format: NSLS("DATE_FORMATTER_MINS"), minute)
        } else if let second = components.second, second > 15 {
            return String(format: NSLS("DATE_FORMATTER_SECS"), second)
        } else {
            return NSLS("DATE_FORMATTER_NOW")
        }
    }
}
