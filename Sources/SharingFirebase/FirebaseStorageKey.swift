import Combine
import Dependencies
import Foundation
import IdentifiedCollections
import Sharing
//#if canImport(Perception)

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(WatchKit)
import WatchKit
#endif


// For entities that are `Codable`
extension SharedKey {
    /// Creates a persistence key that can read and write to a `Codable` value to the file system.
    ///
    /// - Parameter url: The file URL from which to read and write the value.
    /// - Returns: A file persistence key.
    public static func firebase<Value: Codable>(_ path: FBPath<Value>) -> Self
    where Self == FirebaseStorageKey<Value> {
        FirebaseStorageKey(path: path)
    }
//            
//    public static func firebase<Value: Codable>(_ path: CollectionPath<Value>) -> Self
//    where Value: KeyedById, Value: Equatable, Self == FirebaseStorageKey<IdentifiedArray<Value.ID, Value>> {
//        FirebaseStorageKey(path: path)
//    }
//    
//    public static func firebase<Value>(_ path: CollectionPath<Value>) -> Self
//    where Self == FirebaseStorageKey<IdentifiedArray<String, Identified<String, Value>>>, Value: Codable, Value: Equatable {
//        FirebaseStorageKey(path: path)
//    }
    
//    public static func firebase<Value>(_ path: CollectionPath<Value>) -> Self
//    where Self == FirebaseStorageKey<[Value]>, Value: Codable, Value: Equatable {
//        FirebaseStorageKey(path: path)
//    }
}

// For entities that are only `Decodable`
extension SharedReaderKey {
    /// Creates a persistence key that can read and write to a `Codable` value to the file system.
    ///
    /// - Parameter url: The file URL from which to read and write the value.
    /// - Returns: A file persistence key.
    public static func firebase<Value: Decodable>(_ path: FBPath<Value>) -> Self
    where Self == FirebaseStorageReaderKey<Value> {
        FirebaseStorageReaderKey(path: path)
    }
    
    public static func firebase<Value: Decodable>(_ path: CollectionPath<Value>) -> Self
    where Value: Identifiable /*, Value: Equatable*/, Self == FirebaseStorageReaderKey<IdentifiedArray<Value.ID, Value>> {
        FirebaseStorageReaderKey(path: path)
    }
    
//    public static func firebase<Value>(_ path: CollectionPath<Value>) -> Self
//    where Self == FirebaseStorageReaderKey<IdentifiedArray<String, Identified<String, Value>>>, Value: Decodable, Value: Equatable {
//        FirebaseStorageReaderKey(path: path)
//    }
//    
    public static func firebase<Value>(_ path: CollectionPath<Value>) -> Self
    where Self == FirebaseStorageReaderKey<[Value]>, Value: Decodable, Value: Identifiable /*, Value: Equatable*/ {
        FirebaseStorageReaderKey(path: path)
    }
    
    public static func firebase<Value>(_ path: CollectionPath<Value>) -> Self
    where Self == FirebaseStorageReaderKey<[Identified<String, Value>]>, Value: Decodable /*, Value: Equatable*/ {
        FirebaseStorageReaderKey(path: path)
    }

//
//    public static func firebase<Value: Decodable>(_ query: FBQuery<Value>) -> Self
//    where Self == FirebaseStorageReaderKey<IdentifiedArray<String, Identified<String, Value>>>, Value: Decodable, Value: Equatable {
//        FirebaseStorageReaderKey(query: query)
//    }
//    
//    public static func firebase<Value: Decodable>(_ query: FBQuery<Value>) -> Self
//    where Value: Identifiable, Value: Equatable, Self == FirebaseStorageReaderKey<IdentifiedArray<Value.ID, Value>> {
//        FirebaseStorageReaderKey(query: query)
//    }
//

}

// TODO: Audit unchecked sendable

/// A type defining a file persistence strategy
///
/// Use ``SharedKey/fileStorage(_:)`` to create values of this type.
public final class FirebaseStorageKey<Value: Sendable>: SharedKey {
    private let renderedPath: String
    private let pathHash: FBPathHash
    let storage: any FirebaseStorage
    
    init(path: FBPath<Value>) where Value: Decodable, Value: Encodable {
        self.renderedPath = path.rendered
        self.pathHash = path.pathHash
        @Dependency(\.defaultFirebaseStorage) var storage
        self.storage = storage
        self._load = { context, continuation in
            if let value = try? storage.load(from: path) {
                continuation.resume(returning: value)
            } else {
                continuation.resumeReturningInitialValue()
            }
        }
        
        self._save = { value, context, continuation in
            continuation.resume(with: Result(catching: {
                try storage.save(value, to: path)
            }))
        }
        
        self._subscribe = {
            context,
            subscriber in
            storage.documentListener(
                path: path,
                subscriber: subscriber
            )
        }
    }
    
    let _load: @Sendable (LoadContext<Value>, LoadContinuation<Value>) -> Void
    let _save: @Sendable (Value, SaveContext, SaveContinuation) -> Void
    let _subscribe: @Sendable (LoadContext<Value>?, SharedSubscriber<Value>) -> SharedSubscription
    
    public func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
        _load(context, continuation)
    }
    
    public var id: some Hashable { pathHash } // TODO: Not good enough - must also represent query...
    
    public func subscribe(context: LoadContext<Value>, subscriber: SharedSubscriber<Value>) -> SharedSubscription {
        _subscribe(context, subscriber)
    }

    public func save(_ value: Value, context: SaveContext, continuation: SaveContinuation) {
        _save(value, context, continuation)
    }

//    let storage: any FirebaseStorage
//    var workItem: DispatchWorkItem?
//    
//    var _save: (Value) -> Void = { _ in }
//    let _load: (Value?) -> Value?
//    let _subscribe: (Value?, @escaping (_ newValue: Value?) -> Void) -> Shared<Value>.Subscription
//    
//    // Note: Only used for hashing...
//    private let renderedPath: String
//    
////    public init<T: Codable>(path: CollectionPath<T>) where Value == [T] {
////        @Dependency(\.defaultFirebaseStorage) var storage
////        self.storage = storage
////        self.renderedPath = path.rendered
////        
////        // Can't save...
////        self._save = { _ in }
////        self._load = { initialValue in
////            initialValue
////        }
////        self._subscribe = { initialValue, didSet in
////            let cancellable = storage.collectionListener(path: path) { (values: [(String, T)]) -> Void in
////                didSet(values.map(\.1))
////            }
////            return Shared.Subscription {
////                cancellable.cancel()
////            }
////        }
////    }
//    
//    public init<T>(path: CollectionPath<T>) where Value == IdentifiedArray<String, Identified<String, T>>, T: Codable, T: Equatable {
//        @Dependency(\.defaultFirebaseStorage) var storage
//        self.storage = storage
//        self.renderedPath = path.rendered
//        
//        let _value = LockIsolated<IdentifiedArray<String, Identified<String, T>>>([])
//        
//        self._save = { newValue in
//            let existing = _value.value
//            guard newValue != existing else {
//                return
//            }
//            let newIds = newValue.ids
//            let existingIds = existing.ids
//            let addedIds = newIds.subtracting(existingIds)
//            let removedIds = existingIds.subtracting(newIds)
//            let commonIds = newIds.intersection(existingIds)
//            for id in addedIds {
//                print("Adding \(id)")
//                if let value = newValue[id: id]?.value {
//                    // Hmm, I don't know if this is a good idea...
//                    // But it's a bit annoying that in the situation
//                    // where you don't have `Identifiable` entities
//                    // (since you likely don't care about them)
//                    // you have to provide ids when appending to the collection.
//                    // I'll experiment with using the empty string as a magic value...
//                    if id == "" {
//                        try? storage.add(value, to: path)
//                    } else {
//                        try? storage.save(value, to: path.child(id))
//                    }
//                }
//            }
//            for id in removedIds {
//                print("Removing \(id)")
//                try? storage.remove(at: path.child(id))
//            }
//            for id in commonIds {
//                guard let new = newValue[id: id]?.value,
//                      let old = existing[id: id]?.value else {
//                    continue
//                }
//                if new != old {
//                    print("Updating \(id)")
//                    try? storage.save(new, to: path.child(id))
//                } else {
//                    print("Skipping \(id)")
//                }
//            }
//            _value.setValue(newValue)
//        }
//        self._load = { initialValue in
//            initialValue
//        }
//        self._subscribe = { initialValue, didSet in
//            let cancellable = storage.collectionListener(path: path) { (values: [(String, T)]) -> Void in
//                let identified = IdentifiedArray(values.map { Identified($0.1, id: $0.0) })
//                if identified != _value.value {
//                    _value.setValue(identified)
//                    didSet(identified)
//                }
//            }
//            return Shared.Subscription {
//                cancellable.cancel()
//            }
//        }
//    }
//    
//    public init<T: Codable>(path: CollectionPath<T>) where T: Identifiable, Value == IdentifiedArray<T.ID, T>, T: Equatable {
//        @Dependency(\.defaultFirebaseStorage) var storage
//        self.storage = storage
//        self.renderedPath = path.rendered
//        let _value = LockIsolated<IdentifiedArray<T.ID, T>>([])
//        let _map: LockIsolated<[T.ID: String]> = .init([:])
//        
//        self._save = { newValue in
//            let existing = _value.value
//            guard newValue != existing else {
//                return
//            }
//            let newIds = newValue.ids
//            let existingIds = existing.ids
//            let addedIds = newIds.subtracting(existingIds)
//            let removedIds = existingIds.subtracting(newIds)
//            let commonIds = newIds.intersection(existingIds)
//            for id in addedIds {
//                // For added ids, we do not yet have a value in the map.
//                // Instead we call the 'add' api
//                print("Adding \(id)")
//                if let value = newValue[id: id] {
//                    // TODO: Collection errors?
//                    try? storage.add(value, to: path)
//                }
//            }
//            for id in removedIds {
//                guard let mappedId = _map.value[id] else {
//                    continue
//                }
//                
//                print("Removing \(id)")
//                try? storage.remove(at: path.child(mappedId))
//            }
//            for id in commonIds {
//                guard let mappedId = _map.value[id] else {
//                    continue
//                }
//                
//                guard let new = newValue[id: id],
//                      let old = existing[id: id] else {
//                    continue
//                }
//                if new != old {
//                    print("Updating \(id)")
//                    try? storage.save(new, to: path.child(mappedId))
//                } else {
//                    print("Skipping \(id)")
//                }
//            }
//            _value.setValue(newValue)
//        }
//        self._load = { initialValue in
//            initialValue
//        }
//        self._subscribe = { initialValue, didSet in
//            let cancellable = storage.collectionListener(path: path) { (values: [(String, T)]) -> Void in
//                let identified = IdentifiedArray(values.map(\.1))
//                var map: [T.ID: String] = [:]
//                if identified != _value.value {
//                    _value.setValue(identified)
//                    for (key, value) in values {
//                        let id = value.id
//                        map[id] = key
//                    }
//                    _map.withValue { [map] in $0 = map }
//                    didSet(identified)
//                }
//            }
//            return Shared.Subscription {
//                cancellable.cancel()
//            }
//        }
//    }
//    
//    public init(path: FBPath<Value>) where Value: Codable {
//        @Dependency(\.defaultFirebaseStorage) var storage
//        self.storage = storage
//        self.renderedPath = path.rendered
//        let _value = LockIsolated<Value?>(nil)
//        
//        self._load = { initialValue in
//            try? storage.load(from: path) ?? initialValue
//        }
//        
//        self._subscribe = { initialValue, didSet in
//            let cancellable = storage.documentListener(path: path) { (value: Value) -> Void in
//                didSet(value)
//            }
//            return Shared.Subscription {
//                cancellable.cancel()
//            }
//        }
//        
//        self._save = { (value: Value) -> Void in
//            _value.setValue(value)
//            if self.workItem == nil {
//                let workItem = DispatchWorkItem { [weak self] in
//                    guard let self, let value = _value.value else { return }
//                    try? storage.save(value, to: path)
//                    _value.setValue(nil)
//                    self.workItem = nil
//                }
//                self.workItem = workItem
//                storage.async(execute: workItem)
//            }
//        }
//    }
    
//    public func save(_ value: Value) {
//        _save(value)
//    }
//    
//    public func load(initialValue: Value?) -> Value? {
//        _load(initialValue)
//    }
}

struct FBPathHash: Hashable {
    let renderedPath: String
    let config: PathConfig
}

extension FBPath {
    var pathHash: FBPathHash {
        .init(renderedPath: rendered, config: config)
    }
}

extension SharedSubscriber {
    func pullback<U>(_ transform: @Sendable @escaping (U) -> Value) -> SharedSubscriber<U> {
        SharedSubscriber<U> { result in
            switch result {
            case .success(let value?):
                self.yield(transform(value))
            case .success:
                self.yieldReturningInitialValue()
            case .failure(let error):
                self.yield(throwing: error)
            }
        }
    }
}

public struct FirebaseStorageReaderKey<Value: Sendable>: SharedReaderKey, Sendable {
    
    private let renderedPath: String
    private let pathHash: FBPathHash
    let storage: any FirebaseStorage
    
    init(path: FBPath<Value>) where Value: Decodable {
        self.renderedPath = path.rendered
        self.pathHash = path.pathHash
        @Dependency(\.defaultFirebaseStorage) var storage
        self.storage = storage
        self._load = { context, continuation in
            if let value = try? storage.load(from: path) {
                continuation.resume(returning: value)
            } else {
                continuation.resumeReturningInitialValue()
            }
        }
        
        self._subscribe = {
            context,
            subscriber in
            storage.documentListener(
                path: path,
                subscriber: subscriber
            )
        }

    }
    
    init<T: Decodable>(path: CollectionPath<T>) where T: Identifiable, Value == IdentifiedArray<T.ID, T> /*, T: Equatable*/ {
        self.renderedPath = path.rendered
        self.pathHash = path.pathHash
        @Dependency(\.defaultFirebaseStorage) var storage
        self.storage = storage
        self._load = { context, continuation in
            continuation.resumeReturningInitialValue()
        }
        self._subscribe = {
            context,
            subscriber in
            
            let transformed: SharedSubscriber<[(String, T)]> = subscriber.pullback { value in
                IdentifiedArray(value.map(\.1))
            }
            return storage.collectionListener(path: path, subscriber: transformed)
        }
    }


    let _load: @Sendable (LoadContext<Value>, LoadContinuation<Value>) -> Void
    let _subscribe: @Sendable (LoadContext<Value>?, SharedSubscriber<Value>) -> SharedSubscription

    public func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
        _load(context, continuation)
    }
    
    public var id: some Hashable { pathHash } // TODO: Not good enough - must also represent query...

    public func subscribe(context: LoadContext<Value>, subscriber: SharedSubscriber<Value>) -> SharedSubscription {
        _subscribe(context, subscriber)
    }
//    let storage: any FirebaseStorage
//    var workItem: DispatchWorkItem?
//    
//    let scheduler: (any ValueObservationScheduler & Hashable)?
//
////    let _load: (Value?) -> Value?
//    let _subscribe: (Value?, @escaping (_ newValue: Value?) -> Void) -> Shared<Value>.Subscription
//    
//    // Note: Only used for hashing...
//    private let renderedPath: String
//
//    // DECODABLE VERSIONS
//    
    public init<T: Decodable>(path: CollectionPath<T>) where Value == [T], T: Identifiable {
        self.renderedPath = path.rendered
        self.pathHash = path.pathHash
        @Dependency(\.defaultFirebaseStorage) var storage
        self.storage = storage
        self._load = { context, continuation in
            continuation.resumeReturningInitialValue()
        }
        self._subscribe = {
            context,
            subscriber in
            
            let transformed: SharedSubscriber<[(String, T)]> = subscriber.pullback { value in
                value.map(\.1)
            }
            return storage.collectionListener(path: path, subscriber: transformed)
        }
    }
    
    public init<T: Decodable>(path: CollectionPath<T>) where Value == [Identified<String, T>] {
        self.renderedPath = path.rendered
        self.pathHash = path.pathHash
        @Dependency(\.defaultFirebaseStorage) var storage
        self.storage = storage
        self._load = { context, continuation in
            continuation.resumeReturningInitialValue()
        }
        self._subscribe = {
            context,
            subscriber in
            
            let transformed: SharedSubscriber<[(String, T)]> = subscriber.pullback { value in
                value.map { Identified($0.1, id: $0.0) }
            }
            return storage.collectionListener(path: path, subscriber: transformed)
        }
        
    }

    
//
//    public init<T>(path: CollectionPath<T>) where Value == IdentifiedArray<String, Identified<String, T>>, T: Decodable, T: Equatable {
//        @Dependency(\.defaultFirebaseStorage) var storage
//        self.storage = storage
//        self.renderedPath = path.rendered
//        
//        let _value = LockIsolated<IdentifiedArray<String, Identified<String, T>>>([])
//        
//        self._load = { initialValue in
//            initialValue
//        }
//        self._subscribe = { initialValue, didSet in
//            let cancellable = storage.collectionListener(path: path) { (values: [(String, T)]) -> Void in
//                let identified = IdentifiedArray(values.map { Identified($0.1, id: $0.0) })
//                if identified != _value.value {
//                    _value.setValue(identified)
//                    didSet(identified)
//                }
//            }
//            return Shared.Subscription {
//                cancellable.cancel()
//            }
//        }
//    }
//    
//    public init<T>(query: FBQuery<T>) where Value == IdentifiedArray<String, Identified<String, T>>, T: Decodable, T: Equatable {
//        @Dependency(\.defaultFirebaseStorage) var storage
//        self.storage = storage
//        let path = query.path
//        self.renderedPath = path.rendered
//        
//        let _value = LockIsolated<IdentifiedArray<String, Identified<String, T>>>([])
//        
//        self._load = { initialValue in
//            initialValue
//        }
//        self._subscribe = { initialValue, didSet in
//            let cancellable = storage.collectionListener(path: path) { (values: [(String, T)]) -> Void in
//                let identified = IdentifiedArray(values.map { Identified($0.1, id: $0.0) })
//                if identified != _value.value {
//                    _value.setValue(identified)
//                    didSet(identified)
//                }
//            }
//            return Shared.Subscription {
//                cancellable.cancel()
//            }
//        }
//    }
//    
//    public init<T: Decodable>(path: CollectionPath<T>) where T: Identifiable, Value == IdentifiedArray<T.ID, T>, T: Equatable {
//        @Dependency(\.defaultFirebaseStorage) var storage
//        self.storage = storage
//        self.renderedPath = path.rendered
//        let _value = LockIsolated<IdentifiedArray<T.ID, T>>([])
//        let _map: LockIsolated<[T.ID: String]> = .init([:])
//        
//        self._load = { initialValue in
//            initialValue
//        }
//        self._subscribe = { initialValue, didSet in
//            let cancellable = storage.collectionListener(path: path) { (values: [(String, T)]) -> Void in
//                let identified = IdentifiedArray(values.map(\.1))
//                var map: [T.ID: String] = [:]
//                if identified != _value.value {
//                    _value.setValue(identified)
//                    for (key, value) in values {
//                        let id = value.id
//                        map[id] = key
//                    }
//                    _map.withValue { [map] in $0 = map }
//                    didSet(identified)
//                }
//            }
//            return Shared.Subscription {
//                cancellable.cancel()
//            }
//        }
//    }
//    
//    public init<T: Decodable>(query: FBQuery<T>) where T: Identifiable, Value == IdentifiedArray<T.ID, T>, T: Equatable {
//        @Dependency(\.defaultFirebaseStorage) var storage
//        self.storage = storage
//        let path = query.path
//        self.renderedPath = path.rendered
//        let _value = LockIsolated<IdentifiedArray<T.ID, T>>([])
//        let _map: LockIsolated<[T.ID: String]> = .init([:])
//        
//        self._load = { initialValue in
//            initialValue
//        }
//        self._subscribe = { initialValue, didSet in
//            let cancellable = storage.collectionListener(path: path) { (values: [(String, T)]) -> Void in
//                let identified = IdentifiedArray(values.map(\.1))
//                var map: [T.ID: String] = [:]
//                if identified != _value.value {
//                    _value.setValue(identified)
//                    for (key, value) in values {
//                        let id = value.id
//                        map[id] = key
//                    }
//                    _map.withValue { [map] in $0 = map }
//                    didSet(identified)
//                }
//            }
//            return Shared.Subscription {
//                cancellable.cancel()
//            }
//        }
//    }
//
//    public init(path: FBPath<Value>) where Value: Decodable {
//        @Dependency(\.defaultFirebaseStorage) var storage
//        self.storage = storage
//        self.renderedPath = path.rendered
//        let _value = LockIsolated<Value?>(nil)
//        
//        self._load = { initialValue in
//            try? storage.load(from: path) ?? initialValue
//        }
//        
//        self._subscribe = { initialValue, didSet in
//            let cancellable = storage.documentListener(path: path) { (value: Value) -> Void in
//                didSet(value)
//            }
//            return Shared.Subscription {
//                cancellable.cancel()
//            }
//        }
//        
//    }

//    func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
//        guard case .userInitiated = context else {
//            continuation.resumeReturningInitialValue()
//            return
//        }
//        guard !isTesting else {
//            continuation.resume(with: Result {
//                //try database.read(request.fetch)
//                fatalError()
//            })
//            return
//        }
//        let scheduler: any ValueObservationScheduler = scheduler ?? .async(onQueue: .main)
//
//    }

//    public func load(initialValue: Value?) -> Value? {
//        _load(initialValue)
//    }
//    
//    public func subscribe(
//        initialValue: Value?, didSet: @escaping (_ newValue: Value?) -> Void
//    ) -> Shared<Value>.Subscription {
//        _subscribe(initialValue, didSet)
//    }
}

//extension FirebaseStorageKey: Hashable {
//    public static func == (lhs: FirebaseStorageKey, rhs: FirebaseStorageKey) -> Bool {
//        lhs.renderedPath == rhs.renderedPath && lhs.storage === rhs.storage
//    }
//    
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(self.renderedPath)
//        hasher.combine(ObjectIdentifier(self.storage))
//    }
//}
//
//extension FirebaseStorageReaderKey: Hashable {
//    public static func == (lhs: FirebaseStorageReaderKey, rhs: FirebaseStorageReaderKey) -> Bool {
//        lhs.renderedPath == rhs.renderedPath && lhs.storage === rhs.storage
//    }
//    
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(self.renderedPath)
//        hasher.combine(ObjectIdentifier(self.storage))
//    }
//}


//#endif
