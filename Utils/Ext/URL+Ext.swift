//
//  URL+Ext.swift
//  Utils
//
//  Created by Andriy Biguniak on 10.05.2025.
//

import Foundation
//https://nshipster.com/extended-file-attributes/


extension URL
{
    /// Get extended attribute.
    func extendedAttribute(forName name: String) throws -> Data  {
        let data = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in
            // Determine attribute size:
            let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
            guard length >= 0 else { throw URL._posixError(errno, name) }
            // Create buffer with required size:
            var data = Data(count: length)
            // Retrieve attribute:
            let result =  data.withUnsafeMutableBytes { [count = data.count] in
                getxattr(fileSystemPath, name, $0.baseAddress, count, 0, 0)
            }
            guard result >= 0 else { throw URL._posixError(errno, name) }
            return data
        }
        return data
    }
    
    
    /// Set extended attribute.
    func setExtendedAttribute(data: Data, forName name: String) throws {
        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = data.withUnsafeBytes {
                setxattr(fileSystemPath, name, $0.baseAddress, data.count, 0, 0)
            }
            guard result >= 0 else { throw URL._posixError(errno, name) }
        }
    }
    
    
    /// Remove extended attribute.
    func removeExtendedAttribute(forName name: String) throws {
        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = removexattr(fileSystemPath, name, 0)
            guard result >= 0 else { throw URL._posixError(errno, name) }
        }
    }
    
    
    /// Get list of all extended attributes.
    func listExtendedAttributes() throws -> [String] {
        let list = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> [String] in
            let length = listxattr(fileSystemPath, nil, 0, 0)
            guard length >= 0 else { throw URL._posixError(errno, self.absoluteString) }
            // Create buffer with required size:
            var namebuf = Array<CChar>(repeating: 0, count: length)
            // Retrieve attribute list:
            let result = listxattr(fileSystemPath, &namebuf, namebuf.count, 0)
            guard result >= 0 else { throw URL._posixError(errno, self.absoluteString) }
            // Extract attribute names:
            let list = namebuf.split(separator: 0).compactMap {
                $0.withUnsafeBufferPointer {
                    $0.withMemoryRebound(to: UInt8.self) {
                        String(bytes: $0, encoding: .utf8)
                    }
                }
            }
            return list
        }
        return list
    }


    /// Helper function to create an NSError from a Unix errno.
    private static func _posixError(_ err: Int32, _ target: String) -> NSError {
        return NSError(domain: NSPOSIXErrorDomain, code: Int(err),
                       userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err)),
                                  "target": target])
    }
}


extension URL
{
    var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
    
    public func regularFileAllocatedSize() throws -> UInt {
        let resourceValues = try self.resourceValues(forKeys: [
            .isRegularFileKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey,
        ])
        // We only look at regular files.
        guard resourceValues.isRegularFile ?? false else {
            return 0
        }
        // To get the file's size we first try the most comprehensive value in terms of what
        // the file may use on disk. This includes metadata, compression (on file system
        // level) and block size.
        // In case totalFileAllocatedSize is unavailable we use the fallback value (excluding
        // meta data and compression) This value should always be available.
        return UInt (resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
    }
    
    
    public var creation: Date? {
        get {
            return (try? resourceValues(forKeys: [.creationDateKey]))?.creationDate
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.creationDate = newValue
            try? setResourceValues(resourceValues)
        }
    }
    
    
    /// The time at which the resource was most recently modified.
    /// This key corresponds to an Date value, or nil if the volume doesn't support modification dates.
    public var contentModification: Date? {
        get {
            return (try? resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.contentModificationDate = newValue
            try? setResourceValues(resourceValues)
        }
    }
    
    
    /// The time at which the resource was most recently accessed.
    /// This key corresponds to an Date value, or nil if the volume doesn't support access dates.
    ///  When you set the contentAccessDateKey for a resource, also set contentModificationDateKey in the same call to the setResourceValues(_:) method. Otherwise, the file system may set the contentAccessDateKey value to the current contentModificationDateKey value.
    public var contentAccess: Date? {
        get {
            return (try? resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate
        }
        // Beginning in macOS 10.13, iOS 11, watchOS 4, tvOS 11, and later, contentAccessDateKey is read-write. Attempts to set a value for this file resource property on earlier systems are ignored.
        set {
            var resourceValues = URLResourceValues()
            resourceValues.contentAccessDate = newValue
            try? setResourceValues(resourceValues)
        }
    }
}
