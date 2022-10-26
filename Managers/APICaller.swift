//
//  APICaller.swift
//  Stocks
//
//  Created by Ana Dzamelashvili on 9/13/22.
//

import Foundation

final class APICaller {
    static let shared = APICaller()
    
    private struct Constants {
        static let apiKey = "ccs6jtqad3ifi21d9l00ccs6jtqad3ifi21d9l0g"
        static let sandboxApiKey = ""
        static let baseUrl = "https://finnhub.io/api/v1/"
        static let day: TimeInterval = 3600 * 24
    }
    private init() {}
    
    //MARK: - Public
    
    public func search(
        query: String,
        completion: @escaping (Result<SearchResponse, Error>) -> Void
    ) {
        guard let safeQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        
        request(
            url: url(
                for: .search,
                queryParams: ["q": safeQuery] ),
            expecting: SearchResponse.self,
            completion: completion
            
        )
    }
    
    
    //MARK: - news
    
    public func news(
        for type: NewsViewController.TypeOfStories,
        completion: @escaping (Result<[NewsStory], Error>) -> Void
    ){
        switch type {
        case .topStories:
            request(
                url: url(for: .topStories, queryParams: ["category": "general"]),
                expecting: [NewsStory].self,
                completion: completion
            )
        case .compan(let symbol):
            let today = Date()
            //number of seconds in a week
            let oneWeekBefore = today.addingTimeInterval(-(Constants.day * 7))
            request(
                url: url(for: .companyNews, queryParams: ["symbol": symbol,
                                                          "from": DateFormatter.newsDateFormatter.string(from: oneWeekBefore),
                                                          "to": DateFormatter.newsDateFormatter.string(from: today)
                                                         ]
                        ),
                expecting: [NewsStory].self,
                completion: completion
            )
        }
        
        
    }
    
    public func marketData(
        for symbol: String,
        numberOfDays: TimeInterval = 7,
        completion: @escaping(Result<MarketDataResponse, Error>) -> Void
    )
    {
        let today = Date().addingTimeInterval(-(Constants.day))
        //number of seconds in a week
        let prior = today.addingTimeInterval(-(Constants.day * numberOfDays))
        
        request(url: url(for: .marketData,
                         queryParams: [
                            "symbol": symbol,
                            "resolution": "1",
                            "from": "\(Int(prior.timeIntervalSince1970))",
                            "to": "\(Int(today.timeIntervalSince1970))"
                         ]
                        ),
                expecting: MarketDataResponse.self,
                completion: completion)
        
        
    }
    
    
    public func financialMetrics(
        for symbol: String,
        completion: @escaping (Result<FinancialMetricsResponse, Error>) -> Void
    ) {
        request(
            url: url(
                for: .financials,
                queryParams: ["symbol" : symbol, "metric": "all"]
        ),
                expecting: FinancialMetricsResponse.self,
                completion: completion
        )
        
    }
    
    //MARK: - Private
    
    private enum EndPoint: String {
        case search
        case topStories = "news"
        case companyNews = "company-news"
        case marketData = "stock/candle"
        case financials = "stock/metric"
    }
    
    private enum APIError: Error {
        case noDataReturned
        case invalidUrl
    }
    
    private func url(for endpoint: EndPoint,
                     queryParams: [String: String] = [:]) -> URL? {
        var urlString = Constants.baseUrl + endpoint.rawValue
        var queryItems = [URLQueryItem]()
        //add any params
        for (name, value) in queryParams {
            queryItems.append(.init(name: name, value: value))
        }
        
        //add token
        
        queryItems.append(.init(name: "token", value: Constants.apiKey))
        //add query items to suffix
        let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
        urlString += "?" + queryString
        
        //    print("\(urlString)")
        
        return URL(string: urlString)
    }
    
    //generic way to make API calls
    
    private func request<T: Codable>(url: URL?,
                                     expecting: T.Type,
                                     completion: @escaping(Result<T, Error>) -> Void) {
        guard let url = url else {
            //invalid url
            completion(.failure(APIError.invalidUrl))
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                if let error = error {
                    completion(.failure(error))
                }else {
                    completion(.failure(APIError.noDataReturned))
                }
                return
            }
            do {
                let result = try JSONDecoder().decode(expecting, from: data)
                completion(.success(result))
            }
            catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    
    
}
