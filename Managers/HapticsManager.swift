//
//  HapticsManager.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 9/13/22.
//

import Foundation
import UIKit

final class HapticsManager {
    static let shared = HapticsManager()
    private init() {}
    
    //MARK: - public
    
    public func vibrateForSelection() {
        //vibrate lightly for selection tap interaction
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    
    
    /// vibrate for type
    /// - Parameter type: type to vibrate for cell
    public func vibrate(for type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

