import Foundation

struct VideoTrigger: Codable, Identifiable {
    var id: String { label }
    let label: String
    let time: Double
    let data: [RobotCommand]
    
    enum CodingKeys: String, CodingKey {
        case label, time, data
    }
} 