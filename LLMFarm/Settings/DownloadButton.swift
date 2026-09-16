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

        // ЗАЩИТА: файл должен быть достаточно большим, чтобы быть моделью.
        // 15-байтные ответы — это HTML-страницы ошибок (404, Unauthorized), а не GGUF.
        let attributes = try? FileManager.default.attributesOfItem(atPath: location.path)
        let size = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        let MIN_MODEL_SIZE: Int64 = 1_000_000  // 1 МБ — любой GGUF больше

        if size < MIN_MODEL_SIZE {
            // Читаем содержимое, чтобы показать его в ошибке
            let text = (try? String(contentsOf: location, encoding: .utf8)) ?? "<бинарные данные>"
            let preview = text.prefix(200)
            DispatchQueue.main.async {
                self.statusByKey[key] = .failed("Файл повреждён (размер \(size) Б). Ответ сервера: \(preview)")
                self.progressByKey[key] = 0.0
            }
            return
        }

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

    // Диалог-предупреждение перед началом загрузки
    @State private var showWarning: Bool = false

    // Сообщение об ошибке для показа пользователю
    @State private var errorMessage: String? = nil

    private var fileKey: String { filename }

    // Фактический старт загрузки — вызывается после подтверждения в alert
    private func startDownload() {
        status = "downloading"
        print("Downloading model \(modelName) from \(modelUrl)")
        guard let url = URL(string: modelUrl) else {
            status = "download"
            errorMessage = "Некорректный URL: \(modelUrl)"
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
                Button(action: {
                    // Сначала показываем предупреждение
                    showWarning = true
                }) {
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
        // Alert 1: предупреждение о необходимости не выходить из приложения
        .alert("Не выходите из приложения", isPresented: $showWarning) {
            Button("Отмена", role: .cancel) {
                // Пользователь отказался — ничего не делаем
            }
            Button("Начать загрузку") {
                startDownload()
            }
        } message: {
            Text("Пока модель загружается, не выходите из приложения и не сворачивайте его. При выходе загрузка прервётся и начнётся заново.")
        }
        // Alert 2: показ ошибки загрузки
        .alert("Ошибка загрузки", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .onDisappear {
            // Загрузка продолжается в фоне через синглтон — НЕ отменяем
        }
        .onChange(of: manager.status(for: fileKey)) { newStatus in
            switch newStatus {
            case .downloaded:
                status = "downloaded"
            case .failed(let msg):
                print("Download failed: \(msg)")
                errorMessage = msg
                status = "download"
            case .idle:
                if status == "downloading" { status = "download" }
            case .downloading:
                break
            }
        }
    }
}
