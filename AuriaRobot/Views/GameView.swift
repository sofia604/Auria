import SwiftUI

struct GameView: View {
    @State private var score: Int = 0
    @State private var timeLeft: Int = 30
    @State private var gameOver: Bool = false
    @State private var circlePosition: CGPoint = CGPoint(x: 150, y: 200)
    @State private var layoutSize: CGSize = .zero
    @State private var timer: Timer? = nil
    @State private var commandTimer: Timer? = nil
    @State private var movements: [[RobotCommand]] = []
    @State private var movementIndex: Int = 0
    @State private var errorMessage: String? = nil
    @State private var showRetry: Bool = false
    let circleSize: CGFloat = 80

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("🎯 Tap the Circle")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Score: \(score) | Time: \(timeLeft)s")
                        .font(.headline)
                    Spacer()
                    if !gameOver && errorMessage == nil {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: circleSize, height: circleSize)
                            .position(circlePosition)
                            .onTapGesture {
                                handleTap()
                            }
                    } else if gameOver && errorMessage == nil {
                        Text("Game Over! Final Score: \(score)")
                            .font(.title2)
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    if let errorMessage = errorMessage {
                        Text(errorMessage).foregroundColor(.red)
                        if showRetry {
                            Button("Retry") {
                                retryGame(geometry: geometry)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .onAppear {
                    layoutSize = geometry.size
                    startGame()
                }
                .onDisappear {
                    timer?.invalidate()
                    commandTimer?.invalidate()
                }
            }
        }
    }

    private func startGame() {
        score = 0
        timeLeft = 30
        gameOver = false
        movementIndex = 0
        errorMessage = nil
        showRetry = false
        loadMovements()
        moveCircle()
        timer?.invalidate()
        commandTimer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                gameOver = true
                timer?.invalidate()
                commandTimer?.invalidate()
            }
        }
        commandTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            sendNextMovement()
        }
    }

    private func moveCircle() {
        let maxX = max(layoutSize.width - circleSize, 0)
        let maxY = max(layoutSize.height - circleSize, 0)
        let newX = CGFloat.random(in: circleSize/2...maxX)
        let newY = CGFloat.random(in: circleSize/2...maxY)
        circlePosition = CGPoint(x: newX, y: newY)
    }

    private func handleTap() {
        if gameOver || errorMessage != nil { return }
        score += 1
        moveCircle()
    }

    private func loadMovements() {
        guard let url = Bundle.main.url(forResource: "commands", withExtension: "json", subdirectory: "Resources"),
              let data = try? Data(contentsOf: url) else {
            errorMessage = "Could not load commands.json."
            showRetry = true
            timer?.invalidate()
            commandTimer?.invalidate()
            return
        }
        do {
            let json = try JSONDecoder().decode([String: [VideoTrigger]].self, from: data)
            self.movements = json["mainData"]?.map { $0.data } ?? []
            errorMessage = nil
            showRetry = false
        } catch {
            errorMessage = "Failed to parse commands.json: \(error.localizedDescription)"
            showRetry = true
            timer?.invalidate()
            commandTimer?.invalidate()
        }
    }

    private func sendNextMovement() {
        guard !gameOver, !movements.isEmpty, errorMessage == nil else { return }
        let commands = movements[movementIndex % movements.count]
        Task {
            do {
                _ = try await RobotCommunicationService.shared.sendCommands(commands)
                print("Sent movement set #\(movementIndex)")
            } catch {
                errorMessage = "Error sending to server: \(error.localizedDescription)"
                showRetry = true
                timer?.invalidate()
                commandTimer?.invalidate()
            }
        }
        movementIndex += 1
    }

    private func retryGame(geometry: GeometryProxy) {
        timer?.invalidate()
        commandTimer?.invalidate()
        layoutSize = geometry.size
        startGame()
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
} 