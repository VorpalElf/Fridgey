//
//  HomeView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 02/06/2026.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var navViewModel: NavigationViewModel
    
    @State private var showAlert: Bool = false
    @State private var alertMsg: String = ""
    
    var body: some View {
        VStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
        .toolbar {
            Button {
                navViewModel.navigate(to: .settings)
            } label: {
                Image(systemName: "gear")
            }
            
            Button {
                Task {
                    (alertMsg, showAlert) = await authViewModel.SignOut()
                    if showAlert == false {
                        navViewModel.backToRoot()
                    }
                }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMsg), dismissButton: .default(Text("OK")))
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    HomeView()
}
