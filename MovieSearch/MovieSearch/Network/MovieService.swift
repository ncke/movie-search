//
//  MovieService.swift
//  MovieSearch
//
//  Created by Nick on 17/09/2021.
//

import Foundation

// MARK: - Movie Service Delegate

protocol MovieServiceDelegate: AnyObject {

    func movieService(
        _ movieService: MovieService,
        didObtainMovies movies: [Movie]
    )

    func movieService(
        _ movieService: MovieService,
        didEncounterError error: MovieService.NetworkError
    )

}

// MARK: - Movie Service

class MovieService {

    /// A sequential queue to manage search activity.
    private let searchQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    /// A concurrent queue to manage poster fetches.
    private let posterQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 4
        return queue
    }()

    /// Delegate to receive movie search results.
    weak var delegate: MovieServiceDelegate?

}

// MARK: - Movie Search

extension MovieService {

    /// Start a search for the given string.
    func search(title: String) throws {
        guard delegate != nil else {
            // Programmer error.
            fatalError()
        }

        // New search.
        cancelSearchNetworking()

        // Commence the paged search.
        try pagedSearch(title: title, page: 1)
    }

}

// MARK: - Paged Movie Searching

private extension MovieService {
    /// The number of movies in each page of data returned by the service.
    static let pageSize = 10

    /// The maximum number of pages to automatically fetch from the service.
    static let maximumPageFetch = 10

    /// The number of pages to fetch with high-frequency polls
    static let highFrequencyPages = 3

    /// The poll interval for high-frequency polling.
    static let highFrequencyInterval = 0.5

    /// The poll interval for low-frequency polling.
    static let lowFrequencyInterval = 3.0

    func pagedSearch(title: String, page: Int) throws {
        guard
            let url = MovieServiceEndpoint.titleSearch(
                title: title,
                page: page
            ).url
        else {
            throw NetworkError.invalidParameter
        }

        let requestCompletion: (Result<MovieSearch, NetworkError>) -> Void = {
            result in

            switch result {

            case .success(let movieSearch):
                // Pass the results to the delegate.
                self.delegate?.movieService(
                    self,
                    didObtainMovies: movieSearch.search ?? []
                )

                let nextPage = page + 1
                guard
                    nextPage <= MovieService.maximumPageFetch,
                    self.hasMorePages(
                        movieSearch: movieSearch,
                        currentPage: page
                    )
                else {
                    // No further polls.
                    return
                }

                // Arrange to poll for the next page.
                let interval = self.pollInterval(page: nextPage)

                DispatchQueue.global(qos: .userInitiated).asyncAfter(
                    deadline: .now() + interval
                ) {
                    try? self.pagedSearch(title: title, page: nextPage)
                }

            case .failure(let networkError):
                // Report the failure to the delegate, paged searching ends.
                self.delegate?.movieService(
                    self,
                    didEncounterError: networkError
                )
            }
        }

        let operation = MovieServiceOperation(
            requestUrl: url,
            requestCompletion: requestCompletion
        )

        searchQueue.addOperation(operation)
    }

    /// Returns true if the service has more pages for this search,
    /// false otherwise.
    func hasMorePages(
        movieSearch: MovieSearch,
        currentPage: Int
    ) -> Bool {
        // Determine how many results are available on the service.
        guard let availableResults = movieSearch.totalResults else {
            return false
        }

        // Determine how many results we have fetched (note: the over-estimate
        // for partial pages is not significant to the functionality).
        let fetchedResults = currentPage * MovieService.pageSize

        return availableResults > fetchedResults
    }

    /// Returns the poll interval between pages to back-off network pressure
    /// once an initial number of pages has been received.
    func pollInterval(page: Int) -> TimeInterval {
        page <= MovieService.highFrequencyPages
            ? MovieService.highFrequencyInterval
            : MovieService.lowFrequencyInterval
    }

}

// MARK: - Movie Details

extension MovieService {

    /// Get detailed movie information for the given IMDB identifier.
    func getMovieDetails(
        imbdId: String,
        completion: @escaping (Result<MovieDetail, NetworkError>) -> Void
    ) throws {
        guard
            let url = MovieServiceEndpoint.getDetails(imbdId: imbdId).url
        else {
            throw NetworkError.badPosterPath
        }

        let operation = MovieServiceOperation(
            requestUrl: url,
            requestCompletion: completion
        )

        searchQueue.addOperation(operation)
    }

}

// MARK: - Posters

extension MovieService {

    /// Fetch a poster for the given IMDB identifier and poster resource path.
    func getPoster(
        imdbId: String,
        path: String,
        completion: @escaping (Result<Poster, NetworkError>) -> Void
    ) throws {
        guard let url = URL(string: path) else {
            throw NetworkError.badPosterPath
        }

        let requestCompletion: (Result<Data, NetworkError>) -> Void = {
            result in

            switch result {

            case .success(let data):
                let poster = Poster(imdbId: imdbId, imageData: data)
                completion(.success(poster))

            case .failure(let error):
                completion(.failure(error))
            }
        }

        let operation = MovieServiceOperation(
            requestUrl: url,
            requestCompletion: requestCompletion
        )

        posterQueue.addOperation(operation)
    }

}

// MARK: - Cancellation

private extension MovieService {

    /// Cancel any ongoing network activity.
    func cancelSearchNetworking() {
        searchQueue.cancelAllOperations()
        posterQueue.cancelAllOperations()
    }

}

// MARK: - Network Error

extension MovieService {

    enum NetworkError: Error {

        /// Could not construct the API URL.
        case invalidParameter

        /// The network operation failed locally.
        case networkFailure(underlyingError: Error)

        /// The remote host returned an error status code.
        case remoteFailure(statusCode: Int)

        /// No data was returned by the remote host.
        case missingData

        /// The returned data could not be decoded.
        case decodingFailure(underlyingError: Error)

        /// The poster path is not a valid URL.
        case badPosterPath

        var userMessage: String? {
            switch self {
            
            case .invalidParameter:
                return "Please check the title!"

            case .networkFailure:
                return "Please check your network connection."

            case .remoteFailure, .missingData, .decodingFailure:
                return "Please try again later!"

            case .badPosterPath:
                return nil
            }
        }

    }

}
