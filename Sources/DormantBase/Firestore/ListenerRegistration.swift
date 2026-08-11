//
//  ListenerRegistration.swift
//  DormantBase
//
//  Created by Samarth Bhate on 8/9/26.
//


public class ListenerRegistration {
    private var timer: Timer?
    
    internal func startPolling(interval: TimeInterval, action: @escaping () -> Void) {
        action()
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                action()
            }
        }
    }
    
    public func remove() {
        timer?.invalidate()
        timer = nil
    }
}