//
//  RandomAccessDataStore.swift
//  MovieSearch
//
//  Created by Nick on 18/09/2021.
//

import Foundation

// MARK: - Random Access Data Store

class RandomAccessDataStore<Item: Codable> {

    private let store = DataStore<Item>()
    private(set) var count = 0
    private let lock = NSLock()

    /// Fetch an item from the store for the given index.
    subscript(_ index: Int) -> Item? {
        lock.lock()
        defer { lock.unlock() }
        guard index >= 0 && index < count else {
            return nil
        }

        return store.fetch(identifier: "\(index)")
    }

    /// Add a collection of items to the store, executing the completion
    /// handler when successful.
    func load(items: [Item], completion: (() -> Void)? = nil) {
        lock.lock()
        defer { lock.unlock() }

        for (index, item) in items.enumerated() {
            store.store(identifier: "\(count + index)", item: item)
        }

        count += items.count
        completion?()
    }

    /// Remove all items from the store.
    func clearAll() {
        lock.lock()
        defer { lock.unlock() }

        count = 0
        store.clearAll()
    }

}
