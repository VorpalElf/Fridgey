//
//  OAuthService.swift
//  Fridgey
//
//  Created by Jeremy Lo on 06/06/2026.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift

class OAuthService: ObservableObject {
    static let shared = OAuthService()
    let db = Firestore.firestore()
    
    // MARK: OAuth SSO
    // Used for authGoogle
    enum AuthenticationError: Error {
      case tokenError(message: String)
    }
    
    enum authenticationState {
        case authenticating
        case authenticated
    }
    
    // Fetch auth credentials from Google
    func authGoogle() async -> (alertMsg: String, AuthCredential?) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("No client ID found in Firebase Configuration")
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Show Google SSO Window
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = await windowScene.windows.first,
              let rootViewController = await window.rootViewController else {
            return ("There is no root view controller", nil)
        }
        
        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn( withPresenting: rootViewController)
            
            // Invoke ID Token
            let user = userAuthentication.user
            guard let idToken = user.idToken else {
                throw AuthenticationError.tokenError(message: "ID token missing")
            }
            let accessToken = user.accessToken
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
            return ("", credential)
        } catch {
            return (error.localizedDescription, nil)
        }
    }
    
    // Sign in to Firebase with any OAuth Credentials
    func signInWithOAuth(credential: AuthCredential) async -> (isVerified: Bool, alertMsg: String) {

        do {
            // Pass token to Firebase
            let result = try await Auth.auth().signIn(with: credential)
            let firebaseUser = result.user
            print("User \(firebaseUser.uid) signed in wih email \(firebaseUser.email ?? "unknown")")
            
            // Send token to Supabase
            let tokenString = try await firebaseUser.getIDToken(forcingRefresh: true)
            guard !tokenString.isEmpty else {
                return (false, "Authentication token could not be generated.")
            }
            
            // Fetch name
            let fullName = firebaseUser.displayName ?? "User"
            var firstName: String = ""
            var lastName: String = ""
            
            if let profileData = result.additionalUserInfo?.profile {
                        firstName = profileData["given_name"] as? String ?? profileData["first_name"] as? String ?? ""
                        lastName = profileData["family_name"] as? String ?? profileData["last_name"] as? String ?? ""
                    }
            
            if firstName.isEmpty && lastName.isEmpty {
                let fullName = firebaseUser.displayName ?? "User"
                let nameComponents = fullName.split(separator: " ")
                
                if nameComponents.count > 1 {
                    // Convert Substring to String and handle potential nil with ??
                    firstName = String(nameComponents.first ?? "")
                    lastName = String(nameComponents.last ?? "")
                } else {
                    firstName = fullName
                    lastName = ""
                }
            }
            
            // Upload name
            let email = Auth.auth().currentUser?.email ?? "no-email@fridgey.com"
            let uid = Auth.auth().currentUser!.uid
            try await SupaManager.shared.supabase
                .from("users")
                .upsert(AuthViewModel.Profile(userID: uid, firstName: firstName, lastName: lastName, email: email))
                .execute()
            /*
            let docRef = db.collection("Users").document(Auth.auth().currentUser!.uid)
            try await docRef.setData(["firstName": firstName,
                                      "lastName": lastName,
                                      "email": email!])
            */
            return (true, "")
            
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    // Fetch auth credentials from GitHub
    func authGitHub() async -> (alertMsg: String, credential: AuthCredential?) {
        let provider = OAuthProvider(providerID: "github.com")
        
        do {
            // Modern Firebase natively supports async/await here
            let credential = try await provider.credential(with: nil)
            return ("", credential)
        } catch {
            return (error.localizedDescription, nil)
        }
    }
    
    // MARK: Account Linking
    enum AccountLinkMode {
        case google
        case github
    }
    
    // Function to link account with other authentication methods
    func linkWithAccount(mode: AccountLinkMode) async -> (alertMsg: String, isVerified: Bool) {
        var alertMsg = ""
        var credential: AuthCredential? = nil

        // 1. Fetch credential
        switch mode {
        case .google:
            (alertMsg, credential) = await authGoogle()
        case .github:
            (alertMsg, credential) = await authGitHub()
        }
        guard credential != nil else {
            return (alertMsg, false)
        }
        
        // 2. Pass Credential
        let user = Auth.auth().currentUser
        do {
            if let user {
                let result = try await user.link(with: credential!)
                return ("", true)
            }
        } catch {
            return (error.localizedDescription, false)
        }
        return ("", false)
    }

    // Function to unlink OAuth methods
    func unLinkAccount(mode: AccountLinkMode) async -> String {
        do {
            switch mode {
            case .google:
                try await Auth.auth().currentUser?.unlink(fromProvider: "google.com")
            case .github:
                try await Auth.auth().currentUser?.unlink(fromProvider: "github.com")
            }
            return ""
        } catch {
            return error.localizedDescription
        }
    }
    
    func linkWithEmail(email: String, password: String) async -> String {
        let user = Auth.auth().currentUser
        let hasPassword = user!.providerData.contains { userInfo in
            return userInfo.providerID == "password"
        }
        if hasPassword {
            return ("You already have an email-password account.")
        }
        
        // Validation Check
        if password.count < 6 {
            return ("Password must be at least 6 characters long")
        }
        if !password.contains(/[0-9]/) || !password.contains(/[^a-zA-Z0-9]/) {
            return ("Password should include numbers and special characters")
        }
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await user!.link(with: credential)
            return ("Email-password linked successfully!")
        } catch {
            return (error.localizedDescription)
        }
    }
}
