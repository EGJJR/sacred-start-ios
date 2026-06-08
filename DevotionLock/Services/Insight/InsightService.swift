//
//  InsightService.swift
//  DevotionLock
//

import Foundation
import Supabase

struct GenerateInsightResponse: Decodable {
    let morningsThisWeek: Int
    let topMood: String
    let topMoodEmoji: String
    let currentStreak: Int
    let totalDays: Int
    let highlightInsight: String
    let weeklyNarrative: String?
    let weekCompleted: [Bool]

    enum CodingKeys: String, CodingKey {
        case morningsThisWeek = "mornings_this_week"
        case topMood = "top_mood"
        case topMoodEmoji = "top_mood_emoji"
        case currentStreak = "current_streak"
        case totalDays = "total_days"
        case highlightInsight = "highlight_insight"
        case weeklyNarrative = "weekly_narrative"
        case weekCompleted = "week_completed"
    }
}

enum InsightServiceError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "Please sign in to load your Morning Wrapped insight."
        case .invalidResponse: "Unexpected response from the server."
        case .serverError(let message): message
        }
    }
}

@MainActor
final class InsightService {
    static let shared = InsightService()

    func fetchWeeklyInsight(fallback: MorningWrappedStats) async -> MorningWrappedStats {
        do {
            let response = try await requestWeeklyInsight()
            return MorningWrappedStats(
                morningsThisWeek: response.morningsThisWeek,
                topMood: response.topMood,
                topMoodEmoji: response.topMoodEmoji,
                currentStreak: max(response.currentStreak, fallback.currentStreak),
                totalDays: max(response.totalDays, fallback.totalDays),
                highlightInsight: response.highlightInsight,
                weeklyNarrative: response.weeklyNarrative ?? fallback.weeklyNarrative,
                weekLabels: fallback.weekLabels,
                weekCompleted: response.weekCompleted.isEmpty ? fallback.weekCompleted : response.weekCompleted
            )
        } catch {
            return fallback
        }
    }

    private func requestWeeklyInsight() async throws -> GenerateInsightResponse {
        let session = try await SupabaseManager.client.auth.session
        let accessToken = session.accessToken

        var request = URLRequest(url: SupabaseConfig.generateInsightFunctionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["period": "weekly"])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw InsightServiceError.invalidResponse
        }

        if http.statusCode == 401 {
            throw InsightServiceError.notAuthenticated
        }

        if http.statusCode != 200 {
            let message = String(data: data, encoding: .utf8) ?? "Server error (\(http.statusCode))"
            throw InsightServiceError.serverError(message)
        }

        return try JSONDecoder().decode(GenerateInsightResponse.self, from: data)
    }
}
