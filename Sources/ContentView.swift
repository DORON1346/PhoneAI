import SwiftUI

struct ContentView: View {
    @State private var isListening = false

    var body: some View {
        VStack(spacing: 24) {
            Text("PhoneAI")
                .font(.largeTitle).bold()

            Text(isListening ? "מקשיב…" : "מוכן")
                .font(.title3)
                .foregroundStyle(.secondary)

            Button {
                // Phase 1 will wire this button to on-device speech recognition
                // (Apple Speech framework) and the local LLM (Qwen3 1.7B via MLX).
                isListening.toggle()
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 44))
                    .frame(width: 120, height: 120)
                    .background(Circle().fill(.blue.opacity(0.15)))
            }
            .accessibilityLabel("דבר")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
