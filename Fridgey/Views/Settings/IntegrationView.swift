//
//  IntegrationView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 05/06/2026.
//

import SwiftUI

struct IntegrationView: View {
    @EnvironmentObject var navViewModel: NavigationViewModel
    
    @State private var linkedGoogle: Bool = false
    @State private var linkedApple: Bool = false
    @State private var linkedGitHub: Bool = false
    
    @State private var alertMsg: String = ""
    @State private var showAlert: Bool = false
    
    var body: some View {
        VStack {
            // TODO: Detect if user linked
            Button {
                
            } label: {
                HStack {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                    
                    Text("Link with Google")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 30)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMsg), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    IntegrationView()
}
