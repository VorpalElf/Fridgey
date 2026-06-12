//
//  IntegrationView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 05/06/2026.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct IntegrationView: View {
    @StateObject private var oAuthService = OAuthService()
    @EnvironmentObject var navViewModel: NavigationViewModel
    
    @State private var linkedGoogle: Bool = false
    @State private var linkedGitHub: Bool = false
    
    // Used to notify users with error
    @State private var alertTitle: String = ""
    @State private var alertMsg: String = ""
    @State private var showAlert: Bool = false
    @State private var isVerified: Bool = false
    
    // Unlink Warning
    @State private var showGoogleWarning: Bool = false
    @State private var showGitHubWarning: Bool = false
    
    // Light or Dark Mode
    @Environment(\.colorScheme) var colourScheme
    
    var body: some View {
        VStack {
            Button {
                Task {
                    if linkedGoogle == false {
                        (alertMsg, isVerified) = await oAuthService.linkWithAccount(mode: .google)
                        if isVerified == true {
                            alertTitle = "Success"
                            alertMsg = "Your Google Account has been linked"
                            linkedGoogle = true
                        } else {
                            alertTitle = "Error"
                        }
                        showAlert = true
                    } else {
                        alertMsg = "Are you sure to unlink with Google?"
                        showGoogleWarning = true
                    }
                }
            } label: {
                HStack {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                    
                    Text(linkedGoogle ? "Unlink with Google": "Link with Google")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 30)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding()
            
            // TODO: GitHub Button
            Button {
                Task {
                    if linkedGitHub == false {
                        (alertMsg, isVerified) = await oAuthService.linkWithAccount(mode: .github)
                        if isVerified == true {
                            alertTitle = "Success"
                            alertMsg = "Your GitHub Account has been linked"
                            linkedGitHub = true
                        } else {
                            alertTitle = "Error"
                        }
                        showAlert = true
                    } else {
                        alertMsg = "Are you sure to unlink with GitHub?"
                        showGitHubWarning = true
                    }
                }
            } label: {
                HStack {
                    Image(colourScheme == .dark ? "GitHub_Invertocat_White": "GitHub_Invertocat_Black")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                    
                    Text(linkedGitHub ? "Unlink with GitHub": "Link with GitHub")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding()
        }
        .onAppear() {
            let user = Auth.auth().currentUser!
            linkedGoogle = user.providerData.contains { userInfo in
                return userInfo.providerID == "google.com"
            }
            linkedGitHub = user.providerData.contains { userInfo in
                return userInfo.providerID == "github.com"
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMsg), dismissButton: .default(Text("OK")))
        }
        .alert("Warning", isPresented: $showGoogleWarning) {
            Button("Yes", role: .destructive) {
                Task {
                    let user = Auth.auth().currentUser!
                    let onlyGoogle = user.providerData.allSatisfy { userInfo in
                        return userInfo.providerID == "google.com"
                    }
                    if onlyGoogle == true {
                        alertTitle = "Error"
                        alertMsg = "To unlink Google, Google cannot be your only authentication method"
                        showAlert = true
                    } else {
                        alertMsg = await oAuthService.unLinkAccount(mode: .google)
                        if alertMsg == "" {
                            alertTitle = "Success"
                            alertMsg = "Google Account unlinked successfully"
                            linkedGoogle = false
                        } else {
                            alertTitle = "Error"
                        }
                        showAlert = true
                    }
                }
            }
            Button ("No", role: .cancel) {
                
            }
        } message: {
            Text(alertMsg)
        }
        .alert("Warning", isPresented: $showGitHubWarning) {
            Button("Yes", role: .destructive) {
                Task {
                    let user = Auth.auth().currentUser!
                    let onlyGoogle = user.providerData.allSatisfy { userInfo in
                        return userInfo.providerID == "github.com"
                    }
                    if onlyGoogle == true {
                        alertTitle = "Error"
                        alertMsg = "To unlink GitHub, GitHub cannot be your only authentication method"
                        showAlert = true
                    } else {
                        alertMsg = await oAuthService.unLinkAccount(mode: .github)
                        if alertMsg == "" {
                            alertTitle = "Success"
                            alertMsg = "GitHub Account unlinked successfully"
                            linkedGitHub = false
                        } else {
                            alertTitle = "Error"
                        }
                        showAlert = true
                    }
                }
            }
            Button ("No", role: .cancel) {
                
            }
        } message: {
            Text(alertMsg)
        }
    }
}

#Preview {
    IntegrationView()
}
