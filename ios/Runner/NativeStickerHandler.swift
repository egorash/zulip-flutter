import UIKit
import Flutter
import AVFoundation

// Each sticker instance is also a FlutterTexture
class StickerInstance: NSObject, FlutterTexture {
    var textureId: Int64  // Changed from let to var
    private let assetPath: String
    private let targetWidth: Int
    private let targetHeight: Int

    private var assetReader: AVAssetReader?
    private var videoTrackOutput: AVAssetReaderTrackOutput?
    private var displayLink: CADisplayLink?
    private var currentPixelBuffer: CVPixelBuffer?
    private var isPlaying = false
    private var isLooping = true
    private var isReleased = false
    private var asset: AVAsset?
    private var videoTrack: AVAssetTrack?

    init(textureId: Int64, assetPath: String, targetWidth: Int, targetHeight: Int) {
        self.textureId = textureId
        self.assetPath = assetPath
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
    }

    // FlutterTexture protocol
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if let buffer = currentPixelBuffer {
            // Notify Flutter that we have a new frame
            NativeStickerHandler.sharedTextureRegistry?.textureFrameAvailable(textureId)
            return Unmanaged.passRetained(buffer)
        }
        return nil
    }

    func initialize() {
        asset = AVAsset(url: URL(fileURLWithPath: assetPath))

        guard let asset = asset else { return }

        videoTrack = asset.tracks(withMediaType: .video).first

        isPlaying = true

        DispatchQueue.main.async { [weak self] in
            self?.startDisplayLink()
        }
    }

    private func startAssetReader() {
        guard let asset = asset, let videoTrack = videoTrack else { return }

        do {
            // Release previous reader resources
            assetReader?.cancelReading()
            assetReader = nil

            // Calculate scaled dimensions (max 256px for stickers)
            let maxDimension: CGFloat = 128
            let naturalSize = videoTrack.naturalSize
            let transform = videoTrack.preferredTransform
            let isPortrait = transform.a == 0 && abs(transform.b) == 1

            var width = isPortrait ? naturalSize.height : naturalSize.width
            var height = isPortrait ? naturalSize.width : naturalSize.height

            // Scale down if needed
            let scale = min(maxDimension / width, maxDimension / height, 1.0)
            let scaledWidth = Int(width * scale)
            let scaledHeight = Int(height * scale)

            // Align to even dimensions (required by some codecs)
            let outputWidth = (scaledWidth / 2) * 2
            let outputHeight = (scaledHeight / 2) * 2

            print("StickerInstance: Original size \(width)x\(height), scaled to \(outputWidth)x\(outputHeight)")

            assetReader = try AVAssetReader(asset: asset)

            let outputSettings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferMetalCompatibilityKey as String: true,
                kCVPixelBufferWidthKey as String: outputWidth,
                kCVPixelBufferHeightKey as String: outputHeight
            ]

            videoTrackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
            videoTrackOutput?.alwaysCopiesSampleData = true

            if let output = videoTrackOutput, assetReader?.canAdd(output) == true {
                assetReader?.add(output)
            }

            assetReader?.startReading()
        } catch {
            print("Failed to start asset reader: \(error)")
        }
    }

    private func startDisplayLink() {
        startAssetReader()
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 30)
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateFrame() {
        guard !isReleased else { return }

        guard isPlaying else { return }

        guard let output = videoTrackOutput else { return }

        // Keep reading frames until we get one or hit end of stream
        var gotFrame = false
        while let sampleBuffer = output.copyNextSampleBuffer() {
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            if pixelBuffer != nil {
                currentPixelBuffer = pixelBuffer
                gotFrame = true
                break
            }
        }

        // If no more frames and looping, restart reader
        if !gotFrame && isLooping {
            assetReader?.cancelReading()
            startAssetReader()
        }
    }

    func play() {
        isPlaying = true
    }

    func pause() {
        isPlaying = false
    }

    func setLooping(_ loop: Bool) {
        isLooping = loop
    }

    func release() {
        isReleased = true
        displayLink?.invalidate()
        displayLink = nil
        assetReader?.cancelReading()
        assetReader = nil
        videoTrackOutput = nil
        // Clear pixel buffer to free memory
        currentPixelBuffer = nil
    }
}

class NativeStickerHandler: NSObject {
    private var stickerInstances: [Int64: StickerInstance] = [:]
    fileprivate static var sharedTextureRegistry: FlutterTextureRegistry?
    fileprivate static var sharedRegistrar: FlutterPluginRegistrar?
    private var textureRegistry: FlutterTextureRegistry? {
        return NativeStickerHandler.sharedTextureRegistry
    }
    private let queue = DispatchQueue(label: "com.zulip.sticker", qos: .userInteractive)

    static func setTextureRegistry(_ registry: FlutterTextureRegistry?) {
        sharedTextureRegistry = registry
    }

    static func setRegistrar(_ registrar: FlutterPluginRegistrar?) {
        sharedRegistrar = registrar
    }

    init(textureRegistry: FlutterTextureRegistry?) {
        super.init()
        if textureRegistry != nil {
            NativeStickerHandler.sharedTextureRegistry = textureRegistry
        }
    }

    private func resolveAssetPath(_ assetPath: String) -> String {
        if let key = NativeStickerHandler.sharedRegistrar?.lookupKey(forAsset: assetPath) {
            if let bundlePath = Bundle.main.path(forResource: key, ofType: nil) {
                return bundlePath
            }
            if let bundlePath = Bundle.main.path(forResource: key, ofType: "mp4") {
                return bundlePath
            }
            let assetKey = "Frameworks/App.framework/flutter_assets/\(key)"
            if let bundlePath = Bundle.main.path(forResource: assetKey, ofType: nil) {
                return bundlePath
            }
        }
        return assetPath
    }

    func createTexture(assetPath: String, width: Int, height: Int, completion: @escaping (Result<Int64, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }

            guard let textureRegistry = self.textureRegistry else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NativeSticker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Texture registry not available"])))
                }
                return
            }

            let resolvedPath = self.resolveAssetPath(assetPath)
            print("NativeStickerHandler: Resolved asset path: \(resolvedPath)")

            // Create the sticker instance first
            // We use a placeholder textureId initially, then register it
            let instance = StickerInstance(
                textureId: 0, // Will be set after registration
                assetPath: resolvedPath,
                targetWidth: width,
                targetHeight: height
            )

            // Register the instance as a texture - this gives us the actual textureId
            let textureId = textureRegistry.register(instance)

            // Update the instance with the correct textureId
            instance.textureId = textureId

            self.stickerInstances[textureId] = instance
            instance.initialize()

            DispatchQueue.main.async {
                completion(.success(textureId))
            }
        }
    }

    func destroyTexture(_ textureId: Int64) {
        queue.async { [weak self] in
            self?.stickerInstances.removeValue(forKey: textureId)?.release()

            DispatchQueue.main.async {
                self?.textureRegistry?.unregisterTexture(textureId)
            }
        }
    }

    func play(_ textureId: Int64) {
        stickerInstances[textureId]?.play()
    }

    func pause(_ textureId: Int64) {
        stickerInstances[textureId]?.pause()
    }

    func setLooping(_ textureId: Int64, loop: Bool) {
        stickerInstances[textureId]?.setLooping(loop)
    }

    // This is called by Flutter when it needs a frame for a specific texture
    // But we have multiple stickers, so we need a different approach
    // The issue is that FlutterTexture.copyPixelBuffer() doesn't tell us WHICH texture
    // So we need a different solution - use the textureId in the key lookup

    func copyPixelBuffer(for textureId: Int64) -> CVPixelBuffer? {
        return stickerInstances[textureId]?.copyPixelBuffer()?.takeRetainedValue()
    }
}

// Add extension to make StickerInstance work as the FlutterTexture
extension StickerInstance {
    // Already conforms to FlutterTexture
}