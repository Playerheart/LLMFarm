import SwiftUI

struct DownloadButton: View {

    @Binding var modelName: String
    @Binding var modelUrl: String
    @Binding var filename: String

    @Binding var status: String

    @StateObject private var downloader = FileDownloader()

    private func download() {
        status = "downloading"
        print("Downloading model \(modelName) from \(modelUrl)")

        guard let url = URL(string: modelUrl) else {
            status = "download"
            return
        }

        let fileURL = getFileURLFormPathStr(dir: "models", filename: filename)

        downloader.start(url: url, destination: fileURL) { _ in
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
                    downloader.cancel()
                    status = "download"
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("\(Int(downloader.progress * 100))%")
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
            downloader.cancel()
        }
        .onChange(of: downloader.status) { newStatus in
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
