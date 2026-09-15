import Foundation
import SwiftUI

final class FileDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {

    enum DownloadStatus: Equatable {
        case idle
        case downloading
        case downloaded
        case failed(String)
    }

    @Published var progress: Double = 0.0
    @Published var status: DownloadStatus = .idle

    private var session: URLSession!
    private var downloadTask: URLSessionDownloadTask?
    private var destinationURL: URL?
    private var onComplete: ((URL) -> Void)?

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func start(url: URL, destination: URL, onComplete: ((URL) -> Void)? = nil) {
        self.destinationURL = destination
        self.onComplete = onComplete
        self.progress = 0.0
        self.status = .downloading

        let task = session.downloadTask(with: url)
        self.downloadTask = task
        task.resume()
    }

    func cancel() {
        downloadTask?.cancel()
        downloadTask = nil
        DispatchQueue.main.async {
            self.status = .idle
            self.progress = 0.0
        }
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        // КЛЮЧЕВОЙ МОМЕНТ: у HuggingFace с ?download=true totalBytesExpectedToWrite
        // приходит как -1 или 0. Без этой защиты прогресс схлопывается в 1.0 = 100%.
        guard totalBytesExpectedToWrite > 0 else { return }

        let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progress = min(max(p, 0.0), 1.0)
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let destination = destinationURL else { return }

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: location, to: destination)

            DispatchQueue.main.async {
                self.progress = 1.0
                self.status = .downloaded
                self.onComplete?(destination)
            }
        } catch {
            DispatchQueue.main.async {
                self.status = .failed(error.localizedDescription)
            }
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                // NSURLErrorCancelled (-999) — это отмена пользователем, не ошибка
                if (error as NSError).code != NSURLErrorCancelled {
                    self.status = .failed(error.localizedDescription)
                }
            }
        }
        // Разрываем retain cycle между сессией и делегатом
        session.finishTasksAndInvalidate()
    }
}
