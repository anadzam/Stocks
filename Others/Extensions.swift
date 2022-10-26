//
//  Extensions.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 9/16/22.
//

import Foundation
import UIKit

//MARK: - notification

extension Notification.Name {
    /// Notification for when symbol gets added to watchlist
    static let didAddToWatchList = Notification.Name("didAddToWatchList")
}

//number formater
extension NumberFormatter {
    
    /// formatter for percent style
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    /// formatter for decimal style
    static let numberFormatter: NumberFormatter = {

        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

//imageView
extension UIImageView {
    
    /// sets image from remote url
    /// - Parameter url: URL to dercg
    func setImage(with url: URL?) {
        guard let url = url else {
            return
        }
        DispatchQueue.global(qos: .userInteractive).async {
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                guard let data = data, error == nil else {
                    return
                }
                DispatchQueue.main.async {
                    self?.image = UIImage(data: data)
                }
                
            }
            task.resume()
        }
    }
}

//MARK: - string



extension String {
    
    /// cretating string from time interval
    /// - Parameter timeInterval: time interval since 1970
    /// - Returns: formatted strinf
    static func string(from timeInterval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        return DateFormatter.prettyDateFormatter.string(from: date)
    }
    
    
    /// precentahe fromatted string
    /// - Parameter double: double to fromat
    /// - Returns: string in percentage formate
    static func percentage(from double: Double) -> String? {
        let formatter = NumberFormatter.percentFormatter
        return formatter.string(from: NSNumber(value: double)) ?? "\(double)"
    }
    
    
    /// format number to string
    /// - Paramformat numbereter number: number to form
    /// - Returns: formatted string
    static func formatted(number: Double) -> String? {
        let formatter = NumberFormatter.numberFormatter
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
//MARK: - date formatter


extension DateFormatter {
    static let newsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        return formatter
    }()
    
    static let prettyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}


//MARK: - add subview

extension UIView {
    func addSubviews(_ views: UIView...){
        views.forEach {
            addSubview($0)
        }
    }
}
//MARK: - frame extensions
extension UIView {
    var width: CGFloat {
        frame.size.width
    }
    var height: CGFloat {
        frame.size.height
    }
    var left: CGFloat {
        frame.origin.x
    }
    var right: CGFloat {
        left + width
    }
    var top: CGFloat {
        frame.origin.y
    }
    var bottom: CGFloat {
        top + height
    }
}
