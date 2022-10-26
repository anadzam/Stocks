//
//  SearchResultTableViewCell.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 9/16/22.
//

import UIKit

class SearchResultTableViewCell: UITableViewCell {

  static let identifier = "SearchResultTableViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
}
