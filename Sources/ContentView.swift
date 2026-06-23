import SwiftUI
import LLM

struct ContentView: View {
    @State private var bot: Bot?
    @State private var loadProgress: Double = 0

    var body: some View {
        VStack(spacing: 12) {
            Text("PhoneAI")
                .font(.largeTitle).bold()

            if let bot {
                ChatView(bot: bot)
            } else {
                Spacer()
                ProgressView(value: loadProgress) {
                    Text("טוען מודל… \(Int(loadProgress * 100))%")
                }
                .padding()
                Text("בפעם הראשונה מורידים את המודל (~1GB) — זה לוקח כמה דקות")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .task {
            if bot == nil {
                bot = await Bot(progress: { p in
                    Task { @MainActor in loadProgress = p }
                })
            }
        }
    }
}

struct ChatView: View {
    @ObservedObject var bot: Bot
    @State private var input = ""

    var body: some View {
        VStack(spacing: 10) {
            ScrollView {
                Text(bot.output.isEmpty ? "שאל אותי משהו…" : bot.output)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 8) {
                TextField("כתוב הודעה…", text: $input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button {
                    let p = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !p.isEmpty else { return }
                    input = ""
                    Task { await bot.respond(to: p) }
                } label: {
                    Image(systemName: "paperplane.fill").font(.title2)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
