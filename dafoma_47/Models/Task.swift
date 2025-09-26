//
//  Task.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import Foundation

struct Task: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?
    var createdDate: Date
    var projectId: UUID?
    var assignedTo: [String] // User IDs for collaboration
    var tags: [String]
    var estimatedHours: Double?
    var actualHours: Double?
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
        
        var color: String {
            switch self {
            case .low: return "#4CAF50"
            case .medium: return "#FF9800"
            case .high: return "#FF5722"
            case .urgent: return "#F44336"
            }
        }
        
        var sortOrder: Int {
            switch self {
            case .urgent: return 0
            case .high: return 1
            case .medium: return 2
            case .low: return 3
            }
        }
    }
    
    init(title: String, description: String = "", priority: Priority = .medium, dueDate: Date? = nil, projectId: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        self.createdDate = Date()
        self.projectId = projectId
        self.assignedTo = []
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
}

extension Task {
    static let sampleTasks: [Task] = [
        Task(title: "Design App Interface", description: "Create wireframes and mockups for the main screens", priority: .high, dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())),
        Task(title: "Implement Authentication", description: "Set up user login and registration system", priority: .urgent, dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())),
        Task(title: "Write Unit Tests", description: "Create comprehensive test coverage for core functionality", priority: .medium, dueDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())),
        Task(title: "Update Documentation", description: "Review and update project documentation", priority: .low, dueDate: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()))
    ]
}
