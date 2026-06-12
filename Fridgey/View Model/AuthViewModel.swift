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
import Supabase

class AuthViewModel: ObservableObject {
    private let oAuthService = OAuthService.shared
    let db = Firestore.firestore()
    
    // MARK: Supabase Structs
    struct Profile: Codable {
        let userID: String
        let firstName: String
        let lastName: String
        let email: String
    }
    
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
            
            // 3. Add to Firestore
            let user = AuthResult.user
            let token = try await user.getIDToken(forcingRefresh: true)
            /* let docRef = db.collection("Users").document(uid)
            try await docRef.setData(["firstName": firstName,
                                      "lastName": lastName,
                                      "email": email]) */
            try await SupaManager.shared.supabase
                .from("users")
                .insert(Profile(userID: uid, firstName: firstName, lastName: lastName, email: email))
                .execute()
                .value
            
        } catch {
            return (error.localizedDescription, false)
        }
        return ("Registered successfully", true)
    }
    
    // Sign In on Firebase
    func SignIn(email: String, password: String) async -> (alertMsg: String, showAlert: Bool) {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)      // Sign In function for Firebase
            let user = authResult.user
            let token = try await user.getIDToken(forcingRefresh: true)
            let email = user.email
            let uid = user.uid
            
            try await SupaManager.shared.supabase
                .from("users")
                .update(["email": email])
                .eq("userID", value: uid)
                .execute()
            
            return ("", false)
            } catch {
            return (error.localizedDescription, true)
        }
    }
    
    // Sign Out on Firebase
    func SignOut() async -> (alertMsg: String, showAlert: Bool) {
        do {
            try Auth.auth().signOut()
            return ("", false)
        } catch {
            return (error.localizedDescription, true)
        }
    }
    
    // MARK: Fetch
    // Fetch UID based on name
    func fetchUID(firstName: String, email: String) async -> String {
        /*
        let docRef = db.collection("Users")
        let query = docRef.whereField("email", isEqualTo: email)
            .whereField("firstName", isEqualTo: firstName) */
        
        do {
            let result = try await SupaManager.shared.supabase
                .from("users")
                .select("userID")
                .eq("firstName", value: firstName)
                .execute()
            /*
            let querySnapshot = try await query.getDocuments()
            for document in querySnapshot.documents {
                print("\(document.documentID) => \(document.data())")
                return document.documentID
            } */
        } catch {
            print(error.localizedDescription)
        }
        return ""
    }
    
    // Fetch name based on UID
    func fetchName(userID: String) async -> (firstName: String, lastName: String) {
        var uid: String = ""
        
        // If no UID given, assume current user
        if userID.isEmpty {
            uid = Auth.auth().currentUser?.uid ?? "Unknown"
        } else {
            uid = userID
        }
        
        if uid == "Unknown" {
            return ("Unknown", "Unknown")
        }
        
        do {
            /*
            let docRef = db.collection("Users").document(uid)
            let document = try await docRef.getDocument()
            if document.exists {
                let docData = document.data()!
                let firstName = docData["firstName"] as! String
                let lastName = docData["lastName"] as! String
                return (firstName, lastName)
            } else {
                return ("Unknown", "Unknown")
            } */
            
            let SupaResponse: [Profile] = try await SupaManager.shared.supabase
                .from("users")
                .select("userID, firstName, lastName, email")
                .eq("userID", value: uid)
                .execute()
                .value
            
            if SupaResponse.isEmpty {
                return ("Unknown", "Unknown")
            } else {
                let matchedProfile = SupaResponse.first
                let firstName = matchedProfile!.firstName
                let lastName = matchedProfile!.lastName
                return (firstName, lastName)
            }
        } catch {
            print(error.localizedDescription)
            return ("Unknown", "Unknown")
        }
    }
    
    func fetchEmail(userID: String) async -> String {
        var uid: String = ""
        
        // If no UID given, assume current user
        if userID.isEmpty {
            uid = Auth.auth().currentUser?.uid ?? "Unknown"
        } else {
            uid = userID
        }
        
        if uid == "Unknown" {
            return "Unknown"
        }
        
        do {
            /*
            let docRef = db.collection("Users").document(uid)
            let document = try await docRef.getDocument()
            if document.exists {
                let docData = document.data()!
                let email = docData["email"] as! String
                return (email)
            } else {
                return ("Unknown")
            } */
            
            let SupaResponse: [Profile] = try await SupaManager.shared.supabase
                .from("users")
                .select("userID, firstName, lastName, email")
                .eq("userID", value: uid)
                .execute()
                .value
            
            if SupaResponse.isEmpty {
                return ("Unknown")
            } else {
                let matchedProfile = SupaResponse.first
                let email = matchedProfile!.email
                return (email)
            }
        } catch {
            print(error.localizedDescription)
            return ("Unknown")
        }
    }
    
    // MARK: Account Update
    // Function to allow user reset their password
    func forgotPassword(email: String) async -> (hadError: Bool, alertMsg: String) {
        guard email.contains("@") else {
            return (true, "Invalid email. Please try again.")
        }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            return (false, "If you've been registered using this address, an email has been sent. Please check your inbox or spam.")
        } catch {
            return (true, error.localizedDescription)
        }
    }
    
    func updateAccount(firstName: String, lastName: String, email: String, password: String) async -> (alertMsg: String, hadError: Bool) {
        let (storedFirstName, storedLastName) = await fetchName(userID: "")
        let storedEmail = await fetchEmail(userID: "")
        let uid = (Auth.auth().currentUser?.uid)!
        
        do {
            var updates: [String: String] = [:]
            
            if firstName != storedFirstName {
                updates["firstName"] = firstName
            }
            if lastName != storedLastName {
                updates["lastName"] = lastName
            }
            
            if !updates.isEmpty {
                /* try await db.collection("Users").document(uid).updateData(updates) */
                try await SupaManager.shared.supabase
                    .from("users")
                    .update(updates)
                    .eq("userID", value: uid)
                    .execute()
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
            return ("An verification email has been sent. Please check your inbox or spam. If you would like to revert, sign in again using your original email.", false)
        }
        return ("Changes Applied", false)
    }
}
