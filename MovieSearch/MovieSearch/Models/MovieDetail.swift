//
//  MovieDetail.swift
//  MovieSearch
//
//  Created by Nick on 18/09/2021.
//

import Foundation

// MARK: - Movie Detail

class MovieDetail: Codable {

    var title: String
    var year: String?
    var rated: String?
    var released: String?
    var runtime: String?
    var genre: String?
    var director: String?
    var writer: String?
    var actors: String?
    var plot: String?
    var language: String?
    var country: String?
    var awards: String?
    var metascore: String?
    var imdbRating: String?
    var dvd: String?
    var boxOffice: String?
    var production: String?

    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case year = "Year"
        case rated = "Rated"
        case released = "Released"
        case runtime = "Runtime"
        case genre = "Genre"
        case director = "Director"
        case writer = "Writer"
        case actors = "Actors"
        case plot = "Plot"
        case language = "Language"
        case country = "Country"
        case awards = "Awards"
        case metascore = "Metascore"
        case imdbRating = "imdbRating"
        case dvd = "DVD"
        case boxOffice = "BoxOffice"
        case production = "Production"
    }

}

// MARK: - Awards Hieroglyphics

extension MovieDetail {

    var awardsHieroglyphic: String? {
        guard let awards = self.awards, !awards.isEmpty, awards != "N/A" else {
            return nil
        }

        let words: [String] = awards
            .split(separator: " ")
            .compactMap { word in

                var res = word.trimmingCharacters(in: .whitespacesAndNewlines)
                res = res.trimmingCharacters(in: .punctuationCharacters)
                res = res.lowercased()

                if res.last == "s" {
                    res.remove(at: res.index(before: res.endIndex))
                }

                return res.count > 0 ? res : nil
            }

        var hieroglyphic = ""

        func addHieroglyph(_ award: String, _ glyph: String, number: Int) {
            guard number >= 1 else { return }
            let addition = String(repeating: glyph, count: number)
            hieroglyphic += award + ": " + addition + "\n"
        }

        for (index, word) in words.enumerated() {
            guard index > 0, let number = Int(words[index - 1]) else {
                continue
            }

            switch word {

            case "oscar": addHieroglyph("Oscars", "🕴", number: number)

            case "win": addHieroglyph("Wins", "🏆", number: number)

            case "nomination":
                addHieroglyph(
                    "Nominations", "👏",
                    number: number
                )

            default: break
            }
        }

        return hieroglyphic.count > 0
            ? hieroglyphic + "(\(awards))"
            : awards
    }

}

// MARK: - Score Hieroglyphics

extension MovieDetail {

    var metascoreHieroglyphic: String? {
        scoreHieroglyphic(score: metascore, maximum: 100)
    }

    var imdbRatingHieroglyphic: String? {
        scoreHieroglyphic(score: imdbRating, maximum: 10)
    }

    private func scoreHieroglyphic(
        score: String?,
        maximum: Double
    ) -> String? {
        guard let scoreString = score, let score = Double(scoreString) else {
            return nil
        }

        let tenths = Int((score / (maximum / 10.0)).rounded(.down))

        let block: String
        if tenths <= 3 {
            block = "🟥"
        } else if tenths <= 6 {
            block = "🟨"
        } else {
            block = "🟩"
        }

        let scoreBlocks = String(repeating: block, count: tenths)
        let greyBlocks = String(repeating: "⬜️", count: 10 - tenths)

        return scoreBlocks + greyBlocks + " " + "\(scoreString)"
    }

}
