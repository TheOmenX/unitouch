//
//  DataManager.swift
//  unitouch
//
//  Created by Tijn Giesberts on 31/03/2026.
//

import Foundation

class DataManager {
    static let shared = DataManager()
    private init() {}
    
    // MARK: - Save Any Codable Object
    /// Saves any object that conforms to Codable into UserDefaults.
    /// - Parameters:
    ///   - object: The struct or class to save (must conform to Codable)
    ///   - key: The unique string key to save it under
    func save<T: Codable>(_ object: T, forKey key: String) {
        do {
            let encodedData = try JSONEncoder().encode(object)
            UserDefaults.standard.set(encodedData, forKey: key)
            print("Successfully saved data for key: \(key)")
        } catch {
            print("Failed to save data for key \(key): \(error)")
        }
    }
    
    // MARK: - Load Any Codable Object
    /// Loads any object that conforms to Codable from UserDefaults.
    /// - Parameters:
    ///   - key: The unique string key it was saved under
    ///   - type: The Type you expect to get back (e.g., UserSettings.self)
    /// - Returns: The decoded object, or nil if it doesn't exist or decoding fails
    func load<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let savedData = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: savedData)
            return decodedObject
        } catch {
            print("Failed to load data for key \(key): \(error)")
            return nil
        }
    }
    
    // MARK: - Delete Data
    /// Removes the saved data for a specific key
    func delete(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        print("Deleted data for key: \(key)")
    }
}
