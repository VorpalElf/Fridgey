//
//  ContentView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 02/06/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var navViewModel = NavigationViewModel()
    
    var body: some View {
        NavigationStack(path: $navViewModel.path){
            VStack {
                Text("Welcome")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Button("Sign In") {
                    navViewModel.navigate(to: .signIn)
                }
                .padding()
                .padding(.horizontal, 13)
                .background(Color(.orange))
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
                .cornerRadius(8)
                .frame(width: 180)
                
                Button("Register"){
                    navViewModel.navigate(to: .register)
                }
                .padding()
                .padding(.horizontal, 13)
                .background(Color(.blue))
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
                .cornerRadius(8)
                .frame(width: 180)
            }
            .padding()
            .navigationDestination (for: AppRoute.self) {
                route in switch route {
                case .register:
                    RegisterView()
                case .signIn:
                    SignInView()
                case .home:
                    HomeView()
                }
            }
        }
        .environmentObject(navViewModel)
    }
}

#Preview {
    ContentView()
}
