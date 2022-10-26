//
//  TopStoriesNewViewController.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 9/13/22.
//

import UIKit
import SafariServices

class NewsViewController: UIViewController {
    
    //using '' because type is keyword in swift
    enum TypeOfStories {
    case topStories
    case compan(symbol: String)
        
        var title: String {
            switch self {
            case .topStories:
                return "Top Stories"
            case .compan(let symbol):
                return symbol.uppercased()
            }
        }
        
    }
    
    //MARK: - properties
    private var stories = [NewsStory]()
        
    
    private let type: TypeOfStories
    

    
    let tableView: UITableView = {
        let table = UITableView()
        //register cell, header
        table.register(NewsStoryTableViewCell.self, forCellReuseIdentifier: NewsStoryTableViewCell.identifier)
        table.register(NewsHeaderView.self,
                       forHeaderFooterViewReuseIdentifier: NewsHeaderView.identifier)
        table.backgroundColor = .clear
        
        return table
    }()
    
    
    //MARK: - init
    init(type: TypeOfStories) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    //MARK: - LyfeCycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTable()
        fetchNews()
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    //MARK: - private funcs
    
    private func setUpTable() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    private func fetchNews() {
        APICaller.shared.news(for: type) { [weak self] result in
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
    private func open(url: URL) {
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
        
    }
    
}

extension NewsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        stories.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NewsStoryTableViewCell.identifier, for: indexPath) as? NewsStoryTableViewCell else {
            fatalError()
        }
        cell.configure(with: .init(model: stories[indexPath.row]))
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: NewsHeaderView.identifier) as? NewsHeaderView else {
            return nil
        }
        //if bug check this and write TypeOfStories istead of type
        header.configure(with: .init(title: self.type.title, shouldShowAddButton: false))
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NewsStoryTableViewCell.preferredHeight
    }
  
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return NewsHeaderView.preferredHeight
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        HapticsManager.shared.vibrateForSelection()
        //open news story
        let story = stories[indexPath.row]
        guard let url = URL(string: story.url) else {
            presetFailedToOpenAlert()
            return
        }
        open(url: url)
    }
    
    private func presetFailedToOpenAlert() {
        HapticsManager.shared.vibrate(for: .error)
        
        let alert = UIAlertController(title: "Unable to open",
                                      message: "Unable to open the link",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        
        present(alert, animated: true)
    }
}

