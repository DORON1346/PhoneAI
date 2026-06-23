import SwiftUI

struct ContentView: View {
    @StateObject private var model = ModelManager()
    @State private var prompt = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("PhoneAI")
                .font(.largeTitle).bold()
            Text(model.status)
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                Text(model.answer.isEmpty ? "שאל אותי משהו…" : model.answer)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 8) {
                TextField("כתוב הודעה…", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button {
                    let p = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !p.isEmpty else { return }
                    prompt = ""
                    Task { await model.ask(p) }
                } label: {
                    Image(systemName: "paperplane.fill").font(.title2)
                }
                .disabled(!model.ready || model.generating)
            }
        }
        .padding()
        .task { await model.load() }
    }
}

#Preview {
    ContentView()
}
