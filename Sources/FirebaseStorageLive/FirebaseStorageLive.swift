//
//  FirebaseStorageLive.swift
//  SharedState
//
//  Created by Morten Bek Ditlevsen on 17/03/2024.
//

import Combine
import Dependencies
import Sharing
import SharingFirebase

#if canImport(FirebaseFirestore)
@preconcurrency import FirebaseFirestore
#endif
#if canImport(FirebaseDatabase)
import FirebaseDatabase
#endif

import FirebaseSharedSwift
import Foundation

#if canImport(FirebaseFirestore)
extension FirestoreConfig {
    static let dispatchQueue: DispatchQueue = DispatchQueue(label: "Background")
    var firestore: Firestore {
        var settings = FirestoreSettings()
        settings.dispatchQueue = FirestoreConfig.dispatchQueue
        let firestore: Firestore
        if let database {
            firestore = Firestore.firestore(database: database)
        } else {
            firestore = Firestore.firestore()
        }
        firestore.settings = settings
        return firestore
    }
    
    func getDecoder() -> Firestore.Decoder {
        let decoder = Firestore.Decoder()
        decoder.dataDecodingStrategy = decodingOptions.dataDecodingStrategy.firebase
        decoder.dateDecodingStrategy = decodingOptions.dateDecodingStrategy.firebase
        decoder.keyDecodingStrategy = decodingOptions.keyDecodingStrategy.firebase
        decoder.nonConformingFloatDecodingStrategy = decodingOptions.nonConformingFloatDecodingStrategy.firebase
//        decoder.userInfo = decodingOptions.userInfo
        return decoder
    }
    
    func getEncoder() -> Firestore.Encoder {
        let encoder = Firestore.Encoder()
        encoder.dataEncodingStrategy = encodingOptions.dataEncodingStrategy.firebase
        encoder.dateEncodingStrategy = encodingOptions.dateEncodingStrategy.firebase
        encoder.keyEncodingStrategy = encodingOptions.keyEncodingStrategy.firebase
        encoder.nonConformingFloatEncodingStrategy = encodingOptions.nonConformingFloatEncodingStrategy.firebase
//        encoder.userInfo = encodingOptions.userInfo
        return encoder
    }
}

extension FBQuery {
    func apply(to ref: Query) -> Query {
        if let limit {
            return ref.limit(to: limit)
        } else {
            return ref
        }
    }
}

extension EncodingOptions.DataEncodingStrategy {
    var firebase: FirebaseDataEncoder.DataEncodingStrategy {
        switch self {
        case .blob:
            return .blob
        case .base64:
            return .base64
        case .deferredToData:
            return .deferredToData
//        case .custom(let custom):
//            return .custom(custom)
        }
    }
}

extension EncodingOptions.DateEncodingStrategy {
    var firebase: FirebaseDataEncoder.DateEncodingStrategy {
        switch self {
        case .deferredToDate: .deferredToDate
        case .secondsSince1970: .secondsSince1970
        case .millisecondsSince1970: .millisecondsSince1970
        case .iso8601: .iso8601
        case .formatted(let dateFormatter): .formatted(dateFormatter)
//        case .custom(let transform): .custom(transform)
        }
    }
}

extension EncodingOptions.KeyEncodingStrategy {
    var firebase: FirebaseDataEncoder.KeyEncodingStrategy {
        switch self {
        case .useDefaultKeys: .useDefaultKeys
        case .convertToSnakeCase: .convertToSnakeCase
//        case .custom(let transform): .custom(transform)
        }
    }
}

extension EncodingOptions.NonConformingFloatEncodingStrategy {
    var firebase: FirebaseDataEncoder.NonConformingFloatEncodingStrategy {
        switch self {
        case .throw: .throw
        case .convertToString(let positiveInfinity, let negativeInfinity, let nan):
                .convertToString(positiveInfinity: positiveInfinity, negativeInfinity: negativeInfinity, nan: nan)
        }
    }
}


extension DecodingOptions.DataDecodingStrategy {
    var firebase: FirebaseDataDecoder.DataDecodingStrategy {
        switch self {
        case .blob:
            return .blob
        case .base64:
            return .base64
        case .deferredToData:
            return .deferredToData
//        case .custom(let custom):
//            return .custom(custom)
        }
    }
}

extension DecodingOptions.DateDecodingStrategy {
    var firebase: FirebaseDataDecoder.DateDecodingStrategy {
        switch self {
        case .deferredToDate: .deferredToDate
        case .secondsSince1970: .secondsSince1970
        case .millisecondsSince1970: .millisecondsSince1970
        case .iso8601: .iso8601
        case .formatted(let dateFormatter): .formatted(dateFormatter)
//        case .custom(let transform): .custom(transform)
        }
    }
}

extension DecodingOptions.KeyDecodingStrategy {
    var firebase: FirebaseDataDecoder.KeyDecodingStrategy {
        switch self {
        case .useDefaultKeys: .useDefaultKeys
        case .convertFromSnakeCase: .convertFromSnakeCase
//        case .custom(let transform): .custom(transform)
        }
    }
}

extension DecodingOptions.NonConformingFloatDecodingStrategy {
    var firebase: FirebaseDataDecoder.NonConformingFloatDecodingStrategy {
        switch self {
        case .throw: .throw
        case .convertFromString(let positiveInfinity, let negativeInfinity, let nan):
                .convertFromString(positiveInfinity: positiveInfinity, negativeInfinity: negativeInfinity, nan: nan)
        }
    }
}

#endif

#if canImport(FirebaseDatabase)
extension RTDBConfig {
    var database: Database {
        if let instanceId {
            let url: String
            if let regionId {
                url = "https://\(instanceId).\(regionId).firebasedatabase.app"
            } else {
                url = "https://\(instanceId).firebaseio.com"
            }
            return Database.database(url: url)
        } else {
            return Database.database()
        }
    }

    func getDecoder() -> FirebaseDataDecoder {
        let decoder = FirebaseDataDecoder()
        decoder.dataDecodingStrategy = decodingOptions.dataDecodingStrategy.firebase
        decoder.dateDecodingStrategy = decodingOptions.dateDecodingStrategy.firebase
        decoder.keyDecodingStrategy = decodingOptions.keyDecodingStrategy.firebase
        decoder.nonConformingFloatDecodingStrategy = decodingOptions.nonConformingFloatDecodingStrategy.firebase
//        decoder.userInfo = decodingOptions.userInfo
        return decoder
    }
    
    func getEncoder() -> FirebaseDataEncoder {
        let encoder = FirebaseDataEncoder()
        encoder.dataEncodingStrategy = encodingOptions.dataEncodingStrategy.firebase
        encoder.dateEncodingStrategy = encodingOptions.dateEncodingStrategy.firebase
        encoder.keyEncodingStrategy = encodingOptions.keyEncodingStrategy.firebase
        encoder.nonConformingFloatEncodingStrategy = encodingOptions.nonConformingFloatEncodingStrategy.firebase
//        encoder.userInfo = encodingOptions.userInfo
        return encoder
    }
}

extension FBQuery {
    func apply(to ref: DatabaseQuery) -> DatabaseQuery {
        if let limit {
            // TODO: Should I worry about conversion to UInt?
            return ref.queryLimited(toFirst: UInt(limit))
        } else {
            return ref
        }
    }
}

#endif

enum FirebaseError: Error {
    case notImplemented
    case something
}

/// A ``FirebaseStorage`` conformance that interacts directly with Firestore for saving, loading
/// and listening for data changes.
///
/// This is the version of the ``Dependencies/DependencyValues/defaultFirebaseStorage`` dependency that
/// is used by default when running your app in the simulator or on device.
final public class LiveFirebaseStorage: FirebaseStorage {
    
    private let queue: DispatchQueue
    public init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    public func async(execute workItem: DispatchWorkItem) {
        self.queue.async(execute: workItem)
    }
    
    public func asyncAfter(interval: DispatchTimeInterval, execute workItem: DispatchWorkItem) {
        self.queue.asyncAfter(deadline: .now() + interval, execute: workItem)
    }
    
    public func documentListener<T: Decodable>(
        path: FBPath<T>,
        subscriber: SharedSubscriber<T>
    ) -> SharedSubscription {
        switch path.config {
        case .firestore(let config):
            return documentListenerFirestore(path: path.rendered, 
                                             config: config,
                                             subscriber: subscriber)
        case .rtdb(let config):
            return documentListenerRTDB(path: path.rendered,
                                        config: config,
                                        subscriber: subscriber)
        }
    }
        
    private func documentListenerFirestore<T: Decodable>(
        path: String,
        config: FirestoreConfig,
        subscriber: SharedSubscriber<T>
    ) -> SharedSubscription {
#if canImport(FirebaseFirestore)
        let registration = config.firestore
            .document(path)
            .addSnapshotListener { snap, error in
                switch (snap, error) {
                case (let snap?, _):
                    let decoder = config.getDecoder()
                    let result: Result<T?, any Error> = Result(catching: {
                        try snap.data(as: T.self, decoder: decoder)
                    })
                    subscriber.yield(with: result)
                case (_, let error?):
                    subscriber.yield(throwing: error)
                    
                case (_, _):
                    subscriber.yield(throwing: FirebaseError.something)
                }
            }

        return SharedSubscription {
            registration.remove()
        }
#else
        fatalError("Please link FirebaseFirestore")
#endif
    }
    
    private func documentListenerRTDB<T: Decodable>(
        path: String,
        config: RTDBConfig,
        subscriber: SharedSubscriber<T>
    ) -> SharedSubscription {
#if canImport(FirebaseDatabase)
        
        let db = config.database
        let ref = db.reference(withPath: path)
        let handle = ref.observe(.value) { snapshot in
            let result: Result<T?, any Error> = Result(catching: {
                try snapshot.data(as: T.self, decoder: config.getDecoder() ?? .init())
            })
            subscriber.yield(with: result)
        } withCancel: { error in
            subscriber.yield(throwing: error)
        }
        
        return SharedSubscription {
            let db = config.database
            let ref = db.reference(withPath: path)
            ref.removeObserver(withHandle: handle)
        }
#else
        fatalError("Please link FirebaseDatabase")
#endif
    }
    
    public func collectionListener<T: Decodable>(
        path: CollectionPath<T>,
        subscriber: SharedSubscriber<[(String, T)]>
    ) -> SharedSubscription {
        switch path.config {
        case .firestore(let config):
            collectionListenerFirestore(
                path: path.rendered,
                query: nil /* query */,
                config: config,
                subscriber: subscriber
            )
        case .rtdb(let config):
            collectionListenerRTDB(
                path: path.rendered,
                query: nil /* query */,
                config: config,
                subscriber: subscriber
            )
        }
    }
    
    private func collectionListenerFirestore<T: Decodable>(
        path: String,
        query: String?, // FBQuery?,
        config: FirestoreConfig,
        subscriber: SharedSubscriber<[(String, T)]>
    ) -> SharedSubscription {
#if canImport(FirebaseFirestore)
        var ref: Query = config.firestore.collection(path)
//        if let query {
//            ref = query.apply(to: ref)
//        }
        let registration = ref
            .addSnapshotListener { snap, error in
                switch (snap, error) {
                case (let snap?, _):
                    // TODO: Handle each document mapping individually?
                    let decoder = config.getDecoder() ?? .init()
                    let mapped = snap.documents.compactMap { documentSnap -> (String, T)? in
                        guard let value = try? documentSnap.data(as: T.self, decoder: decoder) else {
                            return nil
                        }
                        return (documentSnap.documentID, value)
                    }
                    subscriber.yield(mapped)
                    
                case (_, let error?):
                    subscriber.yield(throwing: error)
                case (.none, .none):
                    subscriber.yield(throwing: FirebaseError.something)
                }
            }
        return SharedSubscription {
            registration.remove()
        }
#else
        fatalError("Please link FirebaseFirestore")
#endif
    }
    
    private func collectionListenerRTDB<T: Decodable>(
        path: String,
        query: String?, // FBQuery?,
        config: RTDBConfig,
        subscriber: SharedSubscriber<[(String, T)]>
    ) -> SharedSubscription {
#if canImport(FirebaseDatabase)
        let db = config.database
        let ref = db.reference(withPath: path)
        let decoder = config.getDecoder() ?? .init()
        let handle = ref.observe(.value) { snapshot in
    
            // TODO: For now we just unwrap entire value.
            // Consider using child listeners and keep a (very local) cache
            let result: Result<[(String, T)]?, Error> = Result {
                let data = try snapshot.data(as: [String: T].self, decoder: decoder)
                // Use firebase RTDB key sorting.
                // TODO: Only sort this way when we are not using a query that sorts.
                return data.sorted(by: { l, r in
                    rtdbKeyIsLessThan(l.key, r.key)
                })
            }
            subscriber.yield(with: result)

        } withCancel: { error in
            subscriber.yield(throwing: error)
        }
        
        return SharedSubscription {
            let db = config.database
            let ref = db.reference(withPath: path)
            ref.removeObserver(withHandle: handle)
        }
#else
        fatalError("Please link FirebaseDatabase")
#endif
    }
    
    
    public func load<T: Decodable>(from path: FBPath<T>) throws -> T {
        switch path.config {
        case .firestore(let config):
            return try loadFirestore(from: path.rendered, config: config)

        case .rtdb(let config):
            return try loadRTDB(from: path.rendered, config: config)
        }
    }
    
    private func loadFirestore<T: Decodable>(
        from path: String,
        config: FirestoreConfig
    ) throws -> T {
#if canImport(FirebaseFirestore)
        var _value: T?
        var _error: Error = FirebaseError.something
        
        // Perform a synchronous load (perhaps unwise since this is called from
        // the main thread, which we are then actively blocking?)
        let lock = DispatchGroup()
        lock.enter()
        config.firestore
            .document(path)
            .getDocument(source: FirestoreSource.cache) { snap, error in
                do {
                    let decoder = config.getDecoder() ?? .init()
                    if let value = try? snap?.data(as: T.self, decoder: decoder) {
                        _value = value
                    } else {
                        throw error ?? FirebaseError.something
                    }
                } catch {
                    _error = error
                }
                lock.leave()
            }

        lock.wait()
        if let _value {
            return _value
        }
        throw _error
#else
        fatalError("Please link FirebaseFirestore")
#endif
    }
    
    private func loadRTDB<T: Decodable>(
        from path: String,
        config: RTDBConfig
    ) throws -> T {
#if canImport(FirebaseDatabase)
        // Note: For RTDB you cannot request a value ONLY from cache, so don't attempt to
        // implement this
        throw FirebaseError.notImplemented
#else
        fatalError("Please link FirebaseDatabase")
#endif
    }
    
    public func save<T: Encodable>(_ value: T, to path: FBPath<T>) throws {
        switch path.config {
        case .firestore(let config):
            try saveFirestore(value, to: path.rendered, config: config)
        case .rtdb(let config):
            try saveRTDB(value, to: path.rendered, config: config)
        }
    }
    
    public func add<T: Encodable>(_ value: T, to path: CollectionPath<T>) throws {
        switch path.config {
        case .firestore(let config):
            try addFirestore(value, to: path.rendered, config: config)
        case .rtdb(let config):
            try addRTDB(value, to: path.rendered, config: config)
        }
    }
    
    private func addFirestore<T: Encodable>(_ value: T, to path: String, config: FirestoreConfig) throws {
#if canImport(FirebaseFirestore)
        let encoder = config.getEncoder() ?? .init()
        try config
            .firestore
            .collection(path)
            .addDocument(from: value, encoder: encoder, completion: { error in
                guard let error else { return }
                print("Error", error)
            })
#else
        fatalError("Please link FirebaseFirestore")
#endif
    }
    
    private func addRTDB<T: Encodable>(_ value: T, to path: String, config: RTDBConfig) throws {
#if canImport(FirebaseDatabase)
        try config
            .database
            .reference(withPath: path)
            .childByAutoId()
            .setValue(from: value, encoder: config.getEncoder() ?? .init()) { error in
                guard let error else { return }
                print("Error", error)
            }
#else
        fatalError("Please link FirebaseDatabase")
#endif
    }


    public func remove<T>(at path: FBPath<T>) throws {
        switch path.config {
        case .firestore(let config):
            try removeFirestore(at: path.rendered, config: config)
        case .rtdb(let config):
            try removeRTDB(at: path.rendered, config: config)
        }
    }
    
    private func removeFirestore(at path: String, config: FirestoreConfig) {
#if canImport(FirebaseFirestore)
        try config
            .firestore
            .document(path)
            .delete()
#else
    fatalError("Please link FirebaseFirestore")
#endif
    }
    
    private func removeRTDB(at path: String, config: RTDBConfig) {
#if canImport(FirebaseDatabase)
        try config
            .database
            .reference(withPath: path)
            .removeValue()
#else
        fatalError("Please link FirebaseDatabase")
#endif
    }

    private func saveFirestore<T: Encodable>(_ value: T, to path: String, config: FirestoreConfig) throws {
#if canImport(FirebaseFirestore)
        let encoder = config.getEncoder() ?? .init()
        try config
            .firestore
            .document(path)
            .setData(from: value, encoder: encoder) { error in
                guard let error else { return }
                print("Error", error)
            }
#else
        fatalError("Please link FirebaseFirestore")
#endif
    }
    
    private func saveRTDB<T: Encodable>(_ value: T, to path: String, config: RTDBConfig) throws {
#if canImport(FirebaseDatabase)
        let db = config.database
        let ref = db.reference(withPath: path)
        try ref.setValue(from: value, encoder: config.getEncoder() ?? .init()) { error in
            guard let error else { return }
            print("Error", error)
        }
#else
        fatalError("Please link FirebaseDatabase")
#endif
    }

}

extension FirebaseStorageQueueKey: DependencyKey {
  public static var liveValue: any FirebaseStorage {
    LiveFirebaseStorage(
      queue: DispatchQueue(label: "co.pointfree.ComposableArchitecture.FirebaseStorage"))
  }
}

/* This method replicates the sorting order of keys used by the real time database */
private func rtdbKeyIsLessThan(_ a: String, _ b: String) -> Bool {
    guard a != b else { return false }
    
    switch (tryParseInt(a), tryParseInt(b)) {
    case (.some(let aAsInt), .some(let bAsInt)):
        // If a or b has prefixed 0s, but evaluate to the same number, then the length of the string gives the sort order
        return aAsInt - bAsInt == 0 ? a.count < b.count : aAsInt < bAsInt
    case (.some, .none):
        return true
    case (.none, .some):
        return false
    case (.none, .none):
        return a < b
    }
}

private func tryParseInt(_ str: String) -> Int? {
    guard let intVal = Int(str) else { return nil }
    if intVal >= -2_147_483_648 && intVal <= 2_147_483_647 {
        return intVal
    }
    return nil
}
