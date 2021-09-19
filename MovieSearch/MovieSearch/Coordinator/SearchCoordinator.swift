//
//  SearchCoordinator.swift
//  MovieSearch
//
//  Created by Nick on 18/09/2021.
//

import UIKit

// MARK: - Search Coordinator

class SearchCoordinator: Coordinator {

    /// The navigation controller used to show coordinated view controllers.
    private weak var navigationController: UINavigationController?

    /// Set to true when the navigation controller UI is loaded.
    var isNavigationControllerReady: Bool = false {
        didSet {
            guard !oldValue, isNavigationControllerReady else {
                return
            }
            showSearchScreen()
        }
    }

    /// Gateway to the OMDB API service.
    private let movieService = MovieService()

    /// A data store used to hold movie summaries.
    private let movieStore = RandomAccessDataStore<Movie>()

    /// A data store used to hold detailed movie information.
    private let detailStore = DataStore<MovieDetail>()

    /// A data store used to hold movie posters.
    private let posterStore = DataStore<Poster>(cacheLimit: 400)

    /// Reference to the search view controller.
    private var searchViewController: SearchViewController?

    /// A timer used to hide network error messages after a duration.
    private var messageTimer: Timer?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
        
        movieService.delegate = self
    }

}

// MARK: - Route to Search Screen

extension SearchCoordinator {

    /// Show the search screen.
    func showSearchScreen() {
        let searchViewController: SearchViewController = makeViewController(
            identifier: "SearchViewController"
        )

        navigationController?.pushViewController(
            searchViewController,
            animated: false
        )

        self.searchViewController = searchViewController
    }

}

// MARK: - Route to Details Screen

extension SearchCoordinator {

    /// Show the details of a particular movie.
    func showDetailScreen(movie: Movie) {
        // We can only show a movie with an IMDB identifier, because this
        // is used to fetch the detailed information from the API.
        guard let imdbId = movie.imdbId else { return }

        let detailViewController: DetailViewController = makeViewController(
            identifier: "DetailViewController"
        )

        // We're likely to have the poster image already, if not this will
        // start a request to fetch it.
        let image = getPosterImage(imdbId: imdbId)

        detailViewController.configure(movie: movie, posterImage: image)
        navigationController?.pushViewController(
            detailViewController,
            animated: true
        )

        // If we have the movie details already then we can show them
        // immediately, otherwise a fetch request is started.
        if let detail = fetchMovieDetail(imdbId: imdbId) {
            detailViewController.setMovieDetail(detail)
        }
    }

}

// MARK: - Movie Searches

extension SearchCoordinator {

    /// Start a search for movies with a given title.
    func performSearch(title: String) {
        // Clear the store for the new search.
        movieStore.clearAll()

        // Advise the search results controller to update to the new
        // (empty) state.
        notifyMoviesAvailable()

        // Start the search request.
        do {
            try movieService.search(title: title)

        } catch {
            // The request could not be started.
            self.showError(error)
        }
    }

    /// Inform the search view controller that new results are available.
    private func notifyMoviesAvailable() {
        DispatchQueue.main.async {
            self.searchViewController?.updateSearchResults()
        }
    }

    /// Inform the search view controller that no results will be
    /// forthcoming.
    private func notifyNoMoviesFound() {
        DispatchQueue.main.async {
            self.searchViewController?.updateNoMoviesFound()
        }
    }

}

// MARK: - Movie Service Delegate

extension SearchCoordinator: MovieServiceDelegate {

    func movieService(
        _ movieService: MovieService,
        didObtainMovies movies: [Movie]
    ) {
        guard movies.count > 0 else {
            // No movies were returned in this page.

            if movieStore.count == 0 {
                // If there are no movies at all, then it's an
                // empty search.
                notifyNoMoviesFound()
            }

            return
        }

        // Add the new movies into the store...
        movieStore.load(items: movies) {
            // ... and then update the user interface.
            self.notifyMoviesAvailable()
        }


        // Start loading posters for all of the new movies.
        movies.forEach { movie in
            // Check to see if we already have a poster for this movie.
            if let imdbId = movie.imdbId,
               let posterImage = getPosterImage(imdbId: imdbId)
            {
                // Yes, propagate it it immediately.
                notifyPosterAvailable(imdbId: imdbId, posterImage: posterImage)

            } else {
                // Otherwise, start a fetch from the API.
                fetchPosterImage(movie: movie)
            }
        }
    }

    func movieService(
        _ movieService: MovieService,
        didEncounterError error: MovieService.NetworkError
    ) {
        // The request failed, advise the user.
        self.showError(error)
    }

}

// MARK: - Load Movie Details

private extension SearchCoordinator {

    /// Returns detailed information for a particular movie, or nil if
    /// none are available.
    func fetchMovieDetail(imdbId: String) -> MovieDetail? {

        // Check the cache.
        if let detail = detailStore.fetch(identifier: imdbId) {
            // Cache hit, return the details.
            return detail
        }

        // Cache miss, request details from the API.
        do {
            try movieService.getMovieDetails(imbdId: imdbId) { result in
                switch result {

                case .success(let detail):
                    // Details obtained, add to store and propagate.
                    self.detailStore.store(identifier: imdbId, item: detail)
                    self.notifyMovieDetailsAvailable(
                        imdbId: imdbId,
                        detail: detail
                    )

                case .failure:
                    // Failure fetching details, propagate the error state.
                    self.notifyMovieDetailsUnavailable(imdbId: imdbId)
                }
            }


        } catch {
            // The request could not be started.
            self.notifyMovieDetailsUnavailable(imdbId: imdbId)
        }

        return nil
    }

    /// Advises a detail view controller that the relevant movie details
    /// have become available.
    func notifyMovieDetailsAvailable(imdbId: String, detail: MovieDetail) {
        DispatchQueue.main.async {

            // Find Detail View Controller's on the navigation stack.
            let dvcs: [DetailViewController] = self.findViewControllers()

            // Load the movie details if the IMDB id matches.
            dvcs.forEach { detailViewController in
                guard detailViewController.imdbIdDisplayed == imdbId else {
                    return
                }

                detailViewController.setMovieDetail(detail)
            }
        }
    }

    /// Advises a detail view controller that the relevant movies will not
    /// be available (e.g. due to a network error).
    func notifyMovieDetailsUnavailable(imdbId: String) {
        DispatchQueue.main.async {

            let dvcs: [DetailViewController] = self.findViewControllers()

            dvcs.forEach { detailViewController in
                guard detailViewController.imdbIdDisplayed == imdbId else {
                    return
                }

                detailViewController.setMovieDetailUnavailable()
            }
        }
    }

}

// MARK: - Load Posters

extension SearchCoordinator {

    /// Returns a poster image for the given IMDB identifier, nil if none
    /// is available.
    func getPosterImage(imdbId: String) -> UIImage? {
        guard let poster = posterStore.fetch(identifier: imdbId) else {
            return nil
        }

        let image = UIImage(data: poster.imageData)
        return image
    }

    /// Get a poster image for a particular movie from the OMDB API.
    private func fetchPosterImage(movie: Movie) {
        // We need an IMDB identifier because this is used to index
        // fetched posters.
        guard
            let imdbId = movie.imdbId,
            movie.hasPoster,
            let posterPath = movie.poster
        else {
            return
        }

        try? self.movieService.getPoster(
            imdbId: imdbId,
            path: posterPath
        ) { result in

            switch result {

            case .success(let poster):
                guard let posterImage = UIImage(data: poster.imageData) else {
                    // We can't make an image from this data.
                    return
                }

                // Successful fetch, store the poster and propagate.
                self.posterStore.store(
                    identifier: poster.imdbId,
                    item: poster
                )

                self.notifyPosterAvailable(
                    imdbId: poster.imdbId,
                    posterImage: posterImage
                )

            case .failure:
                // We ignore failures on the poster endpoint. To show them
                // we would need to throttle reports due to the traffic.
                break
            }
        }
    }

    /// Inform the search view controller that a poster is now
    /// available.
    private func notifyPosterAvailable(imdbId: String, posterImage: UIImage) {
        DispatchQueue.main.async {
            self.searchViewController?.posterBecameAvailable(
                imdbId: imdbId,
                posterImage: posterImage
            )
        }
    }

}

// MARK: - Movie Search Result Provider

extension SearchCoordinator {

    /// Returns the number of movies in the current search result.
    var moviesSearchResultCount: Int {
        movieStore.count
    }

    /// Returns the movie at the given index of the search result.
    func movieSearchResult(atIndex index: Int) -> Movie? {
        movieStore[index]
    }

}

// MARK: - Error Handling

private extension SearchCoordinator {

    /// A generic error message to use when specific wording is unavailable.
    static let genericErrorMessage = "Something went wrong."

    /// The time interval for which error messages should be shown (seconds).
    static let errorMessageDuration = 6.0

    /// Show an error message via the search view controller.
    func showError(_ error: Error) {
        #if DEBUG
        // Log the error in debug builds.
        print("😱 error: \(error)")
        #endif

        // We need a search view controller to show the error.
        guard let searchViewController = searchViewController else {
            return
        }

        // Unwrap the user facing error message, or use the generic
        // alternative.
        let message: String
        if let networkError = error as? MovieService.NetworkError,
           let msg = networkError.userMessage
        {
            message = msg
        } else {
            message = SearchCoordinator.genericErrorMessage
        }

        DispatchQueue.main.async {
            // Dismiss any existing timer (if showing a message while another
            // is still on-screen).
            self.messageTimer?.invalidate()

            // Show the error message.
            searchViewController.showErrorMessage(message)

            self.messageTimer = Timer.scheduledTimer(
                withTimeInterval: SearchCoordinator.errorMessageDuration,
                repeats: false,
                block: { _ in

                // Hide the error message after the interval.
                self.searchViewController?.hideErrorMessage()
            })
        }
    }

}

// MARK: - Helpers

private extension SearchCoordinator {

    /// Instantiate a coordinated view controller from the main storyboard.
    func makeViewController<T: CoordinatedViewController>(
        identifier: String
    ) -> T {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard
            var vc = storyboard.instantiateViewController(
                withIdentifier: identifier
            ) as? T
        else {
            fatalError()
        }

        vc.coordinator = self
        return vc
    }

    /// Find all view controllers on the navigation stack that match the
    /// type parameter.
    func findViewControllers<T>() -> [T] {
        self.navigationController?.viewControllers.compactMap {
            viewController in
            
            viewController as? T
        } ?? []
    }

}
