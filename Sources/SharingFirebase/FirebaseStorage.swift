//
//  FirebaseStorage.swift
//
//
//  Created by Morten Bek Ditlevsen on 29/03/2024.
//
import Combine
import Dependencies
import Foundation
import Sharing
//import Synchronization

/// A type that encapsulates storing to and reading  from Firestore.
public protocol FirebaseStorage: Sendable, AnyObject {
    func documentListener<T: Decodable>(
        path: FBPath<T>,
        subscriber: SharedSubscriber<T>
    ) -> SharedSubscription
    func collectionListener<T: Decodable>(
        path: CollectionPath<T>,
        subscriber: SharedSubscriber<[(String, T)]>
    ) -> SharedSubscription
    
    func load<T: Decodable>(from path: FBPath<T>) throws -> T
    func save<T: Encodable>(_ value: T, to path: FBPath<T>) throws
    func remove<T>(at path: FBPath<T>) throws
    func add<T: Encodable>(_ value: T, to path: CollectionPath<T>) throws
}

/// A ``FirebaseStorage`` conformance that emulates a firebase database connections without actually writing anything
/// to the backend.
///
/// This is the version of the ``Dependencies/DependencyValues/defaultFirebaseStorage`` dependency that
/// is used by default when running your app in tests and previews.
public final class EphemeralFirebaseStorage: FirebaseStorage, Sendable {
    package let documentDatabase: Mutex<[String: Data]> = .init([:])
    package let collectionDatabase: Mutex<[String: [(String, Data)]]> = .init([:])

    public func documentListener<T>(path: FBPath<T>, subscriber: Sharing.SharedSubscriber<T>) -> Sharing.SharedSubscription where T : Decodable {
        subscriber.yield(with: Result(catching: {
            try load(from: path)
        }))
        return .init {
            
        }
    }

    // XXX TODO
    public func collectionListener<T>(path: CollectionPath<T>, subscriber: Sharing.SharedSubscriber<[(String, T)]>) -> Sharing.SharedSubscription where T : Decodable {
//        subscriber.yield(with: Result(catching: {
//
//        }))
        return .init {
            
        }
    }
    
    public func load<T>(from path: FBPath<T>) throws -> T where T : Decodable {
        let rendered = path.rendered
        let decoder = JSONDecoder()
        return try documentDatabase.withLock { db in
            guard let data = db[rendered] else {
                fatalError()
            }
            return try decoder.decode(T.self, from: data)
        }
    }
    
    public func save<T>(_ value: T, to path: FBPath<T>) throws where T : Encodable {
        let rendered = path.rendered
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        try documentDatabase.withLock { db in
            db[rendered] = data
        }
//        self.sourceHandlers.value[rendered]?(data)
    }
    
    public func remove<T>(at path: FBPath<T>) throws {
    }
    
    public func add<T>(_ value: T, to path: CollectionPath<T>) throws where T : Encodable {
    }
    
//    private let scheduler: AnySchedulerOf<DispatchQueue>
//    private let sourceHandlers: [String: ((Data) -> Void)] = [:]
//    private let collectionHandlers: [String: (([(String, Data)]) -> Void)] = [:]
//    
//    public init(scheduler: AnySchedulerOf<DispatchQueue> = .immediate) {
//        self.scheduler = scheduler
//    }
//    
//    public func asyncAfter(interval: DispatchTimeInterval, execute workItem: DispatchWorkItem) {
//        self.scheduler.schedule(after: self.scheduler.now.advanced(by: .init(interval))) {
//            workItem.perform()
//        }
//    }
//    
//    public func async(execute workItem: DispatchWorkItem) {
//        self.scheduler.schedule(workItem.perform)
//    }
//    
//    public func documentListener<T: Decodable>(
//        path: FBPath<T>,
//        handler: @escaping (T) -> Void
//    ) -> AnyCancellable {
//        let rendered = path.rendered
//        self.sourceHandlers.withValue { $0[rendered] = { data in
//            let decoder = JSONDecoder()
//            if let t = try? decoder.decode(T.self, from: data) {
//                handler(t)
//            }
//        }
//        }
//        return AnyCancellable {
//            self.sourceHandlers.withValue { $0[rendered] = nil }
//        }
//    }
//    
//    public func collectionListener<T: Decodable>(
//        path: CollectionPath<T>,
//        handler: @escaping ([(String, T)]) -> Void
//    ) -> AnyCancellable {
//        let rendered = path.rendered
//        self.collectionHandlers.withValue { $0[rendered] = { dataArray in
//            let decoder = JSONDecoder()
//            let values = dataArray.compactMap { (key: String, data: Data) -> (String, T)? in
//                guard let value = try? decoder.decode(T.self, from: data) else {
//                    return nil
//                }
//                return (key, value)
//            }
//            handler(values)
//        }
//        }
//        return AnyCancellable {
//            self.collectionHandlers.withValue { $0[rendered] = nil }
//        }
//    }
//    
//    struct LoadError: Error {}
//    
//    public func load<T: Decodable>(from path: FBPath<T>) throws -> T {
//        let rendered = path.rendered
//        let decoder = JSONDecoder()
//        guard let data = self.documentDatabase[rendered],
//              let value = try? decoder.decode(T.self, from: data)
//        else {
//            throw LoadError()
//        }
//        
//        return value
//    }
//    
//    public func save<T: Encodable>(_ value: T, to path: FBPath<T>) throws {
//        let rendered = path.rendered
//        let encoder = JSONEncoder()
//        let data = try encoder.encode(value)
//        self.documentDatabase.withValue { $0[rendered] = data }
//        self.sourceHandlers.value[rendered]?(data)
//    }
//    
//    public func remove<T>(at path: FBPath<T>) throws {
//        let rendered = path.rendered
//        self.documentDatabase.withValue { $0[rendered] = nil }
//        self.sourceHandlers.withValue { $0[rendered] = nil }
//    }
//    
//    public func add<T>(_ value: T, to path: CollectionPath<T>) throws where T : Encodable {
//        let id = UUID().uuidString
//        try save(value, to: path.child(id))
//    }
}
//
public enum FirebaseStorageQueueKey: TestDependencyKey {
    public static var previewValue: any FirebaseStorage {
        fatalError()
//        EphemeralFirebaseStorage()
    }
    public static var testValue: any FirebaseStorage {
        fatalError()
//        EphemeralFirebaseStorage()
    }
}

extension DependencyValues {
    public var defaultFirebaseStorage: any FirebaseStorage {
        get { self[FirebaseStorageQueueKey.self] }
        set { self[FirebaseStorageQueueKey.self] = newValue }
    }
}
