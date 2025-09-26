//
//  TaskViewModel.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import Foundation
import SwiftUI
import Combine

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var filteredTasks: [Task] = []
    @Published var searchText = ""
    @Published var selectedPriority: Task.Priority?
    @Published var selectedProject: Project?
    @Published var showCompletedTasks = true
    @Published var sortOption: TaskSortOption = .dueDate
    
    private let dataService = DataStorageService.shared
    
    enum TaskSortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case priority = "Priority"
        case createdDate = "Created Date"
        case title = "Title"
        
        var systemImage: String {
            switch self {
            case .dueDate: return "calendar"
            case .priority: return "exclamationmark.triangle"
            case .createdDate: return "clock"
            case .title: return "textformat.abc"
            }
        }
    }
    
    init() {
        loadTasks()
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe changes in DataStorageService
        dataService.$tasks
            .assign(to: &$tasks)
        
        // Update filtered tasks when any filter changes
        Publishers.CombineLatest4($tasks, $searchText, $selectedPriority, $showCompletedTasks)
            .map { [weak self] tasks, searchText, priority, showCompleted in
                self?.filterTasks(tasks: tasks, searchText: searchText, priority: priority, showCompleted: showCompleted) ?? []
            }
            .assign(to: &$filteredTasks)
    }
    
    private func loadTasks() {
        tasks = dataService.tasks
    }
    
    // MARK: - Task Management
    func addTask(_ task: Task) {
        dataService.addTask(task)
    }
    
    func updateTask(_ task: Task) {
        dataService.updateTask(task)
    }
    
    func deleteTask(_ task: Task) {
        dataService.deleteTask(task)
    }
    
    func toggleTaskCompletion(_ task: Task) {
        dataService.toggleTaskCompletion(task)
    }
    
    // MARK: - Filtering and Sorting
    private func filterTasks(tasks: [Task], searchText: String, priority: Task.Priority?, showCompleted: Bool) -> [Task] {
        var filtered = tasks
        
        // Filter by completion status
        if !showCompleted {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Filter by priority
        if let priority = priority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        // Filter by project
        if let project = selectedProject {
            filtered = filtered.filter { $0.projectId == project.id }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText) ||
                task.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort tasks
        return sortTasks(filtered)
    }
    
    private func sortTasks(_ tasks: [Task]) -> [Task] {
        switch sortOption {
        case .dueDate:
            return tasks.sorted { task1, task2 in
                // Tasks without due date go to the end
                guard let date1 = task1.dueDate else { return false }
                guard let date2 = task2.dueDate else { return true }
                return date1 < date2
            }
        case .priority:
            return tasks.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
        case .createdDate:
            return tasks.sorted { $0.createdDate > $1.createdDate }
        case .title:
            return tasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
    
    func clearFilters() {
        searchText = ""
        selectedPriority = nil
        selectedProject = nil
        showCompletedTasks = true
    }
    
    // MARK: - Analytics
    func getTasksForToday() -> [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow && !task.isCompleted
        }
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
    
    func getCompletionRate() -> Double {
        guard !tasks.isEmpty else { return 0 }
        let completedTasks = tasks.filter { $0.isCompleted }.count
        return Double(completedTasks) / Double(tasks.count)
    }
    
    func getTasksByPriority() -> [Task.Priority: Int] {
        var priorityCount: [Task.Priority: Int] = [:]
        for priority in Task.Priority.allCases {
            priorityCount[priority] = tasks.filter { $0.priority == priority && !$0.isCompleted }.count
        }
        return priorityCount
    }
    
    // MARK: - Bulk Operations
    func markAllTasksAsCompleted(for project: Project? = nil) {
        let tasksToUpdate: [Task]
        if let project = project {
            tasksToUpdate = tasks.filter { $0.projectId == project.id && !$0.isCompleted }
        } else {
            tasksToUpdate = tasks.filter { !$0.isCompleted }
        }
        
        for task in tasksToUpdate {
            var updatedTask = task
            updatedTask.isCompleted = true
            updateTask(updatedTask)
        }
    }
    
    func deleteCompletedTasks() {
        let completedTasks = tasks.filter { $0.isCompleted }
        for task in completedTasks {
            deleteTask(task)
        }
    }
    
    // MARK: - Task Creation Helpers
    func createQuickTask(title: String, priority: Task.Priority = .medium, projectId: UUID? = nil) {
        let task = Task(title: title, priority: priority, projectId: projectId)
        addTask(task)
    }
    
    func duplicateTask(_ task: Task) {
        var newTask = task
        newTask.title = "\(task.title) (Copy)"
        newTask.isCompleted = false
        newTask.createdDate = Date()
        addTask(newTask)
    }
}
