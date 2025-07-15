import Foundation

class RobotCommunicationService {
    static let shared = RobotCommunicationService()
    private let serverURL = URL(string: "http://192.168.4.2:3000/execute-sequence")!
    
    private init() {}
    
    func sendCommands(_ commands: [RobotCommand]) async throws -> String {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        let payload = ["data": commands]
        request.httpBody = try encoder.encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return String(data: data, encoding: .utf8) ?? "Success"
    }
} 