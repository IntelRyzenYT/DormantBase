//
//  FieldMapper.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/9/26.
//


import Foundation

public struct FirestoreFieldMapper {
    
    public static func encode(_ data: [String: Any]) -> Data? {
        /// String:Any
        var fields = [String: Any]()
        
        /// Encode each
        for (key, value) in data {
            fields[key] = encodeValue(value)
        }
        let payload: [String: Any] = ["fields": fields]
        return try? JSONSerialization.data(withJSONObject: payload)
    }

    public static func encodeFieldValue(_ value: FieldReference.FieldType) -> [String: Any] {
        switch value {
        case .stringValue(let stringValue):
            return ["stringValue": stringValue]
        case .nullValue:
            return ["nullValue": "NULL_VALUE"]
        case .booleanValue(let booleanValue):
            return ["booleanValue": booleanValue]
        case .integerValue(let integerValue):
            return ["integerValue": "\(integerValue)"]
        case .doubleValue(let doubleValue):
            return ["doubleValue": doubleValue]
        case .timestamp(let timestampValue):
            return ["timestampValue": encodeTimestamp(timestampValue)]
        case .geoPointValue(let geoPointValue):
            return [
                "geoPointValue": [
                    "latitude": geoPointValue.latitude,
                    "longitude": geoPointValue.longitude
                ]
            ]
        case .arrayValue(let arrayValue):
            return ["arrayValue": ["values": arrayValue.map(encodeValue)]]
        case .mapValue(let mapValue):
            var mapFields = [String: Any]()

            for (key, value) in mapValue {
                mapFields[String(describing: key)] = encodeValue(value)
            }

            return ["mapValue": ["fields": mapFields]]
        }
    }
    
    
    private static func encodeValue(_ value: Any) -> [String: Any] {
        if let str = value as? String { return ["stringValue": str] }
        if let int = value as? Int { return ["integerValue": "\(int)"] }
        if let double = value as? Double { return ["doubleValue": double] }
        if let bool = value as? Bool { return ["booleanValue": bool] }
        if let date = value as? Date { return ["timestampValue": encodeTimestamp(date)] }
        if let geopoint = value as? LatLng {
            return [
                "geoPointValue": [
                    "latitude": geopoint.latitude,
                    "longitude": geopoint.longitude
                ]
            ]
        }
        
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
        if typeDict["nullValue"] != nil { return NSNull() }
        if let val = typeDict["timestampValue"] as? String { return decodeTimestamp(val) }
        if let val = typeDict["geoPointValue"] as? [String: Any],
           let latitude = val["latitude"] as? Double,
           let longitude = val["longitude"] as? Double {
            return LatLng(latitude: latitude, longitude: longitude)
        }
        
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

    private static func decodeTimestamp(_ timestamp: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = fractionalFormatter.date(from: timestamp) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: timestamp)
    }

    private static func encodeTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
