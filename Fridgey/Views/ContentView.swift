//
//  ContentView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 02/06/2026.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ContentView: View {
    @StateObject private var navViewModel = NavigationViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    
    @State private var email: String = ""
    @State private var password: String = ""
    @FocusState private var isFocused: Bool
    @State private var credential: AuthCredential?
    @State private var isVerified: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMsg: String = ""
    
    var body: some View {
        NavigationStack(path: $navViewModel.path){
            VStack {
                Text("Sign In")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                    .frame(alignment: .leading)
                
                HStack {
                    Image(systemName: "envelope")
                        .frame(width: 30)
                    
                    TextField("Email: ", text: $email)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                        .frame(height: 20)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isFocused)
                }
                
                HStack {
                    Image(systemName: "lock")
                        .frame(width: 30)
                    
                    SecureField("Password", text: $password)
                        .autocorrectionDisabled()
                        .textContentType(.password)
                        .autocapitalization(.none)
                    
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isFocused)
                }
                
                // TODO: Forgot Password
                Button("Forgot Password") {
                    
                }
                .padding(.top)
                .padding(.horizontal)
                .foregroundStyle(.indigo)
                
                Button {
                    Task {
                        (alertMsg, showAlert) = await authViewModel.SignIn(email: email, password: password)
                        if showAlert == false {
                            navViewModel.navigate(to: .home)
                        }
                    }
                } label: {
                    Text("Sign In")
                        .padding(10)
                        .padding(.horizontal, 13)
                        .background(email.isEmpty || password.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .font(.title2)
                        .fontWeight(.bold)
                        .cornerRadius(8)
                        .frame(width: 330)
                }
                .padding(.top, 5)
                .disabled(email.isEmpty || password.isEmpty)
                .frame(width: 230)
                
                HStack {
                    VStack { Divider() }
                    Text("or")
                    VStack { Divider() }
                }
                
                HStack {
                    Text("Dont have an account yet?")
                    Button("Sign Up"){
                        navViewModel.navigate(to: .register)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                }
                
                Button {
                    Task {
                        (alertMsg, credential) = await authViewModel.authGoogle()
                        if credential == nil {
                            showAlert = true
                            return
                        }
                        
                        (isVerified, alertMsg) = await authViewModel.signInWithGoogle(credential: credential!)
                        if isVerified == false {
                            showAlert = true
                        } else {
                            navViewModel.navigate(to: .home)
                        }
                    }
                } label: {
                    HStack {
                        Image("google_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 32)
                        
                        Text("Sign in with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding()
            
            // MARK: Navigation Destination
            .navigationDestination (for: AppRoute.self) {
                route in switch route {
                case .register:
                    RegisterView()
                case .home:
                    HomeView()
                case .settings:
                    SettingsView()
                case .profile:
                    ProfileView()
                case .integration:
                    IntegrationView()
                }
            }
        }
        .environmentObject(navViewModel)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMsg), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    ContentView()
}
