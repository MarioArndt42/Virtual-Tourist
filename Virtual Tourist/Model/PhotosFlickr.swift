//
//  PhotoFlickr.swift
//  Virtual Tourist
//
//  Created by Mario Arndt on 06.12.22.
//

import Foundation

struct PhotosFlickr: Codable {
    let photos: Photos
}

struct Photos: Codable {
    let pages: Int
    let photo: [Photo]
}

struct Photo: Codable {
    let url: String?
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case url = "url_sq"
        case title
    }
}
