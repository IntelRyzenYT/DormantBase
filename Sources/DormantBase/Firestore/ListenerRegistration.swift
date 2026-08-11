//
//  ListenerRegistration.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/9/26.
//

import Foundation

/// A global actor responsible for orchestrating all Firestore polling listeners.
public actor ListenerRegistration {
    public static let shared = ListenerRegistration()
    
    /// Store listeners by a unique ID so they can be easily removed later.
    private var listeners: [UUID: @Sendable () async -> Void] = [:]
    private var pollingTask: Task<Void, Never>?
    
    /// Global polling interval
    private let interval: TimeInterval = 5.0
    
    private init() {}
    
    /// Registers a new listener and returns its unique ID.
    public func register(action: @escaping @Sendable () async -> Void) -> UUID {
        let id = UUID()
        listeners[id] = action
        
        /// Start the polling loop if this is the first listener
        if pollingTask == nil {
            startPolling()
        }
        
        return id
    }
    
    /// Removes a listener by ID. Stops the loop if no listeners remain.
    public func unregister(id: UUID) {
        listeners.removeValue(forKey: id)
        
        if listeners.isEmpty {
            stopPolling()
        }
    }
    
    private func startPolling() {
        pollingTask?.cancel()
        
        pollingTask = Task {
            while !Task.isCancelled {
                /// Execute all registered listeners concurrently
                await withTaskGroup(of: Void.self) { group in
                    for action in self.listeners.values {
                        group.addTask {
                            await action()
                        }
                    }
                }
                
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch {
                    /// Task was cancelled, exit the loop
                    break
                }
            }
        }
    }
    
    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
