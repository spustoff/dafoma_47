//
//  ProjectViewModel.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import Foundation
import SwiftUI
import Combine

class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var filteredProjects: [Project] = []
    @Published var searchText = ""
    @Published var showCompletedProjects = true
    @Published var sortOption: ProjectSortOption = .createdDate
    
    private let dataService = DataStorageService.shared
    
    enum ProjectSortOption: String, CaseIterable {
        case createdDate = "Created Date"
        case dueDate = "Due Date"
        case name = "Name"
        case progress = "Progress"
        
        var systemImage: String {
            switch self {
            case .createdDate: return "clock"
            case .dueDate: return "calendar"
            case .name: return "textformat.abc"
            case .progress: return "chart.bar"
            }
        }
    }
    
    init() {
        loadProjects()
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe changes in DataStorageService
        dataService.$projects
            .assign(to: &$projects)
        
        // Update filtered projects when any filter changes
        Publishers.CombineLatest3($projects, $searchText, $showCompletedProjects)
            .map { [weak self] projects, searchText, showCompleted in
                self?.filterProjects(projects: projects, searchText: searchText, showCompleted: showCompleted) ?? []
            }
            .assign(to: &$filteredProjects)
    }
    
    private func loadProjects() {
        projects = dataService.projects
    }
    
    // MARK: - Project Management
    func addProject(_ project: Project) {
        dataService.addProject(project)
    }
    
    func updateProject(_ project: Project) {
        dataService.updateProject(project)
    }
    
    func deleteProject(_ project: Project) {
        dataService.deleteProject(project)
    }
    
    func toggleProjectCompletion(_ project: Project) {
        var updatedProject = project
        updatedProject.isCompleted.toggle()
        updateProject(updatedProject)
    }
    
    // MARK: - Filtering and Sorting
    private func filterProjects(projects: [Project], searchText: String, showCompleted: Bool) -> [Project] {
        var filtered = projects
        
        // Filter by completion status
        if !showCompleted {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                project.description.localizedCaseInsensitiveContains(searchText) ||
                project.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort projects
        return sortProjects(filtered)
    }
    
    private func sortProjects(_ projects: [Project]) -> [Project] {
        switch sortOption {
        case .createdDate:
            return projects.sorted { $0.createdDate > $1.createdDate }
        case .dueDate:
            return projects.sorted { project1, project2 in
                // Projects without due date go to the end
                guard let date1 = project1.dueDate else { return false }
                guard let date2 = project2.dueDate else { return true }
                return date1 < date2
            }
        case .name:
            return projects.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .progress:
            return projects.sorted { project1, project2 in
                let progress1 = project1.projectProgress(from: dataService.tasks)
                let progress2 = project2.projectProgress(from: dataService.tasks)
                return progress1 > progress2
            }
        }
    }
    
    func clearFilters() {
        searchText = ""
        showCompletedProjects = true
    }
    
    // MARK: - Project Analytics
    func getProjectProgress(_ project: Project) -> Double {
        return project.projectProgress(from: dataService.tasks)
    }
    
    func getProjectTasks(_ project: Project) -> [Task] {
        return dataService.tasks.filter { $0.projectId == project.id }
    }
    
    func getProjectTasksCount(_ project: Project) -> Int {
        return project.tasksCount(from: dataService.tasks)
    }
    
    func getProjectCompletedTasksCount(_ project: Project) -> Int {
        return project.completedTasksCount(from: dataService.tasks)
    }
    
    func getOverdueProjects() -> [Project] {
        return projects.filter { $0.isOverdue }
    }
    
    func getUpcomingProjects(days: Int = 7) -> [Project] {
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return projects.filter { project in
            guard let dueDate = project.dueDate else { return false }
            return !project.isCompleted && dueDate >= Date() && dueDate <= endDate
        }
    }
    
    func getCompletionRate() -> Double {
        guard !projects.isEmpty else { return 0 }
        let completedProjects = projects.filter { $0.isCompleted }.count
        return Double(completedProjects) / Double(projects.count)
    }
    
    // MARK: - Project Statistics
    func getProjectStatistics(_ project: Project) -> ProjectStatistics {
        let tasks = getProjectTasks(project)
        let completedTasks = tasks.filter { $0.isCompleted }
        let overdueTasks = tasks.filter { $0.isOverdue }
        let totalEstimatedHours = tasks.compactMap { $0.estimatedHours }.reduce(0, +)
        let totalActualHours = tasks.compactMap { $0.actualHours }.reduce(0, +)
        
        return ProjectStatistics(
            totalTasks: tasks.count,
            completedTasks: completedTasks.count,
            overdueTasks: overdueTasks.count,
            progress: getProjectProgress(project),
            totalEstimatedHours: totalEstimatedHours,
            totalActualHours: totalActualHours
        )
    }
    
    func getAllProjectsStatistics() -> [ProjectStatistics] {
        return projects.map { getProjectStatistics($0) }
    }
    
    // MARK: - Bulk Operations
    func markAllProjectsAsCompleted() {
        let incompleteProjects = projects.filter { !$0.isCompleted }
        for project in incompleteProjects {
            var updatedProject = project
            updatedProject.isCompleted = true
            updateProject(updatedProject)
        }
    }
    
    func deleteCompletedProjects() {
        let completedProjects = projects.filter { $0.isCompleted }
        for project in completedProjects {
            deleteProject(project)
        }
    }
    
    // MARK: - Project Creation Helpers
    func createQuickProject(name: String, description: String = "", color: String = "#fbd600") {
        let project = Project(name: name, description: description, color: color)
        addProject(project)
    }
    
    func duplicateProject(_ project: Project) {
        var newProject = project
        newProject.name = "\(project.name) (Copy)"
        newProject.isCompleted = false
        newProject.createdDate = Date()
        addProject(newProject)
    }
    
    // MARK: - Color Management
    static let projectColors = [
        "#fbd600", "#4CAF50", "#2196F3", "#FF9800",
        "#9C27B0", "#F44336", "#795548", "#607D8B",
        "#E91E63", "#3F51B5", "#009688", "#8BC34A",
        "#FFEB3B", "#FF5722", "#9E9E9E", "#673AB7"
    ]
    
    func getRandomProjectColor() -> String {
        return Self.projectColors.randomElement() ?? "#fbd600"
    }
}

struct ProjectStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
    let progress: Double
    let totalEstimatedHours: Double
    let totalActualHours: Double
    
    var remainingTasks: Int {
        return totalTasks - completedTasks
    }
    
    var efficiencyRate: Double {
        guard totalEstimatedHours > 0 else { return 0 }
        return totalActualHours / totalEstimatedHours
    }
}
