import Foundation
import LLM

/// On-device chat model (Qwen2.5 1.5B, 4-bit GGUF) running via llama.cpp.
/// Small enough for an iPhone 13 (4GB) while still good at following instructions.
final class Bot: LLM {
    convenience init?(progress: @escaping (Double) -> Void) async {
        let system = "אתה PhoneAI — עוזר AI מקומי וחכם. ענה בעברית בצורה ברורה, מדויקת וקצרה. אם אינך יודע משהו, אמור זאת בכנות."
        let model = HuggingFaceModel(
            "bartowski/Qwen2.5-1.5B-Instruct-GGUF",
            .Q4_K_M,
            template: .chatML(system)
        )
        try? await self.init(from: model) { p in progress(p) }
    }
}
