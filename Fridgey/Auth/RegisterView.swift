//
//  RegisterView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 02/06/2026.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var navViewModel: NavigationViewModel
    
    @FocusState private var isFocused: Bool
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = "Error"
    @State private var alertMsg: String = ""
    
    @State private var isRegistered: Bool = false
    
    var body: some View {
        VStack {
            Text("Register")
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                TextField("First Name: ", text: $firstName)
                    .autocorrectionDisabled()
                    .textContentType(.givenName)
                
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isFocused)
                
                TextField("Last Name: ", text: $lastName)
                    .autocorrectionDisabled()
                    .textContentType(.familyName)
                
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isFocused)
            }
            TextField("Email: ", text: $email)
                .autocorrectionDisabled()
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($isFocused)
            
            SecureField("Password", text: $password)
                .autocorrectionDisabled()
                .textContentType(.newPassword)
                .autocapitalization(.none)
            
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($isFocused)
            
            Button("Register") {
                Task {
                    (alertMsg, isRegistered) = await authViewModel.register(firstName: firstName, lastName: lastName, email: email, password: password)
                    if isRegistered == true {
                        alertTitle = "Success"
                        showAlert = true
                        navViewModel.backToRoot()
                    }
                    showAlert = true
                }
            }
            .padding()
            .padding(.horizontal, 13)
            .background(Color(.green))
            .foregroundColor(.white)
            .font(.title2)
            .fontWeight(.bold)
            .cornerRadius(8)
            .frame(width: 180)
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMsg), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    RegisterView()
}
