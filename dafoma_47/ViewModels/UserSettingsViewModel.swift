//
//  UserSettingsViewModel.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import Foundation
import SwiftUI

class UserSettingsViewModel: ObservableObject {
    @Published var userSettings: UserSettings
    @Published var userProfile: UserProfile?
    
    private let dataService = DataStorageService.shared
    private let authService = UserAuthenticationService.shared
    
    init() {
        self.userSettings = dataService.userSettings
        self.userProfile = dataService.userProfile
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe changes in DataStorageService
        dataService.$userSettings
            .assign(to: &$userSettings)
        
        dataService.$userProfile
            .assign(to: &$userProfile)
    }
    
    // MARK: - Settings Management
    func updateUserSettings(_ settings: UserSettings) {
        dataService.userSettings = settings
        dataService.saveUserSettings()
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        dataService.updateUserProfile(profile)
    }
    
    // MARK: - Profile Management
    func updateProfileName(_ name: String) {
        userSettings.userName = name
        if var profile = userProfile {
            profile.name = name
            updateUserProfile(profile)
        }
        updateUserSettings(userSettings)
    }
    
    func updateProfileEmail(_ email: String) {
        userSettings.userEmail = email
        if var profile = userProfile {
            profile.email = email
            updateUserProfile(profile)
        }
        updateUserSettings(userSettings)
    }
    
    func updateProfileImage(_ imageData: Data?) {
        userSettings.profileImageData = imageData
        updateUserSettings(userSettings)
    }
    
    // MARK: - Notification Settings
    func toggleNotifications() {
        userSettings.notificationsEnabled.toggle()
        updateUserSettings(userSettings)
    }
    
    func updateReminderTime(_ minutes: Int) {
        userSettings.reminderTime = minutes
        updateUserSettings(userSettings)
    }
    
    func toggleSound() {
        userSettings.soundEnabled.toggle()
        updateUserSettings(userSettings)
    }
    
    func toggleVibration() {
        userSettings.vibrationEnabled.toggle()
        updateUserSettings(userSettings)
    }
    
    // MARK: - App Settings
    func updateTheme(_ theme: UserSettings.AppTheme) {
        userSettings.theme = theme
        updateUserSettings(userSettings)
    }
    
    func updateLanguage(_ language: String) {
        userSettings.language = language
        updateUserSettings(userSettings)
    }
    
    func toggleAnalytics() {
        userSettings.analyticsEnabled.toggle()
        updateUserSettings(userSettings)
    }
    
    func toggleAutoSync() {
        userSettings.autoSyncEnabled.toggle()
        updateUserSettings(userSettings)
    }
    
    func updateDefaultProjectColor(_ color: String) {
        userSettings.defaultProjectColor = color
        updateUserSettings(userSettings)
    }
    
    func updateWorkingHours(start: Int, end: Int) {
        userSettings.workingHoursStart = start
        userSettings.workingHoursEnd = end
        updateUserSettings(userSettings)
    }
    
    // MARK: - Onboarding
    func completeOnboarding() {
        userSettings.hasCompletedOnboarding = true
        updateUserSettings(userSettings)
    }
    
    func resetOnboarding() {
        userSettings.hasCompletedOnboarding = false
        updateUserSettings(userSettings)
    }
    
    // MARK: - Authentication
    func signOut() {
        authService.signOut()
    }
    
    func deleteAccount() {
        // Reset all data but keep the app structure
        dataService.resetAllData()
        authService.signOut()
    }
    
    // MARK: - Data Export/Import
    func exportUserData() -> String? {
        let exportData = UserDataExport(
            userSettings: userSettings,
            userProfile: userProfile,
            tasks: dataService.tasks,
            projects: dataService.projects,
            exportDate: Date()
        )
        
        guard let jsonData = try? JSONEncoder().encode(exportData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return jsonString
    }
    
    func importUserData(from jsonString: String) -> Bool {
        guard let jsonData = jsonString.data(using: .utf8),
              let importData = try? JSONDecoder().decode(UserDataExport.self, from: jsonData) else {
            return false
        }
        
        // Update all data
        dataService.userSettings = importData.userSettings
        dataService.userProfile = importData.userProfile
        dataService.tasks = importData.tasks
        dataService.projects = importData.projects
        
        // Save all data
        dataService.saveUserSettings()
        dataService.saveUserProfile()
        dataService.saveTasks()
        dataService.saveProjects()
        
        return true
    }
    
    // MARK: - Statistics
    func getUserStatistics() -> UserStatistics {
        guard let profile = userProfile else {
            return UserStatistics(
                tasksCompleted: 0,
                projectsCompleted: 0,
                totalHoursWorked: 0,
                currentStreak: 0,
                level: 1,
                experience: 0,
                joinDate: Date(),
                averageTasksPerDay: 0,
                mostProductiveDay: "Monday",
                favoriteProjectColor: userSettings.defaultProjectColor
            )
        }
        
        let tasks = dataService.tasks
        let projects = dataService.projects
        
        // Calculate average tasks per day
        let daysSinceJoin = Calendar.current.dateComponents([.day], from: profile.joinDate, to: Date()).day ?? 1
        let averageTasksPerDay = Double(profile.tasksCompleted) / Double(max(daysSinceJoin, 1))
        
        // Find most productive day (simplified - would need more complex logic in real app)
        let mostProductiveDay = "Monday" // Placeholder
        
        // Find favorite project color
        let colorCounts = projects.reduce(into: [String: Int]()) { counts, project in
            counts[project.color, default: 0] += 1
        }
        let favoriteProjectColor = colorCounts.max(by: { $0.value < $1.value })?.key ?? userSettings.defaultProjectColor
        
        return UserStatistics(
            tasksCompleted: profile.tasksCompleted,
            projectsCompleted: profile.projectsCompleted,
            totalHoursWorked: profile.totalHoursWorked,
            currentStreak: profile.streak,
            level: profile.level,
            experience: profile.experience,
            joinDate: profile.joinDate,
            averageTasksPerDay: averageTasksPerDay,
            mostProductiveDay: mostProductiveDay,
            favoriteProjectColor: favoriteProjectColor
        )
    }
    
    // MARK: - Backup and Restore
    func createBackup() -> UserDataBackup? {
        let backup = UserDataBackup(
            userSettings: userSettings,
            userProfile: userProfile,
            tasks: dataService.tasks,
            projects: dataService.projects,
            backupDate: Date(),
            appVersion: "1.0"
        )
        
        return backup
    }
    
    func restoreFromBackup(_ backup: UserDataBackup) -> Bool {
        // Validate backup
        guard backup.appVersion == "1.0" else { return false }
        
        // Restore data
        dataService.userSettings = backup.userSettings
        dataService.userProfile = backup.userProfile
        dataService.tasks = backup.tasks
        dataService.projects = backup.projects
        
        // Save all data
        dataService.saveUserSettings()
        dataService.saveUserProfile()
        dataService.saveTasks()
        dataService.saveProjects()
        
        return true
    }
}

// MARK: - Data Models for Export/Import
struct UserDataExport: Codable {
    let userSettings: UserSettings
    let userProfile: UserProfile?
    let tasks: [Task]
    let projects: [Project]
    let exportDate: Date
}

struct UserDataBackup: Codable {
    let userSettings: UserSettings
    let userProfile: UserProfile?
    let tasks: [Task]
    let projects: [Project]
    let backupDate: Date
    let appVersion: String
}

struct UserStatistics {
    let tasksCompleted: Int
    let projectsCompleted: Int
    let totalHoursWorked: Double
    let currentStreak: Int
    let level: Int
    let experience: Int
    let joinDate: Date
    let averageTasksPerDay: Double
    let mostProductiveDay: String
    let favoriteProjectColor: String
    
    var experienceToNextLevel: Int {
        return (level * 100) - experience
    }
    
    var levelProgress: Double {
        let currentLevelExp = (level - 1) * 100
        let nextLevelExp = level * 100
        let progressExp = experience - currentLevelExp
        return Double(progressExp) / Double(nextLevelExp - currentLevelExp)
    }
}
