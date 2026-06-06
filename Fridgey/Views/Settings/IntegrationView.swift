//
//  IntegrationView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 05/06/2026.
//

import SwiftUI

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
    @State private var warningMsg: String = ""
    @State private var showWarning: Bool = false
    
    var body: some View {
        VStack {
            // TODO: Detect if user linked
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
                        alertTitle = "Warning"
                        alertMsg = "Are you sure to unlink with Google?"
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
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMsg), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    IntegrationView()
}
