import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            VideoPlayerView()
                .tabItem {
                    Label("Video", systemImage: "play.rectangle.fill")
                }
            GameView()
                .tabItem {
                    Label("Game", systemImage: "gamecontroller.fill")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 