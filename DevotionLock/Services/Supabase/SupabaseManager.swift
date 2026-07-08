//
//  SupabaseManager.swift
//  DevotionLock
//

import Foundation
import Supabase

enum SupabaseManager {
    static let client: SupabaseClient = {
        SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.anonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    redirectToURL: URL(string: "devotionlock://password-reset"),
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()
}
