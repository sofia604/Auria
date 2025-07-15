import Foundation
import Network

class RobotCommunicationService {
    static let shared = RobotCommunicationService()
    private let robotIP = "192.168.4.1"
    private let robotPort: NWEndpoint.Port = 100
    
    private init() {}
    
    func sendCommands(_ commands: [RobotCommand]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let connection = NWConnection(host: NWEndpoint.Host(robotIP), port: robotPort, using: .tcp)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    Task {
                        do {
                            try await self.sendSequence(commands, over: connection)
                            connection.cancel()
                            continuation.resume(returning: "Sequence completed")
                        } catch {
                            connection.cancel()
                            continuation.resume(throwing: error)
                        }
                    }
                case .failed(let error):
                    connection.cancel()
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            connection.start(queue: .global())
        }
    }
    
    private func sendSequence(_ commands: [RobotCommand], over connection: NWConnection) async throws {
        for step in commands {
            let encoder = JSONEncoder()
            let payload = try encoder.encode(step)
            let payloadString = String(data: payload, encoding: .utf8) ?? "{}"
            let payloadData = payloadString.data(using: .utf8) ?? Data()
            let sendSemaphore = DispatchSemaphore(value: 0)
            connection.send(content: payloadData, completion: .contentProcessed { error in
                sendSemaphore.signal()
            })
            sendSemaphore.wait()
            let delay = Double(step.T ?? 500) / 1000.0
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
} 