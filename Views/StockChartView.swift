//
//  StockChartView.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 10/9/22.
//

import UIKit
import Charts

class StockChartView: UIView {
    
    struct ViewModel {
        let data: [Double]
        let showLegend: Bool
        let showAxis: Bool
        let fillColor: UIColor
    }
    
    private let chartView: LineChartView = {
        let chartView = LineChartView()
        chartView.pinchZoomEnabled = false
        chartView.setScaleEnabled(true)
        chartView.xAxis.enabled = false
        chartView.drawGridBackgroundEnabled = false
        chartView.legend.enabled = false
        chartView.leftAxis.enabled = false
        chartView.rightAxis.enabled = false
        
        return chartView
    }()
    
    //MARK: - init

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews(chartView)
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        chartView.frame = bounds
    }
    
  //reset the chart view
    func reset() {
        chartView.data = nil
    }
    func configure(with viewModel: ViewModel) {
        var entries = [ChartDataEntry]()
        
        for (index, value) in viewModel.data.enumerated() {
            entries.append(.init(
                x: Double(index),
                y: value))
        }
        
        chartView.rightAxis.enabled = viewModel.showAxis
        chartView.legend.enabled = viewModel.showLegend
        
        
        let dataSet = LineChartDataSet(entries: entries, label: "One week")
        dataSet.fillColor = viewModel.fillColor
        dataSet.drawFilledEnabled = true
        dataSet.drawIconsEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.drawCirclesEnabled = false
        let data = LineChartData(dataSet: dataSet)
        chartView.data = data
    }
}
