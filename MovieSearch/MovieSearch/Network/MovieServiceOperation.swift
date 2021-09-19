//
//  MovieServiceOperation.swift
//  MovieSearch
//
//  Created by Nick on 18/09/2021.
//

import Foundation

// MARK: - Movie Service Operation

class MovieServiceOperation<T: Decodable>: Operation {
    typealias OperationResult = Result<T, MovieService.NetworkError>
    typealias Completion = (OperationResult) -> Void

    private enum KVOKey: String {
        case isExecuting = "isExecuting"
        case isFinished = "isFinished"

        var key: String { self.rawValue }
    }

    private var isWaitingForNetwork: Bool? = nil

    override var isAsynchronous: Bool { true }
    override var isExecuting: Bool { isWaitingForNetwork == true }
    override var isFinished: Bool { isWaitingForNetwork == false }

    let requestUrl: URL
    let requestCompletion: Completion

    init(
        requestUrl: URL,
        requestCompletion: @escaping Completion
    ) {
        self.requestUrl = requestUrl
        self.requestCompletion = requestCompletion
    }

    override func start() {
        guard !isCancelled  else {
            return
        }

        willChangeValue(forKey: KVOKey.isExecuting.key)
        isWaitingForNetwork = true
        didChangeValue(forKey: KVOKey.isExecuting.key)

        URLSession.shared.dataTask(with: requestUrl) { data, response, error in

            defer {
                self.willChangeValue(forKey: KVOKey.isExecuting.key)
                self.willChangeValue(forKey: KVOKey.isFinished.key)
                self.isWaitingForNetwork = false
                self.didChangeValue(forKey: KVOKey.isExecuting.key)
                self.didChangeValue(forKey: KVOKey.isFinished.key)
            }

            if let underlyingError = error {
                let networkError = MovieService.NetworkError.networkFailure(
                    underlyingError: underlyingError
                )
                self.requestCompletion(OperationResult.failure(networkError))
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !self.isSuccessStatusCode(httpResponse.statusCode)
            {
                let networkError = MovieService.NetworkError.remoteFailure(
                    statusCode: httpResponse.statusCode
                )
                self.requestCompletion(OperationResult.failure(networkError))
                return
            }

            guard let data = data else {
                let networkError = MovieService.NetworkError.missingData
                self.requestCompletion(OperationResult.failure(networkError))
                return
            }

            if let unencodedResult = data as? T {
                self.requestCompletion(.success(unencodedResult))
                return
            }

            let result = self.decodeResult(data: data)
            self.requestCompletion(result)

        }.resume()
    }

}

// MARK: - Helpers

private extension MovieServiceOperation {

    func isSuccessStatusCode(_ statusCode: Int) -> Bool {
        statusCode == 200
    }

    func decodeResult(data: Data) -> OperationResult {
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return OperationResult.success(decoded)

        } catch {
            let networkError = MovieService.NetworkError.decodingFailure(
                underlyingError: error
            )
            return OperationResult.failure(networkError)
        }
    }

}
