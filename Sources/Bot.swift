import Foundation
import LLM

/// On-device chat model — Qwen2.5 1.5B (Q4_K_M GGUF, ~940MB) via llama.cpp.
/// This is the model that ran well on the iPhone 13. Downloaded once from the
/// app's own GitHub release and cached locally. On launch it also deletes any
/// other cached .gguf models from previous experiments (frees storage).
final class Bot: LLM {
    static let modelRemoteURL = URL(string: "https://github.com/DORON1346/PhoneAI/releases/download/model-v1/model.gguf")!

    convenience init?(progress: @escaping (Double) -> Void) async {
        let fm = FileManager.default
        let dir = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? fm.temporaryDirectory
        let localURL = dir.appendingPathComponent("phoneai-qwen2.5-1.5b-q4km.gguf")

        // Clean up any OTHER cached model files (e.g. earlier Gemma experiments).
        if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for f in files where f.pathExtension.lowercased() == "gguf" && f.lastPathComponent != localURL.lastPathComponent {
                try? fm.removeItem(at: f)
                print("removed old model: \(f.lastPathComponent)")
            }
        }

        if !fm.fileExists(atPath: localURL.path) {
            do {
                try await ModelDownloader.shared.download(from: Bot.modelRemoteURL, to: localURL, progress: progress)
            } catch {
                print("PhoneAI model download failed: \(error)")
                return nil
            }
        } else {
            progress(1.0)
        }

        let system = "אתה PhoneAI — עוזר AI מקומי וחכם. ענה בעברית בצורה ברורה, מדויקת וקצרה."
        self.init(from: localURL, template: .chatML(system))
    }
}

/// Streams a large file to disk (no RAM blow-up) and reports progress 0...1.
final class ModelDownloader: NSObject, URLSessionDownloadDelegate {
    static let shared = ModelDownloader()

    private var continuation: CheckedContinuation<Void, Error>?
    private var destination: URL?
    private var onProgress: ((Double) -> Void)?
    private var finished = false

    func download(from remote: URL, to dest: URL, progress: @escaping (Double) -> Void) async throws {
        destination = dest
        onProgress = progress
        finished = false
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 3600
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            continuation = c
            session.downloadTask(with: remote).resume()
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let handler = onProgress
        DispatchQueue.main.async { handler?(p) }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard !finished, let dest = destination else { return }
        finished = true
        do {
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: location, to: dest)
            continuation?.resume()
        } catch {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard !finished else { return }
        finished = true
        continuation?.resume(throwing: error ?? URLError(.unknown))
        continuation = nil
    }
}
