//
//  DetailViewController.swift
//  MovieSearch
//
//  Created by Nick on 18/09/2021.
//

import UIKit

// MARK: - Detail View Controller

class DetailViewController: UIViewController, CoordinatedViewController {

    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var detailTableView: UITableView!
    @IBOutlet weak var stateView: UIView!
    @IBOutlet weak var stateImageView: UIImageView!


    weak var coordinator: Coordinator?
    var searchCoordinator: SearchCoordinator? {
        coordinator as? SearchCoordinator
    }

    private var movie: Movie?
    private var movieDetail: MovieDetail?
    private var posterImage: UIImage?

    private struct DetailItem {
        var heading: String
        var text: String
    }

    private var details = [DetailItem]()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        titleLabel.text = movie?.title

        if let year = movie?.year {
            yearLabel.text = "(\(year))"
        } else {
            yearLabel.text = nil
        }

        posterImageView.image = posterImage

        self.detailTableView.reloadData()

        if details.count == 0 {
            showStateImage(image: UIImage(systemName: "timer"))
        }
    }

}

// MARK: - Configuration

extension DetailViewController {

    func configure(movie: Movie, posterImage: UIImage?) {
        self.movie = movie
        self.posterImage = posterImage
    }

    var imdbIdDisplayed: String? {
        self.movie?.imdbId
    }

    func setMovieDetail(_ movieDetail: MovieDetail) {
        self.movieDetail = movieDetail
        details = []

        func add(_ string: String?, heading: String) {
            guard let string = string, !string.isEmpty, string != "N/A" else {
                return
            }
            details.append(DetailItem(heading: heading, text: string))
        }

        add(movieDetail.director, heading: "Director")
        add(movieDetail.genre, heading: "Genre")
        add(movieDetail.plot, heading: "Plot")
        add(movieDetail.released, heading: "Release Date")
        add(self.movie?.type?.capitalized, heading: "Release Type")
        add(movieDetail.country, heading: "Country")
        add(movieDetail.rated, heading: "Rated")
        add(movieDetail.actors, heading: "Actors")
        add(movieDetail.writer, heading: "Writer")
        add(movieDetail.awardsHieroglyphic, heading: "Awards")
        add(movieDetail.boxOffice, heading: "Box Office Takings")
        add(movieDetail.metascoreHieroglyphic, heading: "Metascore")
        add(movieDetail.imdbRatingHieroglyphic, heading: "IMDB Rating")
        add(movieDetail.dvd, heading: "DVD Release Date")
        add(movieDetail.production, heading: "Production")

        if let tableView = self.detailTableView {
            hideStateImage(animated: true)
            tableView.reloadData()
        }
    }

    func setMovieDetailUnavailable() {
        showStateImage(image: UIImage(systemName: "heart.slash"))
    }

}

// MARK: - State Image

private extension DetailViewController {
    static let animationDuration = 0.4

    func showStateImage(image: UIImage?) {
        guard let image = image else { return }

        if stateView.alpha > 0.0 {
            hideStateImage(animated: false)
        }

        self.stateImageView.image = image
        self.stateView.backgroundColor = UIColor(named: "Background")
        self.stateView.layer.borderWidth = 2.0
        self.stateView.layer.cornerRadius = 16.0
        self.stateView.layer.borderColor = UIColor(
            named: "MovieCellBackground"
        )?.cgColor

        UIView.animate(withDuration: DetailViewController.animationDuration) {
            self.detailTableView.alpha = 0.0
            self.stateView.alpha = 1.0
        }
    }

    func hideStateImage(animated: Bool) {
        UIView.animate(
            withDuration: animated
                ? DetailViewController.animationDuration
                : 0.0
        ) {
            self.detailTableView.alpha = 1.0
            self.stateView.alpha = 0.0
        }
    }

}

// MARK: - Table View Data Source

extension DetailViewController: UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        details.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "DetailTableViewCell"
            ) as? DetailTableViewCell
        else {
            fatalError()
        }

        let detail = details[indexPath.row]
        cell.headingLabel.text = detail.heading
        cell.detailLabel.text = detail.text

        return cell
    }

}

// MARK: - Table View Delegate

extension DetailViewController: UITableViewDelegate {}
