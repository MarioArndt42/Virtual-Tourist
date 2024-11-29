//
//  ClientFlickr.swift
//  Virtual Tourist
//
//  Created by Mario Arndt on 06.12.22.
//

import Foundation

class ClientFlickr {
    
    enum CustomError: Error {
        case decodingError
        case networkError
    }
    
    // Insert API Key and Secret
    static let apiKey = ***************
    static let secret = ***************
    
    enum Endpoint {
        static let base = "https://www.flickr.com/services/rest/?method=flickr.photos.search"
        
        case downloadList
        case downloadPhoto
        
        private var stringValue: String {
            switch self {
            case .downloadList: return Endpoint.base
            case .downloadPhoto: return Endpoint.base
            }
        }
        
        var url: URL { return URL(string: stringValue)! }
    }
    
    // Download list of photos
    class func downloadList(lat: Double, lon: Double, page: Int, completion: @escaping (Result<Photos, CustomError>) -> Void) {
        
        let stringURL = String(Endpoint.base
                               + "&extras=url_sq&api_key=\(apiKey)"
                               + "&lat=\(lat)"
                               + "&lon=\(lon)"
                               + "&per_page=30"
                               + "&page=\(page)"
                               + "&format=json&nojsoncallback=1")
        
        var request = URLRequest(url: URL(string: stringURL)!)
        request.httpMethod = "GET"
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    completion (.failure(.networkError))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(PhotosFlickr.self, from: data)
                    completion(.success(response.photos))
                } catch {
                    completion (.failure(.decodingError))
                }
            }
        }
        task.resume()
    }
    
    // Download single photo
    class func downloadImage(request: URL, completion: @escaping (Result<Data, CustomError>) -> Void) {
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    completion (.failure(.networkError))
                    return
                }
                completion(.success(data))
            }
        }
        task.resume()
    }
    
}





