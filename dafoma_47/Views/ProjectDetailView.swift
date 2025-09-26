//
//  ProjectDetailView.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @ObservedObject var projectViewModel: ProjectViewModel
    @StateObject private var taskViewModel = TaskViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddTask = false
    @State private var showingEditProject = false
    @State private var selectedTask: Task?
    @State private var showingTaskDetail = false
    
    private var projectTasks: [Task] {
        taskViewModel.tasks.filter { $0.projectId == project.id }
    }
    
    private var completedTasks: [Task] {
        projectTasks.filter { $0.isCompleted }
    }
    
    private var pendingTasks: [Task] {
        projectTasks.filter { !$0.isCompleted }
    }
    
    private var progress: Double {
        guard !projectTasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(projectTasks.count)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Project Header
                        projectHeaderView
                        
                        // Progress Section
                        progressSectionView
                        
                        // Quick Stats
                        quickStatsView
                        
                        // Tasks Section
                        tasksSectionView
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white.opacity(0.7)),
                
                trailing: Menu {
                    Button(action: { showingEditProject = true }) {
                        Label("Edit Project", systemImage: "pencil")
                    }
                    
                    Button(action: { showingAddTask = true }) {
                        Label("Add Task", systemImage: "plus")
                    }
                    
                    Button(action: toggleProjectCompletion) {
                        Label(project.isCompleted ? "Mark as Incomplete" : "Mark as Complete", 
                              systemImage: project.isCompleted ? "circle" : "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color(hex: "#fbd600"))
                }
            )
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskViewModel: taskViewModel, projectViewModel: projectViewModel)
        }
        .sheet(isPresented: $showingEditProject) {
            EditProjectView(project: project, projectViewModel: projectViewModel)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task, taskViewModel: taskViewModel, projectViewModel: projectViewModel)
        }
    }
    
    private var projectHeaderView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Project Color Indicator
                Circle()
                    .fill(Color(hex: project.color))
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.largeTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    
                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Completion Status
                Image(systemName: project.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(project.isCompleted ? Color(hex: "#4CAF50") : .white.opacity(0.6))
            }
            
            // Due Date
            if let dueDate = project.dueDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(project.isOverdue ? .red : Color(hex: "#fbd600"))
                    
                    Text("Due: ")
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(dueDate, style: .date)
                        .foregroundColor(project.isOverdue ? .red : .white)
                    
                    if project.isOverdue && !project.isCompleted {
                        Text("(Overdue)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .font(.subheadline)
            }
            
            // Tags
            if !project.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(project.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(hex: project.color).opacity(0.2))
                                )
                                .foregroundColor(Color(hex: project.color))
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var progressSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Progress Bar
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.title2)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "#fbd600"))
                    
                    Spacer()
                    
                    Text("\(completedTasks.count) of \(projectTasks.count) tasks")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: project.color))
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var quickStatsView: some View {
        HStack(spacing: 16) {
            StatCardView(
                title: "Total Tasks",
                value: "\(projectTasks.count)",
                icon: "list.bullet",
                color: Color(hex: "#2196F3")
            )
            
            StatCardView(
                title: "Completed",
                value: "\(completedTasks.count)",
                icon: "checkmark.circle.fill",
                color: Color(hex: "#4CAF50")
            )
            
            StatCardView(
                title: "Pending",
                value: "\(pendingTasks.count)",
                icon: "clock.fill",
                color: Color(hex: "#FF9800")
            )
        }
    }
    
    private var tasksSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showingAddTask = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Task")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#fbd600"))
                }
            }
            
            if projectTasks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No tasks yet")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Add your first task to get started")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showingAddTask = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Task")
                        }
                        .foregroundColor(.black)
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#fbd600"))
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(projectTasks.sorted(by: { !$0.isCompleted && $1.isCompleted })) { task in
                        ProjectTaskRowView(
                            task: task,
                            onToggleCompletion: { taskViewModel.toggleTaskCompletion(task) },
                            onTap: { selectedTask = task; showingTaskDetail = true }
                        )
                    }
                }
            }
        }
    }
    
    private func toggleProjectCompletion() {
        projectViewModel.toggleProjectCompletion(project)
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ProjectTaskRowView: View {
    let task: Task
    let onToggleCompletion: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion Button
                Button(action: onToggleCompletion) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(task.isCompleted ? Color(hex: "#4CAF50") : .white.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Task Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(task.title)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .strikethrough(task.isCompleted)
                            .opacity(task.isCompleted ? 0.6 : 1.0)
                        
                        Spacer()
                        
                        // Priority Indicator
                        Circle()
                            .fill(Color(hex: task.priority.color))
                            .frame(width: 8, height: 8)
                    }
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dueDate, style: .date)
                                .font(.caption)
                        }
                        .foregroundColor(task.isOverdue ? .red : .white.opacity(0.6))
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditProjectView: View {
    let project: Project
    @ObservedObject var projectViewModel: ProjectViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var description: String
    @State private var selectedColor: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var tags: String
    
    init(project: Project, projectViewModel: ProjectViewModel) {
        self.project = project
        self.projectViewModel = projectViewModel
        
        _name = State(initialValue: project.name)
        _description = State(initialValue: project.description)
        _selectedColor = State(initialValue: project.color)
        _dueDate = State(initialValue: project.dueDate ?? Date())
        _hasDueDate = State(initialValue: project.dueDate != nil)
        _tags = State(initialValue: project.tags.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Project Name")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter project name", text: $name)
                                .textFieldStyle(GlassmorphismTextFieldStyle())
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter project description", text: $description)
                                .textFieldStyle(GlassmorphismTextFieldStyle())
                        }
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                                ForEach(ProjectViewModel.projectColors, id: \.self) { color in
                                    Button(action: { selectedColor = color }) {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                            )
                                    }
                                }
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
                                DatePicker("Select due date", selection: $dueDate, displayedComponents: [.date])
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
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white.opacity(0.7)),
                
                trailing: Button("Save") {
                    saveProject()
                }
                .foregroundColor(Color(hex: "#fbd600"))
                .font(.system(size: 17, weight: .semibold))
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveProject() {
        var updatedProject = project
        updatedProject.name = name
        updatedProject.description = description
        updatedProject.color = selectedColor
        updatedProject.dueDate = hasDueDate ? dueDate : nil
        
        // Parse tags
        if !tags.isEmpty {
            updatedProject.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            updatedProject.tags = []
        }
        
        projectViewModel.updateProject(updatedProject)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    ProjectDetailView(
        project: Project.sampleProjects[0],
        projectViewModel: ProjectViewModel()
    )
}
