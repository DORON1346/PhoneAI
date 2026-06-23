import Foundation
import MLXLLM
import MLXLMCommon

@MainActor
final class ModelManager: ObservableObject {
    @Published var status: String = "טוען מודל…"
    @Published var ready: Bool = false
    @Published var generating: Bool = false
    @Published var answer: String = ""

    private var container: ModelContainer?

    // Small instruction-tuned model that fits an iPhone 13 (4GB).
    private let modelId = "mlx-community/Qwen2.5-1.5B-Instruct-4bit"

    func load() async {
        guard container == nil else { return }
        do {
            let c = try await LLMModelFactory.shared.loadContainer(
                configuration: ModelConfiguration(id: modelId)
            ) { progress in
                Task { @MainActor in
                    self.status = "מוריד מודל… \(Int(progress.fractionCompleted * 100))%"
                }
            }
            self.container = c
            self.status = "מוכן"
            self.ready = true
        } catch {
            self.status = "שגיאה בטעינה: \(error.localizedDescription)"
        }
    }

    func ask(_ prompt: String) async {
        guard let container else { status = "המודל עדיין לא נטען"; return }
        generating = true
        answer = ""
        do {
            _ = try await container.perform { context in
                let input = try await context.processor.prepare(
                    input: UserInput(chat: [.user(prompt)])
                )
                return try MLXLMCommon.generate(
                    input: input,
                    parameters: GenerateParameters(temperature: 0.6),
                    context: context
                ) { tokens in
                    let text = context.tokenizer.decode(tokens: tokens)
                    Task { @MainActor in self.answer = text }
                    return tokens.count >= 400 ? .stop : .more
                }
            }
        } catch {
            answer = "שגיאה: \(error.localizedDescription)"
        }
        generating = false
    }
}
