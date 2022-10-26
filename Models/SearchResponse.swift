//
//  SearchResponse.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 10/4/22.
//

import Foundation

struct SearchResponse: Codable {
    let count: Int
    let result: [SearchResult]
}

struct SearchResult: Codable {
    let description: String
    let displaySymbol: String
    let symbol: String
    let type: String
}
