//
//  DataStore.swift
//  MovieSearch
//
//  Created by Nick on 18/09/2021.
//

import Foundation

// MARK: - Data Store

class DataStore<Item: Codable> {

    /// The maximum count of items held by the store, nil if unlimited.
    let cacheLimit: Int?

    private lazy var cache: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = self.cacheLimit ?? 0
        return cache
    }()

    init(cacheLimit: Int? = nil) {
        self.cacheLimit = cacheLimit
    }

    /// Stores an item indexed by the given identifier.
    func store(identifier: String, item: Item) {
        let data = try! JSONEncoder().encode(item)

        cache.setObject(
            data as NSData,
            forKey: identifier as NSString
        )
    }

    /// Fetches an item from the store for the given index, nil if none
    /// is available.
    func fetch(identifier: String) -> Item? {
        guard
            let data = cache.object(forKey: identifier as NSString) as Data?
        else {
            return nil
        }

        let item = try! JSONDecoder().decode(Item.self, from: data)
        return item
    }

    /// Remove all items from the store.
    func clearAll() {
        cache.removeAllObjects()
    }

}
