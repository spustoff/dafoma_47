//
//  TaskListView.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import SwiftUI

struct TaskListView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var projectViewModel = ProjectViewModel()
    @State private var showingAddTask = false
    @State private var showingFilters = false
    @State private var selectedTask: Task?
    @State private var showingTaskDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with search and filters
                    headerView
                    
                    // Task List
                    if taskViewModel.filteredTasks.isEmpty {
                        emptyStateView
                    } else {
                        taskListContent
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .navigationBarItems(
                trailing: Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color(hex: "#fbd600"))
                }
            )
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskViewModel: taskViewModel, projectViewModel: projectViewModel)
        }
        .sheet(isPresented: $showingFilters) {
            TaskFiltersView(taskViewModel: taskViewModel, projectViewModel: projectViewModel)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task, taskViewModel: taskViewModel, projectViewModel: projectViewModel)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search tasks...", text: $taskViewModel.searchText)
                    .foregroundColor(.white)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !taskViewModel.searchText.isEmpty {
                    Button(action: { taskViewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Filter and Sort Options
            HStack {
                Button(action: { showingFilters = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filters")
                    }
                    .font(.subheadline)
                    .foregroundColor(hasActiveFilters ? Color(hex: "#fbd600") : .white.opacity(0.7))
                }
                
                Spacer()
                
                Menu {
                    ForEach(TaskViewModel.TaskSortOption.allCases, id: \.self) { option in
                        Button(action: { taskViewModel.sortOption = option }) {
                            HStack {
                                Text(option.rawValue)
                                if taskViewModel.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: taskViewModel.sortOption.systemImage)
                        Text("Sort")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var hasActiveFilters: Bool {
        return taskViewModel.selectedPriority != nil || 
               taskViewModel.selectedProject != nil || 
               !taskViewModel.showCompletedTasks
    }
    
    private var taskListContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(taskViewModel.filteredTasks) { task in
                    TaskRowView(
                        task: task,
                        onToggleCompletion: { taskViewModel.toggleTaskCompletion(task) },
                        onTap: { selectedTask = task; showingTaskDetail = true }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Tasks Found")
                .font(.title2)
                .foregroundColor(.white)
            
            Text(taskViewModel.searchText.isEmpty ? 
                 "Create your first task to get started" : 
                 "No tasks match your search criteria")
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingAddTask = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Task")
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#fbd600"))
                )
            }
            
            Spacer()
        }
    }
}

struct TaskRowView: View {
    let task: Task
    let onToggleCompletion: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Completion Button
                Button(action: onToggleCompletion) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? Color(hex: "#4CAF50") : .white.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Task Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .strikethrough(task.isCompleted)
                            .opacity(task.isCompleted ? 0.6 : 1.0)
                        
                        Spacer()
                        
                        // Priority Badge
                        Text(task.priority.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: task.priority.color).opacity(0.2))
                            )
                            .foregroundColor(Color(hex: task.priority.color))
                    }
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    // Due Date and Tags
                    HStack {
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(dueDate, style: .date)
                                    .font(.caption)
                            }
                            .foregroundColor(task.isOverdue ? .red : .white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        if !task.tags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(task.tags.prefix(2), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "#fbd600"))
                                }
                                if task.tags.count > 2 {
                                    Text("+\(task.tags.count - 2)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddTaskView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority = Task.Priority.medium
    @State private var selectedProject: Project?
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var tags = ""
    @State private var estimatedHours = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Title")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter task title", text: $title)
                                .textFieldStyle(GlassmorphismTextFieldStyle())
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter task description", text: $description)
                                .textFieldStyle(GlassmorphismTextFieldStyle())
                        }
                        
                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(Task.Priority.allCases, id: \.self) { taskPriority in
                                    Button(action: { priority = taskPriority }) {
                                        Text(taskPriority.rawValue)
                                            .font(.subheadline)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(priority == taskPriority ? 
                                                          Color(hex: taskPriority.color) : 
                                                          Color.white.opacity(0.1))
                                            )
                                            .foregroundColor(priority == taskPriority ? .black : .white)
                                    }
                                }
                            }
                        }
                        
                        // Project Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Project")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Menu {
                                Button("No Project") {
                                    selectedProject = nil
                                }
                                
                                ForEach(projectViewModel.projects) { project in
                                    Button(project.name) {
                                        selectedProject = project
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedProject?.name ?? "Select Project")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        // Due Date
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Due Date")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $hasDueDate)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#fbd600")))
                            }
                            
                            if hasDueDate {
                                DatePicker("Select due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .colorScheme(.dark)
                            }
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter tags separated by commas", text: $tags)
                                .textFieldStyle(GlassmorphismTextFieldStyle())
                        }
                        
                        // Estimated Hours
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Estimated Hours")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter estimated hours", text: $estimatedHours)
                                .textFieldStyle(GlassmorphismTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white.opacity(0.7)),
                
                trailing: Button("Save") {
                    saveTask()
                }
                .foregroundColor(Color(hex: "#fbd600"))
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func saveTask() {
        var task = Task(
            title: title,
            description: description,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            projectId: selectedProject?.id
        )
        
        // Parse tags
        if !tags.isEmpty {
            task.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        // Parse estimated hours
        if let hours = Double(estimatedHours), hours > 0 {
            task.estimatedHours = hours
        }
        
        taskViewModel.addTask(task)
        presentationMode.wrappedValue.dismiss()
    }
}

struct TaskFiltersView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Priority Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Priority")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Button("All") {
                                taskViewModel.selectedPriority = nil
                            }
                            .buttonStyle(FilterButtonStyle(isSelected: taskViewModel.selectedPriority == nil))
                            
                            ForEach(Task.Priority.allCases, id: \.self) { priority in
                                Button(priority.rawValue) {
                                    taskViewModel.selectedPriority = priority
                                }
                                .buttonStyle(FilterButtonStyle(isSelected: taskViewModel.selectedPriority == priority))
                            }
                        }
                    }
                    
                    // Project Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Project")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button("All Projects") {
                                    taskViewModel.selectedProject = nil
                                }
                                .buttonStyle(FilterButtonStyle(isSelected: taskViewModel.selectedProject == nil))
                                
                                ForEach(projectViewModel.projects) { project in
                                    Button(project.name) {
                                        taskViewModel.selectedProject = project
                                    }
                                    .buttonStyle(FilterButtonStyle(isSelected: taskViewModel.selectedProject?.id == project.id))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Show Completed Toggle
                    HStack {
                        Text("Show Completed Tasks")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Toggle("", isOn: $taskViewModel.showCompletedTasks)
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#fbd600")))
                    }
                    
                    Spacer()
                    
                    // Clear Filters Button
                    Button("Clear All Filters") {
                        taskViewModel.clearFilters()
                    }
                    .foregroundColor(.red)
                    .padding(.bottom, 20)
                }
                .padding(20)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color(hex: "#fbd600"))
            )
        }
    }
}

struct FilterButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#fbd600") : Color.white.opacity(0.1))
            )
            .foregroundColor(isSelected ? .black : .white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct TaskDetailView: View {
    let task: Task
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Task Title and Status
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(task.title)
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: { taskViewModel.toggleTaskCompletion(task) }) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title)
                                        .foregroundColor(task.isCompleted ? Color(hex: "#4CAF50") : .white.opacity(0.6))
                                }
                            }
                            
                            // Priority Badge
                            HStack {
                                Text(task.priority.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: task.priority.color).opacity(0.2))
                                    )
                                    .foregroundColor(Color(hex: task.priority.color))
                                
                                Spacer()
                            }
                        }
                        
                        // Description
                        if !task.description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(task.description)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        // Due Date
                        if let dueDate = task.dueDate {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Due Date")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(task.isOverdue ? .red : Color(hex: "#fbd600"))
                                    
                                    Text(dueDate, style: .date)
                                        .foregroundColor(task.isOverdue ? .red : .white)
                                    
                                    Text(dueDate, style: .time)
                                        .foregroundColor(task.isOverdue ? .red : .white.opacity(0.7))
                                    
                                    if task.isOverdue {
                                        Text("(Overdue)")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        
                        // Project
                        if let projectId = task.projectId,
                           let project = projectViewModel.projects.first(where: { $0.id == projectId }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Project")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Circle()
                                        .fill(Color(hex: project.color))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(project.name)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // Tags
                        if !task.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                    ForEach(task.tags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color(hex: "#fbd600").opacity(0.2))
                                            )
                                            .foregroundColor(Color(hex: "#fbd600"))
                                    }
                                }
                            }
                        }
                        
                        // Time Tracking
                        if task.estimatedHours != nil || task.actualHours != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time Tracking")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    if let estimated = task.estimatedHours {
                                        VStack(alignment: .leading) {
                                            Text("Estimated")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                            Text("\(estimated, specifier: "%.1f")h")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    if let actual = task.actualHours {
                                        VStack(alignment: .leading) {
                                            Text("Actual")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                            Text("\(actual, specifier: "%.1f")h")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Created Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Created")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(task.createdDate, style: .date)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color(hex: "#fbd600"))
            )
        }
    }
}

#Preview {
    TaskListView()
}
