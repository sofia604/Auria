import Foundation

struct MovementSequence: Codable, Identifiable {
    var id: String { name }
    let name: String
    let commands: [RobotCommand]
    
    // Custom decoding to match the movements.json structure
    init(name: String, commands: [RobotCommand]) {
        self.name = name
        self.commands = commands
    }
} 