//
//  FirestoreFieldMapper.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/9/26.
//


import Foundation

// MARK: - Firestore Field Mapper
public struct FirestoreFieldMapper {
    
    // MARK: Swift -> Firestore JSON
    public static func encode(_ data: [String: Any]) -> Data? {
        var fields = [String: Any]()
        for (key, value) in data {
            fields[key] = encodeValue(value)
        }
        let payload: [String: Any] = ["fields": fields]
        return try? JSONSerialization.data(withJSONObject: payload)
    }
    
    private static func encodeValue(_ value: Any) -> [String: Any] {
        if let str = value as? String { return ["stringValue": str] }
        // Firestore REST expects integers as strings to prevent 64-bit precision loss
        if let int = value as? Int { return ["integerValue": "\(int)"] }
        if let double = value as? Double { return ["doubleValue": double] }
        if let bool = value as? Bool { return ["booleanValue": bool] }
        
        if let array = value as? [Any] {
            return ["arrayValue": ["values": array.map(encodeValue)]]
        }
        if let dict = value as? [String: Any] {
            var mapFields = [String: Any]()
            for (k, v) in dict { mapFields[k] = encodeValue(v) }
            return ["mapValue": ["fields": mapFields]]
        }
        
        return ["nullValue": NSNull()]
    }
    
    // MARK: Firestore JSON -> Swift
    public static func decode(_ data: Data) -> [String: Any]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fields = json["fields"] as? [String: Any] else {
            return nil
        }
        return decodeFields(fields)
    }
    
    private static func decodeFields(_ fields: [String: Any]) -> [String: Any] {
        var result = [String: Any]()
        for (key, value) in fields {
            if let typeDict = value as? [String: Any], let parsed = decodeValue(typeDict) {
                result[key] = parsed
            }
        }
        return result
    }
    
    private static func decodeValue(_ typeDict: [String: Any]) -> Any? {
        if let val = typeDict["stringValue"] as? String { return val }
        if let val = typeDict["integerValue"] as? String { return Int(val) }
        if let val = typeDict["doubleValue"] as? Double { return val }
        if let val = typeDict["booleanValue"] as? Bool { return val }
        
        if let arrayVal = typeDict["arrayValue"] as? [String: Any],
           let values = arrayVal["values"] as? [[String: Any]] {
            return values.compactMap(decodeValue)
        }
        
        if let mapVal = typeDict["mapValue"] as? [String: Any],
           let fields = mapVal["fields"] as? [String: Any] {
            return decodeFields(fields)
        }
        
        return nil
    }
}