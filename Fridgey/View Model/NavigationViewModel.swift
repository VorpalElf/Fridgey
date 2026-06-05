//
//  NavigationViewModel.swift
//  Fridgey
//
//  Created by Jeremy Lo on 02/06/2026.
//

import Foundation
import SwiftUI

// Define routes available
enum AppRoute: Hashable {
    case register
    case home
    case settings
    case profile
    case integration
}

class NavigationViewModel: ObservableObject {
    @Published var path: [AppRoute] = []
    
    func navigate (to route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func backToRoot() {
        if !path.isEmpty {
            path.removeLast(path.count)
        }
    }
}


