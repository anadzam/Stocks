//
//  StockDetailsViewController.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 9/13/22.
//
import SafariServices
import UIKit

final class StockDetailsViewController: UIViewController {
    //MARK: - properties
    private var symbol: String
    private var companyName: String
    private var candleStickData: [CandleStick]
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(
            NewsHeaderView.self,
            forHeaderFooterViewReuseIdentifier: NewsHeaderView.identifier
        )
        table.register(
            NewsStoryTableViewCell.self,
            forCellReuseIdentifier: NewsStoryTableViewCell.identifier
        )
        return table
        
    }()
    
    private var stories: [NewsStory] = []
    private var metrics: Metrics?
    
    //MARK: -  init
    
    init(
        symbol: String,
        companyName: String,
        candleStickData: [CandleStick] = []
    ) {
        self.symbol = symbol
        self.companyName = companyName
        self.candleStickData = candleStickData
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    //MARK: - lifecycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = companyName
        setUpCloseButton()
        //show view
        setUpTable()
        // financial data
        fetchFinancialData()
        //show a chart/graph
        
        //show news
        fetchNews()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    //MARK: -  private func
    
    private func setUpTable() {
        view.addSubviews(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: (view.width * 0.7) + 100)
        )
        
    }
    
    private func setUpCloseButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose)
        )
    }
    
    @objc private func didTapClose() {
        dismiss(animated: true, completion: nil)
    }
    private func fetchFinancialData() {
        let group  = DispatchGroup()
        
        //fetch candlesticks if needed
        if candleStickData.isEmpty {
            group.enter()
            APICaller.shared.marketData(for: symbol) { [weak self] result in
                defer {
                    group.leave()
                }
                switch result {
                case .success(let response):
                    self?.candleStickData = response.candleSticks
                case .failure(let error):
                    print(error)
                }
            }
        }
        //fetch financial metrics
        group.enter()
        APICaller.shared.financialMetrics(
            for: symbol) { [weak self] result in
                //leave from dispatch group
                defer {
                    group.leave()
                }
                switch result {
                case .success(let response):
                    let metrics = response.metric
                    self?.metrics = metrics
                case .failure(let error):
                    print(error)
                }
            }
        group.notify(queue: .main) { [weak self] in
            self?.renderChart()
        }
        
    }
    private func fetchNews() {
        APICaller.shared.news(for: .compan(symbol: symbol)) { [weak self] result in
            switch result {
            case .success(let stories):
                DispatchQueue.main.async {
                    self?.stories = stories
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print(error)
            }
        }
        
    }
    
    //display history graph
    private func renderChart() {
        //chartn VM \ collection financialmetricsVM
        let headerView = StockDetailHeaderView(
            frame: CGRect(x: 0,
                          y: 0,
                          width: view.width,
                          height: (view.width * 0.8) + 100
                         )
        )
        
       
        var viewModels = [MetricCollectionViewCell.ViewModel]()
        if let metrics = metrics {
            viewModels.append(.init(name: "52W High", value: "\(metrics.AnnualWeekHigh)"))
            viewModels.append(.init(name: "52W Low", value: "\(metrics.AnnualWeekLow)"))
            viewModels.append(.init(name: "52W Date", value: "\(metrics.AnnualWeekLowDate)"))
            viewModels.append(.init(name: "52W Return", value: "\(metrics.AnnualWeekPriceReturnDaily)"))
            viewModels.append(.init(name: "Beta", value: "\(metrics.beta)"))
            viewModels.append(.init(name: "10D Vol.", value: "\(metrics.TenDayAverageTradingVolume)"))
        }
        
        
        //comfigure func
        let change = getChangePercentage(symbol: symbol, data: candleStickData)
        headerView.configure(
            chartViewModel: .init(
                data: candleStickData.reversed().map { $0.close },
                showLegend: true,
                showAxis: true,
                fillColor: change < 0 ? .systemRed : .systemGreen            ),
            metricViewModels: viewModels)
        
        tableView.tableHeaderView = headerView
        
    }
    private func getChangePercentage(symbol: String, data: [CandleStick]) -> Double {
        //        let today = Date()
        let latestDate = Date().addingTimeInterval(-((3600 * 24) * 2))
//        let latestDate = data[0].date
        guard let latestClose = data.first?.close,
              let priorClose = data.first(where: {
                  !Calendar.current.isDate($0.date, inSameDayAs: latestDate)
              })?.close else {
            return 0
        }
        let diff = 1 - (priorClose/latestClose)
        return diff
    }
    
}

extension StockDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsStoryTableViewCell.identifier, for: indexPath) as? NewsStoryTableViewCell else {
            fatalError()
        }
        cell.configure(with: .init(model: stories[indexPath.row]))
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NewsStoryTableViewCell.preferredHeight
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: NewsHeaderView.identifier) as? NewsHeaderView else {
            return nil
        }
        header.delegate = self
        header.configure(with: .init(
            title: symbol.uppercased(),
            //displaing button only if the opened item is not iin watchlist
            shouldShowAddButton: !PersistenceManager.shared.watchlistContains(symbol: symbol)
        )
        )
        return header
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return NewsHeaderView.preferredHeight
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
                //for opening  website
        guard let url = URL(string: stories[indexPath.row].url) else {
            return
        }
        HapticsManager.shared.vibrateForSelection()
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }
}

extension StockDetailsViewController: NewsHeaderViewDelegate {
    func newsHeaderViewDidTapAddButton(_ headerView: NewsHeaderView) {
        HapticsManager.shared.vibrate(for: .success)
        
        headerView.button.isHidden = true
        PersistenceManager.shared.addToWatchlist(
            symbol: symbol,
            companyName: companyName
        )
        
        //creating alert
        let alert = UIAlertController(
            title: "Added to the Watchlist",
            message: "\(companyName) was successfully added to your watchlist",
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: "Dismiss",
            style: .cancel,
            handler: nil)
        )
        present(alert, animated: true)
    }
}
