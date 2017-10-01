//
//  Extensions.swift
//  EpicSkies
//
//  Created by Grant Emerson on 9/26/17.
//  Copyright © 2017 com.CelebrityGames. All rights reserved.
//  Membership to all Targets

import Foundation

// MARK: - Universal Extensions

extension Date {
    func timeAgoDisplay() -> String {
        
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        if secondsAgo < minute {
            return "\(secondsAgo)s"
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute)m"
        } else if secondsAgo < day {
            return "\(secondsAgo / hour)h"
        } else if secondsAgo < week {
            return "\(secondsAgo / day)d"
        }
        
        return "\(secondsAgo / week)w"
    }
}

extension String {
    func nilIfEmpty() -> String? {
        guard !self.isEmpty else { return nil }
        return self
    }
}

