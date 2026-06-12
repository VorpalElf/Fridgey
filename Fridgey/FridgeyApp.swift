//
//  FridgeyApp.swift
//  Fridgey
//
//  Created by Jeremy Lo on 02/06/2026.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import Supabase

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

final class SupaManager {
    static let shared = SupaManager()
    
    let supabase: SupabaseClient
    
    private init() {
        // Safe URL creation
        let url = URL(string: "https://lmyvxfkwbakchnyuamhe.supabase.co")!
        let anonKey = "sb_publishable_UKhHyZHY5XUs7GTIVD-5ng_C2kkARcT"
        
        supabase = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: .init(accessToken: {
                    // Directly call Auth.auth() instead of referencing SupaManager.shared
                    return try? await Auth.auth().currentUser?.getIDToken()
                })
            )
        )
    }
}

@main
struct FridgeyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
