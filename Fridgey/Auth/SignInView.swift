//
//  SignInView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 02/06/2026.
//

import SwiftUI

struct SignInView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var navViewModel: NavigationViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @FocusState private var isFocused: Bool
    @State private var isVerified: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMsg: String = ""
    
    var body: some View {
        VStack {
            Text("Sign In")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            TextField("Email: ", text: $email)
                .autocorrectionDisabled()
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($isFocused)
            
            SecureField("Password", text: $password)
                .autocorrectionDisabled()
                .textContentType(.password)
                .autocapitalization(.none)
            
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($isFocused)
            
            Button("Sign In") {
                Task {
                    (alertMsg, showAlert) = await authViewModel.SignIn(email: email, password: password)
                    if showAlert == false {
                        navViewModel.navigate(to: .home)
                    }
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
            Alert(title: Text("Error"), message: Text(alertMsg), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    SignInView()
}
