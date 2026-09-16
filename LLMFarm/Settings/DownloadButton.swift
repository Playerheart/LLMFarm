import SwiftUI
import Foundation

// MARK: - Глобальный менеджер загрузок (синглтон)
final class FileDownloadManager: NSObject, ObservableObject {

    static let shared = FileDownloadManager()

    enum Status: Equatable {
        case idle
        case downloading
        case downloaded
        case failed(String)
    }

    @Published private(set) var progressByKey: [String: Double] = [:]
    @Published private(set) var statusByKey: [String: Status] = [:]

    private var session: URLSession!
    private var downloadTasks: [Int: String] = [:]
    private var destinations: [String: URL] = [:]
    private var completions: [String: (URL) -> Void] = [:]
    private var tasksByKey: [String: URLSessionDownloadTask] = [:]

    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func start(url: URL, destination: URL, key: String, onComplete: ((URL) -> Void)? = nil) {
        // Если уже качается — не перезапускаем
        if statusByKey[key] == .downloading { return }

        progressByKey[key] = 0.0
        statusByKey[key] = .downloading
        destinations[key] = destination
        completions[key] = onComplete

        let task = session.downloadTask(with: url)
        tasksByKey[key] = task
        downloadTasks[task.taskIdentifier] = key
        task.resume()
    }

    func cancel(key: String) {
        tasksByKey[key]?.cancel()
        tasksByKey.removeValue(forKey: key)
        statusByKey[key] = .idle
        progressByKey[key] = 0.0
    }

    func status(for key: String) -> Status { statusByKey[key] ?? .idle }
    func progress(for key: String) -> Double { progressByKey[key] ?? 0.0 }
}

extension FileDownloadManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let key = downloadTasks[downloadTask.taskIdentifier] else { return }
        // HuggingFace отдаёт -1 при редиректе — защита от схлопывания в 100%
        guard totalBytesExpectedToWrite > 0 else { return }
        let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progressByKey[key] = min(max(p, 0.0), 1.0)
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let key = downloadTasks[downloadTask.taskIdentifier] else { return }
        guard let destination = destinations[key] else { return }
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: location, to: destination)
            DispatchQueue.main.async {
                self.progressByKey[key] = 1.0
                self.statusByKey[key] = .downloaded
                self.completions[key]?(destination)
            }
        } catch {
            DispatchQueue.main.async {
                self.statusByKey[key] = .failed(error.localizedDescription)
            }
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let key = downloadTasks[task.taskIdentifier] else { return }
        if let error = error {
            DispatchQueue.main.async {
                if (error as NSError).code != NSURLErrorCancelled {
                    self.statusByKey[key] = .failed(error.localizedDescription)
                }
            }
        }
        downloadTasks.removeValue(forKey: task.taskIdentifier)
    }
}

// MARK: - DownloadButton
struct DownloadButton: View {

    @Binding var modelName: String
    @Binding var modelUrl: String
    @Binding var filename: String
    @Binding var status: String

    @ObservedObject private var manager = FileDownloadManager.shared

    private var fileKey: String { filename }

    private func download() {
        status = "downloading"
        print("Downloading model \(modelName) from \(modelUrl)")
        guard let url = URL(string: modelUrl) else {
            status = "download"
            return
        }
        let fileURL = getFileURLFormPathStr(dir: "models", filename: filename)
        manager.start(url: url, destination: fileURL, key: fileKey) { _ in
            status = "downloaded"
        }
    }

    var body: some View {
        VStack {
            switch status {
            case "download":
                Button(action: download) {
                    Image(systemName: "icloud.and.arrow.down")
                }
                .buttonStyle(.borderless)

            case "downloading":
                Button(action: {
                    manager.cancel(key: fileKey)
                    status = "download"
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("\(Int(manager.progress(for: fileKey) * 100))%")
                            .padding(.trailing, -20)
                            .monospacedDigit()
                    }
                }
                .buttonStyle(.borderless)

            case "downloaded":
                Image(systemName: "checkmark.circle.fill")

            default:
                Text("Unknown status")
            }
        }
        .onDisappear {
            // НЕ отменяем загрузку — она продолжается в фоне через синглтон
        }
        .onChange(of: manager.status(for: fileKey)) { newStatus in
            switch newStatus {
            case .downloaded:
                status = "downloaded"
            case .failed(let msg):
                print("Download failed: \(msg)")
                status = "download"
            case .idle:
                if status == "downloading" { status = "download" }
            case .downloading:
                break
            }
        }
    }
}
