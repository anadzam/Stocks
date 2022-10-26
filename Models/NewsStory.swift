//
//  NewsStory.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 10/6/22.
//

import Foundation

struct NewsStory: Codable {
    
    let category: String
    let datetime: TimeInterval
    let headline: String
//    let id: TimeInterval
    let image: String
    let related: String
    let source: String
    let summary: String
    let url: String
      
}
