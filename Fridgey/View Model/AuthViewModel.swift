//
//  AuthViewModel.swift
//  Fridgey
//
//  Created by Jeremy Lo on 02/06/2026.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift

class AuthViewModel: ObservableObject {
    let db = Firestore.firestore()
    
    // MARK: Basic Authentication
    func register(firstName: String, lastName: String, email: String, password: String) async -> (alertMsg: String, registered: Bool) {
        var uid: String = ""
        
        // 1. Validation Check
        if [firstName, lastName, email, password].contains(where: \.isEmpty) {
            return ("All fields are mandatory", false)
        }
        if firstName.contains(/[^a-zA-Z]/) || lastName.contains(/[^a-zA-Z]/) {
            return ("Name can only contain letters", false)
        }
        if !email.contains(/[@]/) {
            return ("Invalid Email", false)
        }
        if password.count < 6 {
            return ("Password must be at least 6 characters long", false)
        }
        if !password.contains(/[0-9]/) || !password.contains(/[^a-zA-Z0-9]/) {
            return ("Password should include numbers and special characters", false)
        }
        
        // 2. Register to FirebaseAuth
        do {
            let AuthResult = try await Auth.auth().createUser(withEmail: email, password: password)
            uid = AuthResult.user.uid
            guard !uid.isEmpty else {
                return ("Failed to create user", false)
            }
        } catch {
            return (error.localizedDescription, false)
        }
        
        // 3. Add to Firestore
        do {
            let uid = Auth.auth().currentUser!.uid
            
            let docRef = db.collection("Users").document(uid)
            try await docRef.setData(["firstName": firstName,
                                      "lastName": lastName,
                                      "email": email])
        } catch {
            return (error.localizedDescription, false)
        }
                
        return ("Registered successfully", true)
    }
    
    func SignIn(email: String, password: String) async -> (alertMsg: String, showAlert: Bool) {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            return ("", false)
            } catch {
            return (error.localizedDescription, true)
        }
    }
    
    func SignOut() async -> (alertMsg: String, showAlert: Bool) {
        do {
            try Auth.auth().signOut()
            return ("", false)
        } catch {
            return (error.localizedDescription, true)
        }
    }
    
    // MARK: OAuth SSO
    enum AuthenticationError: Error {
      case tokenError(message: String)
    }
    
    enum authenticationState {
        case authenticating
        case authenticated
    }
    
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
    
    func signInWithGoogle(credential: AuthCredential) async -> (isVerified: Bool, alertMsg: String) {
        do {
            // Pass token to Firebase
            let result = try await Auth.auth().signIn(with: credential)
            let firebaseUser = result.user
            print("User \(firebaseUser.uid) signed in wih email \(firebaseUser.email ?? "unknown")")
            return (true, "")
            
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    // MARK: Account Linking
    enum AccountLinkMode {
        case google
    }
    
    func linkWithAccount(mode: AccountLinkMode) async -> (alertMsg: String, isVerified: Bool) {
        var alertMsg = ""
        var credential: AuthCredential? = nil

        // 1. Fetch credential
        switch mode {
        case .google:
            (alertMsg, credential) = await authGoogle()
            guard credential != nil else {
                return (alertMsg, false)
            }
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
        
        // TODO: 3. Might need to handle merge account
        
        
        return ("", false)
    }
    
    // MARK: Fetch
    func fetchUID(firstName: String, email: String) async -> String {
        let docRef = db.collection("Users")
        let query = docRef.whereField("email", isEqualTo: email)
            .whereField("firstName", isEqualTo: firstName)
        do {
            let querySnapshot = try await query.getDocuments()
            for document in querySnapshot.documents {
                print("\(document.documentID) => \(document.data())")
                return document.documentID
            }
        } catch {
            print(error.localizedDescription)
        }
        return ""
    }
    
    func fetchName(userID: String) async -> (firstName: String, lastName: String) {
        var uid: String = ""
        
        if userID.isEmpty {
            uid = Auth.auth().currentUser?.uid ?? "Unknown"
        } else {
            uid = userID
        }
        
        if uid == "Unknown" {
            return ("Unknown", "Unknown")
        }
        
        do {
            let docRef = db.collection("Users").document(uid)
            let document = try await docRef.getDocument()
            if document.exists {
                let docData = document.data()!
                let firstName = docData["firstName"] as! String
                let lastName = docData["lastName"] as! String
                return (firstName, lastName)
            } else {
                return ("Unknown", "Unknown")
            }
        } catch {
            print(error.localizedDescription)
            return ("Unknown", "Unknown")
        }
    }
    
    func fetchEmail(userID: String) async -> String {
        var uid: String = ""
        
        if userID.isEmpty {
            uid = Auth.auth().currentUser?.uid ?? "Unknown"
        } else {
            uid = userID
        }
        
        if uid == "Unknown" {
            return "Unknown"
        }
        
        do {
            let docRef = db.collection("Users").document(uid)
            let document = try await docRef.getDocument()
            if document.exists {
                let docData = document.data()!
                let email = docData["email"] as! String
                return (email)
            } else {
                return ("Unknown")
            }
        } catch {
            print(error.localizedDescription)
            return ("Unknown")
        }
    }
    
    // MARK: Account Update
    func updateAccount(firstName: String, lastName: String, email: String, password: String) async -> (alertMsg: String, hadError: Bool) {
        let (storedFirstName, storedLastName) = await fetchName(userID: "")
        let storedEmail = await fetchEmail(userID: "")
        let uid = (Auth.auth().currentUser?.uid)!
        
        do {
            if firstName != storedFirstName {
                let docRef = db.collection("Users").document(uid)
                try await docRef.updateData(["firstName": firstName])
            }
            if lastName != storedLastName {
                let docRef = db.collection("Users").document(uid)
                try await docRef.updateData(["lastName": lastName])
            }
            if email != storedEmail {
                try await Auth.auth().currentUser?.sendEmailVerification(beforeUpdatingEmail: email)
            }
            if !password.isEmpty {
                try await Auth.auth().currentUser?.updatePassword(to: password)
            }
        } catch {
            return (error.localizedDescription, true)
        }
        
        if email != storedEmail {
            return ("Please check your inbox to verify your email", false)
        }
        return ("Changes Applied", false)
    }
}
