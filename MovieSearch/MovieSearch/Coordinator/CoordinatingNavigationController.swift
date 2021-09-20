//
//  CoordinatingNavigationController.swift
//  MovieSearch
//
//  Created by Nick on 18/09/2021.
//

import UIKit

// MARK: - Coordinating Navigation Controller

class CoordinatingNavigationController: UINavigationController {

    private lazy var searchCoordinator: SearchCoordinator = {
        SearchCoordinator(navigationController: self)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchCoordinator.isNavigationControllerReady = true
    }
}
