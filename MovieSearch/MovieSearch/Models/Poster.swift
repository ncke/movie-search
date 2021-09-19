//
//  Poster.swift
//  MovieSearch
//
//  Created by Nick on 18/09/2021.
//

import Foundation

// MARK: - Poster

class Poster: Codable {
    let imdbId: String
    let imageData: Data

    init(imdbId: String, imageData: Data) {
        self.imdbId = imdbId
        self.imageData = imageData
    }
}
