//
//  ProfileView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 05/06/2026.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var navViewModel: NavigationViewModel
    
    @State private var storedFirstName: String = ""
    @State private var storedLastName: String = ""
    @State private var storedEmail: String = ""
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMsg: String = ""
    @State private var hadError: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            // TODO: Add Avatar
            
            Text("Name")
                .padding(.top)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                TextField("First Name", text: $firstName)
                    .autocorrectionDisabled()
                    .textContentType(.givenName)
                
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isFocused)
                
                TextField("Last Name", text: $lastName)
                    .autocorrectionDisabled()
                    .textContentType(.familyName)
                
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isFocused)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            Text("Email")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
            TextField("Email", text: $email)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocapitalization(.none)
            
            
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .focused($isFocused)
            
            Text("Password")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
                .padding(.horizontal)
            SecureField("New Password", text: $password)
                .autocorrectionDisabled()
                .textContentType(.password)
                .autocapitalization(.none)
            
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom)
                .focused($isFocused)
            
            Button {
                Task {
                    (alertMsg, hadError) = await authViewModel.updateAccount(firstName: firstName, lastName: lastName, email: email, password: password)
                    
                    if hadError {
                        alertTitle = "Error"
                    } else {
                        alertTitle = "Success"
                    }
                    
                    showAlert = true
                }
            } label: {
                Text("Apply Changes")
                    .padding(10)
                    .padding(.horizontal, 13)
                    .background((firstName != storedFirstName || lastName != storedLastName || email != storedEmail || !password.isEmpty) ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.bold)
                    .cornerRadius(8)
                    .frame(width: 330)
            }
            .disabled((firstName == storedFirstName && lastName == storedLastName && email == storedEmail && password.isEmpty))
            }
        .padding()
        .onAppear() {
            Task {
                (firstName, lastName) = await authViewModel.fetchName(userID: "")
                email = await authViewModel.fetchEmail(userID: "")
                (storedFirstName, storedLastName, storedEmail) = (firstName, lastName, email)
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button ("OK") {
                if alertTitle == "Success" {
                    navViewModel.pop()
                }
            }
        } message: {
            Text(alertMsg)
        }
    }
}

#Preview {
    ProfileView()
}
