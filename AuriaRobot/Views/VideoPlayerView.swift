import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @State private var player: AVPlayer? = nil
    @State private var triggers: [VideoTrigger] = []
    @State private var firedIndexes: Set<Int> = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = true
    @State private var timer: Timer? = nil
    @State private var showRetry: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Robot-Controlled Video")
                .font(.title)
                .fontWeight(.semibold)
            if let player = player {
                VideoPlayer(player: player)
                    .frame(height: 300)
                    .onAppear {
                        player.play()
                        startTimer()
                    }
                    .onDisappear {
                        timer?.invalidate()
                    }
            } else if isLoading {
                ProgressView("Loading video...")
            } else if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
                if showRetry {
                    Button("Retry") {
                        retryLoad()
                    }
                    .padding(.top, 8)
                }
            }
        }
        .onAppear {
            loadTriggers()
            loadVideo()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func loadVideo() {
        if let url = Bundle.main.url(forResource: "my-video", withExtension: "mp4", subdirectory: "Resources") {
            player = AVPlayer(url: url)
            isLoading = false
            errorMessage = nil
            showRetry = false
        } else {
            errorMessage = "Video file not found."
            isLoading = false
            showRetry = true
        }
    }

    private func loadTriggers() {
        guard let url = Bundle.main.url(forResource: "commands", withExtension: "json", subdirectory: "Resources"),
              let data = try? Data(contentsOf: url) else {
            errorMessage = "Could not load commands.json."
            showRetry = true
            return
        }
        do {
            let json = try JSONDecoder().decode([String: [VideoTrigger]].self, from: data)
            self.triggers = json["mainData"] ?? []
            errorMessage = nil
            showRetry = false
        } catch {
            errorMessage = "Failed to parse commands.json: \(error.localizedDescription)"
            showRetry = true
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            guard let player = player, let currentItem = player.currentItem else { return }
            let currentTime = currentItem.currentTime().seconds
            for (index, trigger) in triggers.enumerated() {
                if !firedIndexes.contains(index) && currentTime >= trigger.time {
                    Task {
                        do {
                            _ = try await RobotCommunicationService.shared.sendCommands(trigger.data)
                            print("Trigger \(trigger.label) fired at \(trigger.time)s")
                        } catch {
                            errorMessage = "Failed to send commands for trigger \(trigger.label): \(error.localizedDescription)"
                            showRetry = true
                            timer?.invalidate()
                            player.pause()
                        }
                    }
                    firedIndexes.insert(index)
                }
            }
        }
    }

    private func retryLoad() {
        errorMessage = nil
        isLoading = true
        showRetry = false
        firedIndexes = []
        player = nil
        loadTriggers()
        loadVideo()
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView()
    }
} 