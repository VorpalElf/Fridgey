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

class AuthViewModel: ObservableObject {
    let db = Firestore.firestore()
    
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
}
