//
//  NotificationManager.swift
//  WatchGarage
//
//  Created by Eissa Ahmad on 2025-12-07.
//


import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func scheduleNotifications(for watch: Watch) {
        // Cancel existing notifications for this watch first
        cancelNotifications(for: watch)
        
        // Schedule battery notifications (only for quartz watches)
        if watch.movementType == .quartz {
            scheduleBatteryNotifications(for: watch)
        }
        
        // Schedule service notifications (for all watches)
        scheduleServiceNotifications(for: watch)
    }
    
    private func scheduleBatteryNotifications(for watch: Watch) {
        let calendar = Calendar.current
        let batteryEndDate = calendar.date(byAdding: .day, value: watch.batteryLife, to: watch.lastBatteryDate) ?? Date()
        let halfwayDate = calendar.date(byAdding: .day, value: watch.batteryLife / 2, to: watch.lastBatteryDate) ?? Date()
        
        // Halfway notification
        if halfwayDate > Date() {
            let halfwayContent = UNMutableNotificationContent()
            halfwayContent.title = "Battery Halfway - \(watch.name)"
            halfwayContent.body = "\(watch.model) battery is halfway through its life. Consider planning a replacement soon."
            halfwayContent.sound = .default
            
            let halfwayComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: halfwayDate)
            let halfwayTrigger = UNCalendarNotificationTrigger(dateMatching: halfwayComponents, repeats: false)
            let halfwayRequest = UNNotificationRequest(identifier: "battery-halfway-\(watch.id)", content: halfwayContent, trigger: halfwayTrigger)
            
            UNUserNotificationCenter.current().add(halfwayRequest)
        }
        
        // Due notification
        if batteryEndDate > Date() {
            let dueContent = UNMutableNotificationContent()
            dueContent.title = "Battery Replacement Due - \(watch.name)"
            dueContent.body = "\(watch.model) battery replacement is due today!"
            dueContent.sound = .default
            
            let dueComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: batteryEndDate)
            let dueTrigger = UNCalendarNotificationTrigger(dateMatching: dueComponents, repeats: false)
            let dueRequest = UNNotificationRequest(identifier: "battery-due-\(watch.id)", content: dueContent, trigger: dueTrigger)
            
            UNUserNotificationCenter.current().add(dueRequest)
        }
    }
    
    private func scheduleServiceNotifications(for watch: Watch) {
        let calendar = Calendar.current
        let serviceEndDate = calendar.date(byAdding: .day, value: watch.serviceInterval, to: watch.lastServiceDate) ?? Date()
        let halfwayDate = calendar.date(byAdding: .day, value: watch.serviceInterval / 2, to: watch.lastServiceDate) ?? Date()
        
        // Halfway notification
        if halfwayDate > Date() {
            let halfwayContent = UNMutableNotificationContent()
            halfwayContent.title = "Service Halfway - \(watch.name)"
            halfwayContent.body = "\(watch.model) service interval is halfway through. Start planning your next service."
            halfwayContent.sound = .default
            
            let halfwayComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: halfwayDate)
            let halfwayTrigger = UNCalendarNotificationTrigger(dateMatching: halfwayComponents, repeats: false)
            let halfwayRequest = UNNotificationRequest(identifier: "service-halfway-\(watch.id)", content: halfwayContent, trigger: halfwayTrigger)
            
            UNUserNotificationCenter.current().add(halfwayRequest)
        }
        
        // Due notification
        if serviceEndDate > Date() {
            let dueContent = UNMutableNotificationContent()
            dueContent.title = "Service Due - \(watch.name)"
            dueContent.body = "\(watch.model) service is due today!"
            dueContent.sound = .default
            
            let dueComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: serviceEndDate)
            let dueTrigger = UNCalendarNotificationTrigger(dateMatching: dueComponents, repeats: false)
            let dueRequest = UNNotificationRequest(identifier: "service-due-\(watch.id)", content: dueContent, trigger: dueTrigger)
            
            UNUserNotificationCenter.current().add(dueRequest)
        }
    }
    
    func cancelNotifications(for watch: Watch) {
        let identifiers = [
            "battery-halfway-\(watch.id)",
            "battery-due-\(watch.id)",
            "service-halfway-\(watch.id)",
            "service-due-\(watch.id)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}