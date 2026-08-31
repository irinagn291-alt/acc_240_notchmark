import SwiftUI

struct ContentView: View {
    @ObservedObject var session: RailSession

    var body: some View {
        RailView(session: session)
    }
}

#Preview {
    ContentView(session: .previewPopulated())
}
