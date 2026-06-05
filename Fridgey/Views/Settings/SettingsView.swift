//
//  SettingsView.swift
//  Fridgey
//
//  Created by Jeremy Lo on 03/06/2026.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var navViewModel: NavigationViewModel
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            List {
                Section {
                    Button {
                        navViewModel.navigate(to: .profile)
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 32)
                            Text("Profile")
                        }
                    }
                    
                    Button {
                        navViewModel.navigate(to: .integration)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 32)
                            Text("Integration")
                        }
                    }
                }
                
                Section {
                    Text("More Stuff")
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
