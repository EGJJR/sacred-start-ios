//
//  SupabaseConfig.swift
//  DevotionLock
//

import Foundation

enum SupabaseConfig {
    // Publishable anon key — safe in client; RLS enforces row access. Never commit service_role keys.
    static let projectURL = URL(string: "https://ygirplpbgxwvstnqxnrz.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlnaXJwbHBiZ3h3dnN0bnF4bnJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3ODMwMTQsImV4cCI6MjA5NjM1OTAxNH0._1m-UEilob_qGwv1pl2w1ChCG0piyoQgkT0rjxWn3E0"

    static var chaplainChatFunctionURL: URL {
        projectURL.appendingPathComponent("functions/v1/chaplain-chat")
    }

    static var generateInsightFunctionURL: URL {
        projectURL.appendingPathComponent("functions/v1/generate-insight")
    }
}
