//
//  MovieServiceEndpoint.swift
//  MovieSearch
//
//  Created by Nick on 17/09/2021.
//

import Foundation

// MARK: - Movie Service Endpoint

enum MovieServiceEndpoint {
    case titleSearch(title: String, page: Int)
    case getDetails(imbdId: String)
    case getPoster(imdbId: String)
}

// MARK: - URL Construction

extension MovieServiceEndpoint {

    var url: URL? {
        guard
            var components = URLComponents(
                url: self.baseUrl,
                resolvingAgainstBaseURL: true
            ),
            let queryItems = self.queryItems
        else {
            return nil
        }

        components.queryItems = queryItems
        return components.url
    }

}

// MARK: - Construction Helpers

private extension MovieServiceEndpoint {

    static let apiKeyParameter = "apikey"
    static let titleSearchParameter = "s"
    static let pageParameter = "page"
    static let imdbSearchParameter = "i"
    static let plotParameter = "plot"
    static let fullPlotOption = "full"

    var queryItems: [URLQueryItem]? {
        switch self {

        case .titleSearch(let title, let page):
            let search = title
                .split(separator: " ")
                .compactMap { word in
                    word.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .joined(separator: "*")

            guard let encodedTitle = percentEncode(string: search) else {
                return nil
            }

            let titleItem = URLQueryItem(
                name: MovieServiceEndpoint.titleSearchParameter,
                value: encodedTitle + "*"
            )

            let pageItem = URLQueryItem(
                name: MovieServiceEndpoint.pageParameter,
                value: String(page)
            )

            return [ apiKeyQueryItem, pageItem, titleItem ]

        case .getDetails(let imdbId):
            guard let imdbQueryItem = imdbIdQueryItem(imdbId: imdbId) else {
                return nil
            }

            let fullPlotItem = URLQueryItem(
                name: MovieServiceEndpoint.plotParameter,
                value: MovieServiceEndpoint.fullPlotOption
            )

            return [ apiKeyQueryItem, imdbQueryItem, fullPlotItem ]

        case .getPoster(let imdbId):
            guard let imdbQueryItem = imdbIdQueryItem(imdbId: imdbId) else {
                return nil
            }

            return [ apiKeyQueryItem, imdbQueryItem ]
        }
    }

    func imdbIdQueryItem(imdbId: String) -> URLQueryItem? {
        guard let encodedId = percentEncode(string: imdbId) else {
            return nil
        }

        return URLQueryItem(
            name: MovieServiceEndpoint.imdbSearchParameter,
            value: encodedId
        )
    }

    var apiKeyQueryItem: URLQueryItem {
        URLQueryItem(
            name: MovieServiceEndpoint.apiKeyParameter,
            value: MovieServiceEndpoint.apiKey
        )
    }

    var baseUrl: URL {
        switch self {
        case .titleSearch, .getDetails: return MovieServiceEndpoint.dataUrl
        case .getPoster: return MovieServiceEndpoint.posterUrl
        }
    }

    func percentEncode(string: String) -> String? {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}

// MARK: - Base URLs

private extension MovieServiceEndpoint {

    static let apiKey = "--------"

    static let dataUrl: URL = {
        let path = "http://www.omdbapi.com/"
        guard let url = URL(string: path) else {
            fatalError("Could not make data url.")
        }

        return url
    }()

    static let posterUrl: URL = {
        let path = "http://img.omdbapi.com/"
        guard let url = URL(string: path) else {
            fatalError("Could not make poster url.")
        }

        return url
    }()

}
