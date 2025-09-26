//
//  UserAuthenticationService.swift
//  TaskSphere Land
//
//  Created by Вячеслав on 9/26/25.
//

import Foundation
import LocalAuthentication

class UserAuthenticationService: ObservableObject {
    static let shared = UserAuthenticationService()
    
    @Published var isAuthenticated = false
    @Published var authenticationError: String?
    
    private let context = LAContext()
    
    private init() {}
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error?.localizedDescription ?? "Biometric authentication not available")
            return
        }
        
        let reason = "Authenticate to access TaskSphere"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthenticated = true
                    self?.authenticationError = nil
                    completion(true, nil)
                } else {
                    let errorMessage = authenticationError?.localizedDescription ?? "Authentication failed"
                    self?.authenticationError = errorMessage
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    // MARK: - Passcode Authentication
    func authenticateWithPasscode(completion: @escaping (Bool, String?) -> Void) {
        var error: NSError?
        
        // Check if device passcode is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(false, error?.localizedDescription ?? "Device passcode not available")
            return
        }
        
        let reason = "Authenticate to access TaskSphere"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthenticated = true
                    self?.authenticationError = nil
                    completion(true, nil)
                } else {
                    let errorMessage = authenticationError?.localizedDescription ?? "Authentication failed"
                    self?.authenticationError = errorMessage
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    // MARK: - Authentication Status
    func checkBiometricAvailability() -> BiometricType {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    func isBiometricAuthenticationAvailable() -> Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    func isPasscodeAuthenticationAvailable() -> Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
    
    // MARK: - Session Management
    func signOut() {
        isAuthenticated = false
        authenticationError = nil
    }
    
    func signIn() {
        isAuthenticated = true
        authenticationError = nil
    }
    
    // MARK: - User Registration/Login Simulation
    func registerUser(name: String, email: String, completion: @escaping (Bool, String?) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Basic validation
            guard !name.isEmpty else {
                completion(false, "Name cannot be empty")
                return
            }
            
            guard self.isValidEmail(email) else {
                completion(false, "Please enter a valid email address")
                return
            }
            
            // Create user profile
            DataStorageService.shared.createUserProfile(name: name, email: email)
            self.isAuthenticated = true
            completion(true, nil)
        }
    }
    
    func loginUser(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Basic validation
            guard self.isValidEmail(email) else {
                completion(false, "Please enter a valid email address")
                return
            }
            
            guard !password.isEmpty else {
                completion(false, "Password cannot be empty")
                return
            }
            
            // Simulate successful login (in real app, this would validate against server)
            self.isAuthenticated = true
            completion(true, nil)
        }
    }
    
    // MARK: - Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID
    
    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }
    
    var iconName: String {
        switch self {
        case .none:
            return "lock"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .opticID:
            return "opticid"
        }
    }
}
