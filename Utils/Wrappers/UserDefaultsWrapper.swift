//
//  UserDefaultsWrapper.swift
//  Utils
//
//  Created by Andriy Biguniak on 22.07.2025.
//

import Foundation


@propertyWrapper
public struct UserDefaultsWrapper<T: UserDefaultsSerializable>
{
    private let userDefaults: UserDefaults

    /// The key for the value in `UserDefaults`.
    public let key: String

    /// The value retrieved from `UserDefaults`.
    public var wrappedValue: T {
        get { self.userDefaults.fetch(self.key) }
        set { self.userDefaults.save(newValue, for: self.key) }
    }

    /// Initializes the property wrapper.
    /// - Parameters:
    ///   - wrappedValue: The default value to register for the specified key.
    ///   - keyName: The key for the value in `UserDefaults`.
    ///   - userDefaults: The `UserDefaults` backing store. The default value is `.standard`.
    public init(
        defaultValue: T,
        key keyName: String,
        userDefaults: UserDefaults = .standard
    ) {
        self.key = keyName
        self.userDefaults = userDefaults
        userDefaults.registerDefault(value: defaultValue, key: keyName)
    }
}


@propertyWrapper
public struct UserDefaultsOprionalWrapper<T: UserDefaultsSerializable>
{
    private let userDefaults: UserDefaults

    /// The key for the value in `UserDefaults`.
    public let key: String

    /// The value retreived from `UserDefaults`, if any exists.
    public var wrappedValue: T? {
        get { self.userDefaults.fetchOptional(self.key) }
        set {
            if let newValue = newValue {
                self.userDefaults.save(newValue, for: self.key)
            } else {
                self.userDefaults.delete(for: self.key)
            }
        }
    }

    /// Initializes the property wrapper.
    /// - Parameters:
    ///   - keyName: The key for the value in `UserDefaults`.
    ///   - userDefaults: The `UserDefaults` backing store. The default value is `.standard`.
    public init(key keyName: String, userDefaults: UserDefaults = .standard) {
        self.key = keyName
        self.userDefaults = userDefaults
    }
}


// MARK: - UserDefaultsSerializable

public protocol UserDefaultsSerializable
{

    /// The type of the value that is stored in `UserDefaults`.
    associatedtype StoredValue

    /// The value to store in `UserDefaults`.
    var storedValue: StoredValue { get }

    /// Initializes the object using the provided value.
    ///
    /// - Parameter storedValue: The previously store value fetched from `UserDefaults`.
    init(storedValue: StoredValue)
}

extension Int: UserDefaultsSerializable
{
    public var storedValue: Self { self }

    public init(storedValue: Self) {
        self = storedValue
    }
}

extension UInt: UserDefaultsSerializable
{
    public var storedValue: Self { self }

    public init(storedValue: Self) {
        self = storedValue
    }
}

extension UInt64: UserDefaultsSerializable
{
    public var storedValue: Self { self }

    public init(storedValue: Self) {
        self = storedValue
    }
}

extension Float: UserDefaultsSerializable
{
    public var storedValue: Self { self }

    public init(storedValue: Self) {
        self = storedValue
    }
}

extension Double: UserDefaultsSerializable
{
    public var storedValue: Self { self }

    public init(storedValue: Self) {
        self = storedValue
    }
}

extension String: UserDefaultsSerializable
{
    public var storedValue: Self { self }

    public init(storedValue: Self) {
        self = storedValue
    }
}

extension Bool: UserDefaultsSerializable
{
    public var storedValue: Self { self }
    
    public init(storedValue: Self) {
        self = storedValue
    }
}

extension URL: UserDefaultsSerializable
{
    public var storedValue: Self { self }

    public init(storedValue: Self) {
        self = storedValue
    }
}

extension Date: UserDefaultsSerializable
{
    public var storedValue: Self { self }

    public init(storedValue: Self) {
        self = storedValue
    }
}

extension Data: UserDefaultsSerializable
{
    public var storedValue: Self { self }

    public init(storedValue: Self) {
        self = storedValue
    }
}

extension Array: UserDefaultsSerializable where Element: UserDefaultsSerializable
{
    public var storedValue: [Element.StoredValue] {
        self.map { $0.storedValue }
    }

    public init(storedValue: [Element.StoredValue]) {
        self = storedValue.map { Element(storedValue: $0) }
    }
}

extension Set: UserDefaultsSerializable where Element: UserDefaultsSerializable
{
    public var storedValue: [Element.StoredValue] {
        self.map { $0.storedValue }
    }

    public init(storedValue: [Element.StoredValue]) {
        self = Set(storedValue.map { Element(storedValue: $0) })
    }
}

extension Dictionary: UserDefaultsSerializable where Key == String, Value: UserDefaultsSerializable
{
    public var storedValue: [String: Value.StoredValue] {
        self.mapValues { $0.storedValue }
    }

    public init(storedValue: [String: Value.StoredValue]) {
        self = storedValue.mapValues { Value(storedValue: $0) }
    }
}

extension UserDefaultsSerializable where Self: RawRepresentable, Self.RawValue: UserDefaultsSerializable
{
    public var storedValue: RawValue.StoredValue {
        self.rawValue.storedValue
    }

    public init(storedValue: RawValue.StoredValue) {
        self = Self(rawValue: Self.RawValue(storedValue: storedValue))!
    }
}
