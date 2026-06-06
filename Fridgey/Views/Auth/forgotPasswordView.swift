//
//  forgotPasswordView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 06/06/2026.
//

import SwiftUI

struct forgotPasswordView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var navViewModel: NavigationViewModel
    
    @State private var email: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMsg: String = ""
    @State private var alertTitle: String = ""
    @State private var hadError: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            Text("Forgot Password")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Email", text: $email)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
            
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 24)
                .focused($isFocused)
            
            Button("Submit") {
                Task {
                    (hadError, alertMsg) = await authViewModel.forgotPassword(email: email)
                    if hadError {
                        alertTitle = "Error"
                    } else {
                        alertTitle = "Success"
                    }
                    showAlert = true
                }
            }
            .padding()
            .padding(.horizontal, 13)
            .background(email.isEmpty ? Color.gray: Color.yellow)
            .foregroundColor(.white)
            .font(.title2)
            .fontWeight(.bold)
            .cornerRadius(8)
            .frame(width: 180)
            .disabled(email.isEmpty)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if alertTitle == "Success" {
                    navViewModel.backToRoot()
                }
            }
        } message: {
            Text(alertMsg)
        }
    }
}

#Preview {
    forgotPasswordView()
}
