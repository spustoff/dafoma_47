//
//  OnboardingView.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Welcome to TaskSphere",
            subtitle: "Your Ultimate Task Management Solution",
            description: "Organize your tasks and projects with our innovative glassmorphism design and powerful features.",
            imageName: "checkmark.circle.fill",
            color: Color(hex: "#fbd600")
        ),
        OnboardingPage(
            title: "Collaborate Seamlessly",
            subtitle: "Work Together, Achieve More",
            description: "Share tasks with team members, assign responsibilities, and track progress in real-time.",
            imageName: "person.2.fill",
            color: Color(hex: "#4CAF50")
        ),
        OnboardingPage(
            title: "Smart Analytics",
            subtitle: "Insights That Drive Productivity",
            description: "Get detailed analytics on your productivity patterns and optimize your workflow.",
            imageName: "chart.bar.fill",
            color: Color(hex: "#2196F3")
        ),
        OnboardingPage(
            title: "Never Miss a Deadline",
            subtitle: "Custom Notifications & Reminders",
            description: "Set personalized reminders and get notified about important deadlines and milestones.",
            imageName: "bell.fill",
            color: Color(hex: "#FF9800")
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            onboardingPagesView
        }
    }
    
    private var onboardingPagesView: some View {
        VStack(spacing: 0) {
            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    OnboardingPageView(page: onboardingPages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Bottom Section
            VStack(spacing: 20) {
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color(hex: "#fbd600") : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 10)
                
                // Navigation Buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    if currentPage < onboardingPages.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(Color(hex: "#fbd600"))
                        .font(.system(size: 17))
                    } else {
                        Button("Get Started") {
                            completeOnboarding()
                        }
                        .foregroundColor(.black)
                        .font(.system(size: 17))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(hex: "#fbd600"))
                        )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.color)
                .shadow(color: page.color.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title2)
                    .foregroundColor(Color(hex: "#fbd600"))
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
}

struct GlassmorphismTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
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
            .foregroundColor(.white)
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingView()
}
