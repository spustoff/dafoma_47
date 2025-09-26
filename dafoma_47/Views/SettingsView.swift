//
//  SettingsView.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = UserSettingsViewModel()
    @StateObject private var authService = UserAuthenticationService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingImagePicker = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSignOutConfirmation = false
    @State private var showingExportSheet = false
    @State private var exportedData = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        
                        // Notifications Section
                        notificationsSectionView
                        
                        // App Settings Section
                        appSettingsSectionView
                        
                        // Data Management Section
                        dataManagementSectionView
                        
                        // Account Section
                        accountSectionView
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { imageData in
                settingsViewModel.updateProfileImage(imageData)
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ShareSheet(activityItems: [exportedData])
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                settingsViewModel.deleteAccount()
            }
        } message: {
            Text("This will permanently delete all your data. This action cannot be undone.")
        }
        .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                settingsViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private var profileSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // Profile Image
                HStack {
                    Button(action: { showingImagePicker = true }) {
                        Group {
                            if let imageData = settingsViewModel.userSettings.profileImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    
                    Spacer()
                    
                }
                
                // User Stats
                if let profile = settingsViewModel.userProfile {
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(profile.tasksCompleted)")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#fbd600"))
                            Text("Tasks")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack {
                            Text("\(profile.projectsCompleted)")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#4CAF50"))
                            Text("Projects")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack {
                            Text("Level \(profile.level)")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#2196F3"))
                            Text("Experience")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack {
                            Text("\(profile.streak)")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#FF9800"))
                            Text("Day Streak")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.top, 8)
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
    
    private var notificationsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                
                if settingsViewModel.userSettings.notificationsEnabled {
                    SettingsRowView(
                        title: "Reminder Time",
                        subtitle: settingsViewModel.userSettings.reminderDisplayText(),
                        icon: "clock.fill",
                        content: {
                            Menu {
                                ForEach(UserSettings.reminderOptions, id: \.0) { option in
                                    Button(option.1) {
                                        settingsViewModel.updateReminderTime(option.0)
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    )
                    
                    SettingsRowView(
                        title: "Sound",
                        icon: "speaker.wave.2.fill",
                        content: {
                            Toggle("", isOn: Binding(
                                get: { settingsViewModel.userSettings.soundEnabled },
                                set: { _ in settingsViewModel.toggleSound() }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#fbd600")))
                        }
                    )
                    
                    SettingsRowView(
                        title: "Vibration",
                        icon: "iphone.radiowaves.left.and.right",
                        content: {
                            Toggle("", isOn: Binding(
                                get: { settingsViewModel.userSettings.vibrationEnabled },
                                set: { _ in settingsViewModel.toggleVibration() }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#fbd600")))
                        }
                    )
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
    
    private var appSettingsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Settings")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                SettingsRowView(
                    title: "Theme",
                    subtitle: settingsViewModel.userSettings.theme.displayName,
                    icon: "paintbrush.fill",
                    content: {
                        Menu {
                            ForEach(UserSettings.AppTheme.allCases, id: \.self) { theme in
                                Button(theme.displayName) {
                                    settingsViewModel.updateTheme(theme)
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                )
                
                SettingsRowView(
                    title: "Default Project Color",
                    icon: "paintpalette.fill",
                    content: {
                        Circle()
                            .fill(Color(hex: settingsViewModel.userSettings.defaultProjectColor))
                            .frame(width: 24, height: 24)
                    }
                )
                
                SettingsRowView(
                    title: "Analytics",
                    subtitle: "Help improve the app",
                    icon: "chart.bar.fill",
                    content: {
                        Toggle("", isOn: Binding(
                            get: { settingsViewModel.userSettings.analyticsEnabled },
                            set: { _ in settingsViewModel.toggleAnalytics() }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#fbd600")))
                    }
                )
                
                SettingsRowView(
                    title: "Auto Sync",
                    subtitle: "Automatically sync data",
                    icon: "arrow.triangle.2.circlepath",
                    content: {
                        Toggle("", isOn: Binding(
                            get: { settingsViewModel.userSettings.autoSyncEnabled },
                            set: { _ in settingsViewModel.toggleAutoSync() }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#fbd600")))
                    }
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
    
    private var dataManagementSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Management")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                
                SettingsRowView(
                    title: "Reset Onboarding",
                    subtitle: "Show onboarding again",
                    icon: "arrow.clockwise",
                    action: {
                        hasCompletedOnboarding = false
                    }
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
    
    private var accountSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                SettingsRowView(
                    title: "Sign Out",
                    icon: "rectangle.portrait.and.arrow.right",
                    titleColor: .orange,
                    action: {
                        showingSignOutConfirmation = true
                    }
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

struct SettingsRowView<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let titleColor: Color
    let action: (() -> Void)?
    let content: () -> Content
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        titleColor: Color = .white,
        action: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.titleColor = titleColor
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color(hex: "#fbd600"))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(titleColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                content()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (Data?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(image.jpegData(compressionQuality: 0.8))
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
