//
//  Project.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import Foundation

struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var color: String
    var createdDate: Date
    var dueDate: Date?
    var isCompleted: Bool
    var teamMembers: [String] // User IDs
    var tags: [String]
    var estimatedHours: Double?
    var actualHours: Double?
    
    init(name: String, description: String = "", color: String = "#fbd600", dueDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.color = color
        self.createdDate = Date()
        self.dueDate = dueDate
        self.isCompleted = false
        self.teamMembers = []
        self.tags = []
        self.estimatedHours = nil
        self.actualHours = nil
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    var completionRate: Double {
        guard let estimated = estimatedHours, estimated > 0 else { return 0 }
        let actual = actualHours ?? 0
        return min(actual / estimated, 1.0)
    }
    
    func tasksCount(from tasks: [Task]) -> Int {
        return tasks.filter { $0.projectId == self.id }.count
    }
    
    func completedTasksCount(from tasks: [Task]) -> Int {
        return tasks.filter { $0.projectId == self.id && $0.isCompleted }.count
    }
    
    func projectProgress(from tasks: [Task]) -> Double {
        let projectTasks = tasks.filter { $0.projectId == self.id }
        guard !projectTasks.isEmpty else { return 0 }
        
        let completedTasks = projectTasks.filter { $0.isCompleted }.count
        return Double(completedTasks) / Double(projectTasks.count)
    }
}

extension Project {
    static let sampleProjects: [Project] = [
        Project(name: "Mobile App Development", description: "Complete iOS application with modern UI/UX", color: "#fbd600", dueDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())),
        Project(name: "Website Redesign", description: "Modernize company website with responsive design", color: "#4CAF50", dueDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())),
        Project(name: "Marketing Campaign", description: "Q4 marketing strategy and implementation", color: "#FF9800", dueDate: Calendar.current.date(byAdding: .weekOfYear, value: 3, to: Date())),
        Project(name: "Database Migration", description: "Migrate legacy database to cloud infrastructure", color: "#2196F3", dueDate: Calendar.current.date(byAdding: .weekOfYear, value: 6, to: Date()))
    ]
}
