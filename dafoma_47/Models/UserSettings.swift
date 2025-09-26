//
//  UserSettings.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import Foundation

struct UserSettings: Codable {
    var userName: String
    var userEmail: String
    var profileImageData: Data?
    var notificationsEnabled: Bool
    var reminderTime: Int // minutes before due date
    var theme: AppTheme
    var language: String
    var hasCompletedOnboarding: Bool
    var analyticsEnabled: Bool
    var soundEnabled: Bool
    var vibrationEnabled: Bool
    var autoSyncEnabled: Bool
    var defaultProjectColor: String
    var workingHoursStart: Int // hour in 24h format
    var workingHoursEnd: Int // hour in 24h format
    
    enum AppTheme: String, CaseIterable, Codable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    init() {
        self.userName = ""
        self.userEmail = ""
        self.profileImageData = nil
        self.notificationsEnabled = true
        self.reminderTime = 60 // 1 hour before
        self.theme = .system
        self.language = "en"
        self.hasCompletedOnboarding = false
        self.analyticsEnabled = true
        self.soundEnabled = true
        self.vibrationEnabled = true
        self.autoSyncEnabled = true
        self.defaultProjectColor = "#fbd600"
        self.workingHoursStart = 9
        self.workingHoursEnd = 17
    }
    
    static let reminderOptions = [
        (15, "15 minutes"),
        (30, "30 minutes"),
        (60, "1 hour"),
        (120, "2 hours"),
        (1440, "1 day")
    ]
    
    func reminderDisplayText() -> String {
        if let option = Self.reminderOptions.first(where: { $0.0 == reminderTime }) {
            return option.1
        }
        return "\(reminderTime) minutes"
    }
}

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String
    var joinDate: Date
    var tasksCompleted: Int
    var projectsCompleted: Int
    var totalHoursWorked: Double
    var streak: Int // consecutive days with completed tasks
    var level: Int
    var experience: Int
    
    init(name: String, email: String) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.joinDate = Date()
        self.tasksCompleted = 0
        self.projectsCompleted = 0
        self.totalHoursWorked = 0
        self.streak = 0
        self.level = 1
        self.experience = 0
    }
    
    var experienceToNextLevel: Int {
        return (level * 100) - experience
    }
    
    var levelProgress: Double {
        let currentLevelExp = (level - 1) * 100
        let nextLevelExp = level * 100
        let progressExp = experience - currentLevelExp
        return Double(progressExp) / Double(nextLevelExp - currentLevelExp)
    }
    
    mutating func addExperience(_ points: Int) {
        experience += points
        while experience >= level * 100 {
            level += 1
        }
    }
}
