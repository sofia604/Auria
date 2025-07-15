import Foundation

struct RobotCommand: Codable, Identifiable {
    var id: UUID = UUID()
    let N: Int
    let H: String?
    let D1: Int
    let D2: Int
    let T: Int?
    
    enum CodingKeys: String, CodingKey {
        case N, H, D1, D2, T
    }
    
    // Custom init to allow optional H and T
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        N = try container.decode(Int.self, forKey: .N)
        H = try? container.decodeIfPresent(String.self, forKey: .H)
        D1 = try container.decode(Int.self, forKey: .D1)
        D2 = try container.decode(Int.self, forKey: .D2)
        T = try? container.decodeIfPresent(Int.self, forKey: .T)
    }
    
    // For manual creation
    init(N: Int, H: String? = nil, D1: Int, D2: Int, T: Int? = nil) {
        self.N = N
        self.H = H
        self.D1 = D1
        self.D2 = D2
        self.T = T
    }
} 