//
//  PersistenceManager.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 9/13/22.
//

import Foundation
// ["AAPL", "MSFT", "SNAP"]
//[AAPL: Apple Inc.

final class PersistenceManager {
    static let shared = PersistenceManager()
    private let userDefaults: UserDefaults = .standard
    
    private struct Constants {
        static let onboardedKey = "hasOnboarded"
        static let watchlistKey = "watchList"
        
    }
    
    private init() {}
    
    //MARK: - public
    public var watchlist: [String] {
        if !hasOnboarded {
            userDefaults.set(true, forKey: Constants.onboardedKey)
            setUpDefaults()
            
        }
        return userDefaults.stringArray(forKey: Constants.watchlistKey) ?? []
    }
    
    //only display watchlist button if the item is not already in watchlist
    
    public func watchlistContains(symbol: String) -> Bool {
        return watchlist.contains(symbol)
    }
    
    public func addToWatchlist(symbol: String, companyName: String) {
        var current = watchlist
        current.append(symbol)
        userDefaults.set(current, forKey: Constants.watchlistKey)
        
        
        userDefaults.set(companyName, forKey:  symbol)
            // notification
        NotificationCenter.default.post(name: .didAddToWatchList, object: nil)
        
    }
    public func removeFromWatchlist(symbol: String) {
        var newList = [String]()
        userDefaults.set(nil, forKey: symbol)
        
        for item in watchlist where item != symbol {
            newList.append(item)
        }
        userDefaults.set(newList, forKey: Constants.watchlistKey)
    }
    
    //MARK: - public
    
    private var hasOnboarded: Bool {
        return userDefaults.bool(forKey: Constants.onboardedKey)
    }
    
    private func setUpDefaults() {
        let map: [String: String] = [
            "AAPL": "Apple Inc.",
            "MSFT": "Microsoft Corporation",
            "SNAP": "Snap Inc.",
            "GOOG": "Alphabet",
            "AMZN": "Amazon.com, Inc.",
            "WORK": "Slack Technologies",
            "FB": "Meta Platforms, Inc.",
            "NVDA": "Nvidia Inc.",
            "NKE": "Nike",
            "PINS": "Pinterest Inc."
        ]
        
        let symbols = map.keys.map { $0 }
        userDefaults.set(symbols, forKey: Constants.watchlistKey)
        
        for (symbol, name) in map {
            userDefaults.set(name, forKey: symbol)
        }
    }
    
}
