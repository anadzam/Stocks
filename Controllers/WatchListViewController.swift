//
//  ViewController.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 9/13/22.
//

import UIKit
import FloatingPanel


class WatchListViewController: UIViewController {
    
    private var searchTimer: Timer?
    
    private var panel: FloatingPanelController?
    //MARK: - model
    
    static var maxChangeWidth: CGFloat = 0
    
    private var watchlistMap: [String: [CandleStick]] = [:]
    
    //MARK: - viewModels
    private var viewModels: [WatchListTableViewCell.ViewModel] = []
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(WatchListTableViewCell.self, forCellReuseIdentifier: WatchListTableViewCell.identifier)
        return table
    }()
    
    //instance of observer
    
    private var observer: NSObjectProtocol?
    //MARK: - lifecycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpSearchController()
        setUpTableView()
        fetchWatchlistData()
        setUpFloatingPanel()
        setUpTitleView()
        setUpObserver()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    
    
    //MARK: - private func
    
        //notification observer function
    private func setUpObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: .didAddToWatchList,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.viewModels.removeAll()
            self?.fetchWatchlistData()
        }
        
    }

    
    private func setUpFloatingPanel() {
        let vc = NewsViewController(type: .topStories)
        let panel = FloatingPanelController()
        panel.surfaceView.backgroundColor = .secondarySystemBackground
        panel.set(contentViewController: vc)
        panel.addPanel(toParent: self)
        panel.delegate = self
        panel.track(scrollView: vc.tableView)
        
    }
    
    private func fetchWatchlistData() {
        let symbols = PersistenceManager.shared.watchlist
        let group = DispatchGroup()
        
        //only fetch if the symbol is nil
        for symbol in symbols where watchlistMap[symbol] == nil {
            group.enter()
            //fetch market data per symnol
            
            APICaller.shared.marketData(for: symbol) { [weak self] result in
                defer {
                    group.leave()
                }
                switch result {
                case .success(let data):
                    let candleSticks = data.candleSticks
                    self?.watchlistMap[symbol] = candleSticks
                case .failure(let error):
                    print(error)
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.createViewModels()
            self?.tableView.reloadData()
            
        }
    }
    
    private func createViewModels() {
        var viewModels = [WatchListTableViewCell.ViewModel]()
        for (symbol, candleSticks) in watchlistMap {
            let changePercentage = getChangePercentage(symbol: symbol, data: candleSticks)
            viewModels.append(
                .init(symbol: symbol,
                      companyName: UserDefaults.standard.string(forKey: symbol) ?? "Company",
                      price: getLatestClosingPrice(from: candleSticks),
                      changeColor: changePercentage < 0 ? .systemRed : .systemGreen,
                      changePercentage: .percentage(from: changePercentage) ?? "\(changePercentage)", chartViewModel: .init(
                        data: candleSticks.reversed().map { $0.close },
                        showLegend: false,
                        showAxis: false,
                        fillColor: changePercentage < 0 ? .systemRed : .systemGreen
                      )
                     )
            )
        }
        
        self.viewModels = viewModels
    }
    
    private func getChangePercentage(symbol: String, data: [CandleStick]) -> Double {
        //        let today = Date()
//        let latestDate = Date().addingTimeInterval(-((3600 * 24) * 2))
        let latestDate = data[0].date
        guard let latestClose = data.first?.close,
              let priorClose = data.first(where: {
                  !Calendar.current.isDate($0.date, inSameDayAs: latestDate)
              })?.close else {
            return 0
        }
        let diff = 1 - (priorClose/latestClose)
        return diff
    }
    
    private func getLatestClosingPrice(from data: [CandleStick]) -> String {
        guard let closingPrice = data.first?.close else {
            return ""
        }
        return .formatted(number: closingPrice) ?? "\(closingPrice)"
    }
    
    private func setUpTableView() {
        view.addSubviews(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    private func setUpTitleView() {
        let titleView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: navigationController?.navigationBar.height ?? 100)
        )
        
        
        let label = UILabel(frame: CGRect(x: 10,
                                          y: 0,
                                          width: titleView.width - 20,
                                          height: titleView.height))
        label.text = "Stocks"
        label.font = .systemFont(ofSize: 32, weight: .medium)
        titleView.addSubview(label)
        navigationItem.titleView = titleView
        
    }
    private func setUpSearchController() {
        let resultVC = SearchResultsViewController()
        let searchVC = UISearchController(searchResultsController: resultVC)
        searchVC.searchResultsUpdater = self
        resultVC.delegate = self
        navigationItem.searchController = searchVC
    }
    
}

extension WatchListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text,
              let resultsVC = searchController.searchResultsController as? SearchResultsViewController,
              !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        
        //reset timer
        searchTimer?.invalidate()
        
        //kick of new timer
        //optimize to reduce number of searches, when user stops typinig
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { _ in
            //call api to search
            APICaller.shared.search(query: query) { result in
                switch result {
                case .success(let response):
                    //update results  contorle
                    DispatchQueue.main.async {
                        resultsVC.update(with: response.result)
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        resultsVC.update(with: [])
                    }
                    print(error)
                    
                }
            }
        })
    }
}

extension WatchListViewController: SearchResultsViewControllerDelegate {
    func SearchResultsViewControllerDidSelect(searchResult: SearchResult) {
        navigationItem.searchController?.searchBar.resignFirstResponder()
        
        HapticsManager.shared.vibrateForSelection()
        
        let vc = StockDetailsViewController(
            symbol: searchResult.displaySymbol,
            companyName: searchResult.description
        )
        let navVC = UINavigationController(rootViewController: vc)
        vc.title = searchResult.description
        present(navVC, animated: true)
    }
}

extension WatchListViewController: FloatingPanelControllerDelegate {
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        navigationItem.titleView?.isHidden = fpc.state == .full
    }
}

extension WatchListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WatchListTableViewCell.identifier, for: indexPath) as? WatchListTableViewCell else {
            fatalError()
        }
        cell.delegate = self
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return WatchListTableViewCell.preferredHeight
    }
    
    
    //swipe to delete
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            //update persistence
            PersistenceManager.shared.removeFromWatchlist(symbol: viewModels[indexPath.row].symbol)
            //update viemodel
            viewModels.remove(at: indexPath.row)
            //delete row
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            tableView.endUpdates()
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        HapticsManager.shared.vibrateForSelection()

        //open details for selection
        let viewModel = viewModels[indexPath.row]
        let vc = StockDetailsViewController(symbol: viewModel.symbol,
                                            companyName: viewModel.companyName,
                                            candleStickData: watchlistMap[viewModel.symbol] ?? [])
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
}

extension WatchListViewController: WatchListTableViewCellDelegate {
    func didUpdateMaxWidth() {
        //optimize only refresh raws prior to the current row that changes the max width
        tableView.reloadData()
    }
}
