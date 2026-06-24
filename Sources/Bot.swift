import Foundation
import LLM

/// On-device chat model — Gemma 3 1B (Q4_K_M GGUF) via llama.cpp.
/// Small enough (~770MB) to fit an iPhone 13 (4GB) reliably; Gemma is multilingual.
/// Downloaded once from the app's own GitHub release and cached locally.
final class Bot: LLM {
    static let modelRemoteURL = URL(string: "https://github.com/DORON1346/PhoneAI/releases/download/model-v3/model.gguf")!

    convenience init?(progress: @escaping (Double) -> Void) async {
        let fm = FileManager.default
        let dir = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? fm.temporaryDirectory
        let localURL = dir.appendingPathComponent("phoneai-gemma3-1b.gguf")

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

        // Gemma chat format. Ask in Hebrew -> answers in Hebrew.
        self.init(from: localURL, template: .gemma)
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
