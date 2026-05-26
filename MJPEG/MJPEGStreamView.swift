//
//  MJPEGStreamView.swift
//  MJPEG
//
//  Created by i on 2026/5/21.
//

import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

class MJPEGStreamLoader: ObservableObject {
    @Published var currentFrame: PlatformImage?
    @Published var isLoading = false
    @Published var error: String?

    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var receivedData = Data()
    private var expectedContentLength: Int?
    private var isReceivingImage = false

    func startStream(url: URL) {
        stopStream()

        print("🎬 Starting MJPEG stream from: \(url)")
        isLoading = true
        error = nil
        receivedData.removeAll()

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        let config = URLSessionConfiguration.default
        let delegate = StreamDelegate(loader: self)
        session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        task = session?.dataTask(with: request)
        task?.resume()
        print("📡 URLSession task started")
    }

    func stopStream() {
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
        isLoading = false
        receivedData.removeAll()
        expectedContentLength = nil
        isReceivingImage = false
    }

    func handleReceivedData(_ data: Data) {
        receivedData.append(data)
        print("💾 Total buffered data: \(receivedData.count) bytes, expected: \(expectedContentLength ?? 0)")

        // Check if we have received the complete image
        if let expected = expectedContentLength, receivedData.count >= expected {
            print("🎨 Complete image received, attempting to decode")
            if let image = PlatformImage(data: receivedData) {
                print("✅ Image decoded successfully!")
                DispatchQueue.main.async {
                    self.currentFrame = image
                    self.isLoading = false
                }
            } else {
                print("❌ Failed to decode image")
            }
            // Reset for next image
            receivedData.removeAll()
            expectedContentLength = nil
            isReceivingImage = false
        }
    }

    func prepareForNewImage(contentLength: Int) {
        print("🆕 Preparing for new image, size: \(contentLength) bytes")
        receivedData.removeAll()
        expectedContentLength = contentLength
        isReceivingImage = true
    }
}

class StreamDelegate: NSObject, URLSessionDataDelegate {
    weak var loader: MJPEGStreamLoader?

    init(loader: MJPEGStreamLoader) {
        self.loader = loader
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("📦 Received data chunk: \(data.count) bytes")
        loader?.handleReceivedData(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ Stream error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.loader?.error = error.localizedDescription
                self.loader?.isLoading = false
            }
        } else {
            print("✅ Stream completed successfully")
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("📥 Received response: \(response)")
        if let httpResponse = response as? HTTPURLResponse {
            print("   Status code: \(httpResponse.statusCode)")
            if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                print("   Content-Type: \(contentType)")

                // Check if this is an image/jpeg response
                if contentType.contains("image/jpeg") {
                    if let contentLengthStr = httpResponse.allHeaderFields["Content-Length"] as? String,
                       let contentLength = Int(contentLengthStr) {
                        loader?.prepareForNewImage(contentLength: contentLength)
                    }
                }
            }
        }
        completionHandler(.allow)
    }
}

struct MJPEGStreamView: View {
    @StateObject private var loader = MJPEGStreamLoader()
    @State private var urlString = "http://192.168.1.254:8192"

    var body: some View {
        VStack {
            HStack {
                TextField("MJPEG URL", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    #endif

                Button(action: toggleStream) {
                    Image(systemName: loader.isLoading ? "stop.fill" : "play.fill")
                        .foregroundColor(loader.isLoading ? .red : .green)
                }
                .buttonStyle(.bordered)
            }
            .padding()

            ZStack {
                Color.black

                if let frame = loader.currentFrame {
                    #if canImport(UIKit)
                    Image(uiImage: frame)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    #elseif canImport(AppKit)
                    Image(nsImage: frame)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    #endif
                } else if loader.isLoading {
                    ProgressView("连接中...")
                        .foregroundColor(.white)
                } else if let error = loader.error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                        Text("错误: \(error)")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    VStack {
                        Image(systemName: "video.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("点击播放按钮开始")
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onDisappear {
            loader.stopStream()
        }
    }

    private func toggleStream() {
        if loader.isLoading {
            loader.stopStream()
        } else {
            if let url = URL(string: urlString) {
                loader.startStream(url: url)
            }
        }
    }
}

#Preview {
    MJPEGStreamView()
}
