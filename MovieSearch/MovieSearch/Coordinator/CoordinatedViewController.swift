//
//  CoordinatedViewController.swift
//  MovieSearch
//
//  Created by Nick on 18/09/2021.
//

import Foundation

// MARK: - Coordinated View Controller

class Coordinator {}

protocol CoordinatedViewController {
    var coordinator: Coordinator? { get set }
}
