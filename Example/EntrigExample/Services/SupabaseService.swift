import Foundation
import Supabase

/// Supabase service for database operations (matching Flutter SupabaseTable exactly)
class SupabaseService {
    static let shared = SupabaseService()

    private(set) var client: SupabaseClient!

    private init() {}

    func initialize(url: String, anonKey: String) {
        client = SupabaseClient(
            supabaseURL: URL(string: url)!,
            supabaseKey: anonKey
        )
    }

    // MARK: - Users

    func getUser(id: String) async throws -> User {
        let response: User = try await client
            .from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        return response
    }

    func upsertUser(id: String, name: String) async throws {
        struct UserInput: Encodable {
            let id: String
            let name: String
        }

        let userData = UserInput(id: id, name: name)

        try await client
            .from("users")
            .upsert(userData)
            .execute()
    }

    // MARK: - Groups

    func getAllGroups() async throws -> [Group] {
        let response: [Group] = try await client
            .from("groups")
            .select()
            .order("created_at")
            .execute()
            .value

        return response
    }

    func createGroup(name: String, createdBy: String) async throws -> Group {
        struct GroupInput: Encodable {
            let name: String
            let createdBy: String

            enum CodingKeys: String, CodingKey {
                case name
                case createdBy = "created_by"
            }
        }

        let groupData = GroupInput(name: name, createdBy: createdBy)

        let response: Group = try await client
            .from("groups")
            .insert(groupData)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Group Members

    func getJoinedGroupIds(userId: String) async throws -> Set<String> {
        struct GroupIdResponse: Decodable {
            let groupId: String
            enum CodingKeys: String, CodingKey {
                case groupId = "group_id"
            }
        }

        let response: [GroupIdResponse] = try await client
            .from("group_members")
            .select("group_id")
            .eq("user_id", value: userId)
            .execute()
            .value

        return Set(response.map { $0.groupId })
    }

    func joinGroup(groupId: String, userId: String) async throws {
        struct MemberInput: Encodable {
            let groupId: String
            let userId: String

            enum CodingKeys: String, CodingKey {
                case groupId = "group_id"
                case userId = "user_id"
            }
        }

        let memberData = MemberInput(groupId: groupId, userId: userId)

        try await client
            .from("group_members")
            .insert(memberData)
            .execute()
    }

    func checkIfUserInGroup(groupId: String, userId: String) async throws -> Bool {
        struct MemberCheck: Decodable {
            let groupId: String
            enum CodingKeys: String, CodingKey {
                case groupId = "group_id"
            }
        }

        do {
            let _: MemberCheck = try await client
                .from("group_members")
                .select()
                .eq("group_id", value: groupId)
                .eq("user_id", value: userId)
                .limit(1)
                .single()
                .execute()
                .value

            return true
        } catch {
            // If single() fails, it means no record found
            return false
        }
    }

    // MARK: - Messages

    func getMessages(groupId: String) async throws -> [Message] {
        struct MessageWithUser: Decodable {
            let id: String
            let createdAt: Date?
            let content: String
            let userId: String
            let groupId: String
            let users: UserInfo?

            struct UserInfo: Decodable {
                let name: String
            }

            enum CodingKeys: String, CodingKey {
                case id
                case createdAt = "created_at"
                case content
                case userId = "user_id"
                case groupId = "group_id"
                case users
            }
        }

        let response: [MessageWithUser] = try await client
            .from("messages")
            .select("*, users!inner(name)")
            .eq("group_id", value: groupId)
            .order("created_at")
            .execute()
            .value

        return response.map { msgWithUser in
            var message = Message(
                id: msgWithUser.id,
                createdAt: msgWithUser.createdAt,
                content: msgWithUser.content,
                userId: msgWithUser.userId,
                groupId: msgWithUser.groupId
            )
            message.senderName = msgWithUser.users?.name
            return message
        }
    }

    func sendMessage(content: String, userId: String, groupId: String) async throws {
        struct MessageInput: Encodable {
            let content: String
            let userId: String
            let groupId: String

            enum CodingKeys: String, CodingKey {
                case content
                case userId = "user_id"
                case groupId = "group_id"
            }
        }

        let messageData = MessageInput(content: content, userId: userId, groupId: groupId)

        try await client
            .from("messages")
            .insert(messageData)
            .execute()
    }

    // MARK: - Realtime Subscriptions

    func subscribeToMessages(
        groupId: String,
        onInsert: @escaping (Message) -> Void
    ) -> RealtimeChannelV2 {
        let channel = client.channel("messages:\(groupId)")

        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "group_id=eq.\(groupId)"
        ) { action in
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601

                let message = try action.decodeRecord(as: Message.self, decoder: decoder)
                onInsert(message)
            } catch {
                print("[SupabaseService] Error decoding message: \(error)")
            }
        }

        Task {
            try? await channel.subscribeWithError()
        }

        return channel
    }
}
