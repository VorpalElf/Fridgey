//
//  ProfileView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 05/06/2026.
//

import SwiftUI
import Firebase
import FirebaseAuth

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
    
    @State private var showSignOutButton: Bool = false
    @State private var showSignWarning: Bool = false
    @State private var emailChanged: Bool = false
    
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
                    let storedEmail = await authViewModel.fetchEmail(userID: "")
                    let user = Auth.auth().currentUser
                    if storedEmail != email {
                        let hasPassword = user?.providerData.contains { userInfo in
                            return userInfo.providerID == "password"
                        } ?? false
                        if !hasPassword {
                            alertMsg = "Email cannot be changed without a email-password account. Please link your email-password account and try again."
                            showAlert = true
                            return
                        }
                        alertMsg = "For safety reasons, your Google account will be disconnected. Are you sure to proceed?"
                        showSignWarning = true
                    } else {
                        await performAccountUpdate()
                    }
                }
            } label: {
                Text("Apply Changes")
                    .padding(10)
                    .padding(.horizontal, 13)
                    .background((firstName == storedFirstName && lastName == storedLastName && email == storedEmail && password.isEmpty) ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.bold)
                    .cornerRadius(8)
                    .frame(width: 330)
            }
            
            Button {
                Task {
                    alertMsg = await OAuthService.shared.linkWithEmail(email: email, password: password)
                    if alertMsg == "Email-password linked successfully!" {
                        alertTitle = "Success"
                    } else {
                        alertTitle = "Error"
                    }
                    showAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "lock.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                    Text("Link to Email-Password")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled((email == storedEmail && password.isEmpty))
        }
        .padding()
        .onAppear() {
            Task {
                (firstName, lastName) = await authViewModel.fetchName(userID: "")
                email = await authViewModel.fetchEmail(userID: "")
                (storedFirstName, storedLastName, storedEmail) = (firstName, lastName, email)
            }
        }
        .navigationBarBackButtonHidden(showSignOutButton)
        .alert(alertTitle, isPresented: $showAlert) {
            Button ("OK") {
                if alertTitle == "Success" && !showSignOutButton {
                    navViewModel.pop()
                }
            }
        } message: {
            Text(alertMsg)
        }
        .alert("Warning", isPresented: $showSignWarning) {
            Button("Yes", role: .destructive) {
                Task {
                    alertMsg = await OAuthService.shared.unLinkAccount(mode: .google)
                    try? await Task.sleep(for: .seconds(0.5))
                    print(alertMsg)
                    if alertMsg != "" && alertMsg != "User was not linked to an account with the given provider." {
                        alertTitle = "Error"
                        showAlert = true
                    } else {
                        await performAccountUpdate()
                    }
                }
            }
            Button("No", role: .cancel) {
                
            }
        } message: {
            Text(alertMsg)
        }
        .toolbar {
            if showSignOutButton {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        Task {
                            (alertMsg, showAlert) = await authViewModel.SignOut()
                            if !showAlert {
                                navViewModel.backToRoot()
                            }
                        }
                    }
                    .foregroundStyle(Color(.red))
                }
            }
        }
    }
    private func performAccountUpdate() async {
        (alertMsg, hadError) = await authViewModel.updateAccount(firstName: firstName, lastName: lastName, email: email, password: password)
        
        if hadError {
            alertTitle = "Error"
        } else {
            if storedEmail != email{
                showSignOutButton = true
                emailChanged = true
            }
            alertTitle = "Success"
        }
        showAlert = true
    }
}

#Preview {
    ProfileView()
}
