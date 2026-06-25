//
//  ChaplainService.swift
//  DevotionLock
//

import Foundation
import Supabase

enum ChaplainStreamEvent: Sendable {
    case conversationID(UUID)
    case scriptureSearch(label: String)
    case scriptureResult([ChaplainScriptureCitation])
    case token(String)
    case done
}

struct ChaplainChatRequest: Encodable {
    struct MessagePayload: Encodable {
        let role: String
        let content: String
    }

    let conversationID: UUID?
    let messages: [MessagePayload]
    let context: ChaplainRequestContext

    enum CodingKeys: String, CodingKey {
        case conversationID = "conversation_id"
        case messages
        case context
    }
}

protocol ChaplainServiceProtocol: Sendable {
    func streamReply(
        conversationID: UUID?,
        messages: [ChaplainMessage],
        context: ChaplainRequestContext
    ) async throws -> AsyncThrowingStream<ChaplainStreamEvent, Error>
}

enum ChaplainServiceError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "Please sign in to talk with your Chaplain."
        case .invalidResponse: "Unexpected response from the server."
        case .serverError(let message): message
        }
    }
}

@MainActor
final class ChaplainService: ChaplainServiceProtocol {
    static let shared = ChaplainService()

    func streamReply(
        conversationID: UUID?,
        messages: [ChaplainMessage],
        context: ChaplainRequestContext
    ) async throws -> AsyncThrowingStream<ChaplainStreamEvent, Error> {
        let session = try await SupabaseManager.client.auth.session
        let accessToken = session.accessToken

        let payload = ChaplainChatRequest(
            conversationID: conversationID,
            messages: messages.map { message in
                ChaplainChatRequest.MessagePayload(
                    role: message.role == .user ? "user" : "chaplain",
                    content: message.text
                )
            },
            context: context
        )

        var request = URLRequest(url: SupabaseConfig.chaplainChatFunctionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ChaplainServiceError.invalidResponse
        }

        if http.statusCode == 401 {
            throw ChaplainServiceError.notAuthenticated
        }

        if http.statusCode != 200 {
            var errorData = Data()
            for try await byte in bytes {
                errorData.append(byte)
            }
            let message = String(data: errorData, encoding: .utf8) ?? "Server error (\(http.statusCode))"
            throw ChaplainServiceError.serverError(message)
        }

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let json = String(line.dropFirst(6))
                        guard let data = json.data(using: .utf8),
                              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let type = object["type"] as? String else { continue }

                        switch type {
                        case "conversation_id":
                            if let idString = object["conversation_id"] as? String,
                               let id = UUID(uuidString: idString) {
                                continuation.yield(.conversationID(id))
                            }
                        case "scripture_search":
                            let reference = object["reference"] as? String
                            let query = object["query"] as? String
                            let label: String
                            if let reference, !reference.isEmpty {
                                label = "Opening \(reference)…"
                            } else if let query, !query.isEmpty {
                                label = "Searching for \"\(query)\"…"
                            } else {
                                label = "Searching Scripture…"
                            }
                            continuation.yield(.scriptureSearch(label: label))
                        case "scripture_result":
                            if let rawPassages = object["passages"] as? [[String: Any]] {
                                let citations = rawPassages.compactMap { ChaplainScriptureCitation.fromJSON($0) }
                                if !citations.isEmpty {
                                    continuation.yield(.scriptureResult(citations))
                                }
                            }
                        case "token":
                            if let text = object["text"] as? String {
                                continuation.yield(.token(text))
                            }
                        case "done":
                            continuation.yield(.done)
                        default:
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
