//
//  DataStorageService.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import Foundation

class DataStorageService: ObservableObject {
    static let shared = DataStorageService()
    
    private let userDefaults = UserDefaults.standard
    private let tasksKey = "TaskSphere_Tasks"
    private let projectsKey = "TaskSphere_Projects"
    private let userSettingsKey = "TaskSphere_UserSettings"
    private let userProfileKey = "TaskSphere_UserProfile"
    
    @Published var tasks: [Task] = []
    @Published var projects: [Project] = []
    @Published var userSettings: UserSettings = UserSettings()
    @Published var userProfile: UserProfile? = nil
    
    private init() {
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        loadTasks()
        loadProjects()
        loadUserSettings()
        loadUserProfile()
    }
    
    private func loadTasks() {
        if let data = userDefaults.data(forKey: tasksKey),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            self.tasks = decodedTasks
        } else {
            // Load sample data for first launch
            self.tasks = Task.sampleTasks
            saveTasks()
        }
    }
    
    private func loadProjects() {
        if let data = userDefaults.data(forKey: projectsKey),
           let decodedProjects = try? JSONDecoder().decode([Project].self, from: data) {
            self.projects = decodedProjects
        } else {
            // Load sample data for first launch
            self.projects = Project.sampleProjects
            saveProjects()
        }
    }
    
    private func loadUserSettings() {
        if let data = userDefaults.data(forKey: userSettingsKey),
           let decodedSettings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.userSettings = decodedSettings
        } else {
            self.userSettings = UserSettings()
            saveUserSettings()
        }
    }
    
    private func loadUserProfile() {
        if let data = userDefaults.data(forKey: userProfileKey),
           let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = decodedProfile
        }
    }
    
    // MARK: - Data Saving
    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: tasksKey)
        }
    }
    
    func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            userDefaults.set(encoded, forKey: projectsKey)
        }
    }
    
    func saveUserSettings() {
        if let encoded = try? JSONEncoder().encode(userSettings) {
            userDefaults.set(encoded, forKey: userSettingsKey)
        }
    }
    
    func saveUserProfile() {
        if let profile = userProfile,
           let encoded = try? JSONEncoder().encode(profile) {
            userDefaults.set(encoded, forKey: userProfileKey)
        }
    }
    
    // MARK: - Task Management
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
            
            // Update user profile if task completed
            if task.isCompleted && userProfile != nil {
                userProfile!.tasksCompleted += 1
                userProfile!.addExperience(10)
                saveUserProfile()
            }
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updateTask(updatedTask)
    }
    
    // MARK: - Project Management
    func addProject(_ project: Project) {
        projects.append(project)
        saveProjects()
    }
    
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects()
            
            // Update user profile if project completed
            if project.isCompleted && userProfile != nil {
                userProfile!.projectsCompleted += 1
                userProfile!.addExperience(50)
                saveUserProfile()
            }
        }
    }
    
    func deleteProject(_ project: Project) {
        // Also delete all tasks associated with this project
        tasks.removeAll { $0.projectId == project.id }
        projects.removeAll { $0.id == project.id }
        saveTasks()
        saveProjects()
    }
    
    // MARK: - User Profile Management
    func createUserProfile(name: String, email: String) {
        userProfile = UserProfile(name: name, email: email)
        userSettings.userName = name
        userSettings.userEmail = email
        userSettings.hasCompletedOnboarding = true
        saveUserProfile()
        saveUserSettings()
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveUserProfile()
    }
    
    // MARK: - Analytics
    func getTaskCompletionRate() -> Double {
        guard !tasks.isEmpty else { return 0 }
        let completedTasks = tasks.filter { $0.isCompleted }.count
        return Double(completedTasks) / Double(tasks.count)
    }
    
    func getProjectCompletionRate() -> Double {
        guard !projects.isEmpty else { return 0 }
        let completedProjects = projects.filter { $0.isCompleted }.count
        return Double(completedProjects) / Double(projects.count)
    }
    
    func getTasksByPriority() -> [Task.Priority: Int] {
        var priorityCount: [Task.Priority: Int] = [:]
        for priority in Task.Priority.allCases {
            priorityCount[priority] = tasks.filter { $0.priority == priority && !$0.isCompleted }.count
        }
        return priorityCount
    }
    
    func getOverdueTasks() -> [Task] {
        return tasks.filter { $0.isOverdue }
    }
    
    func getUpcomingTasks(days: Int = 7) -> [Task] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate >= Date() && dueDate <= endDate
        }
    }
    
    // MARK: - Data Reset
    func resetAllData() {
        tasks.removeAll()
        projects.removeAll()
        userSettings = UserSettings()
        userProfile = nil
        
        userDefaults.removeObject(forKey: tasksKey)
        userDefaults.removeObject(forKey: projectsKey)
        userDefaults.removeObject(forKey: userSettingsKey)
        userDefaults.removeObject(forKey: userProfileKey)
    }
}
