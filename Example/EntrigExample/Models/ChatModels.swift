import Foundation

// MARK: - Database Models (matching Flutter schema exactly)

struct User: Codable {
    let id: String
    let createdAt: Date?
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case name
    }
}

struct Group: Codable {
    let id: String
    let createdAt: Date?
    let name: String
    let createdBy: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case name
        case createdBy = "created_by"
    }
}

struct GroupMember: Codable {
    let groupId: String
    let userId: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct Message: Codable {
    let id: String
    let createdAt: Date?
    let content: String
    let userId: String
    let groupId: String
    var senderName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case content
        case userId = "user_id"
        case groupId = "group_id"
    }
}

// MARK: - Helper Extensions

extension Group {
    var isOwnedBy: (String) -> Bool {
        return { userId in
            self.createdBy == userId
        }
    }
}
