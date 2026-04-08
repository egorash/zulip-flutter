package com.zulip.flutter

import android.content.Context
import android.graphics.SurfaceTexture
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Handler
import android.os.HandlerThread
import android.view.Surface
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentHashMap

class NativeStickerHandler(private val context: Context) {
    private val stickerInstances = ConcurrentHashMap<Int, StickerInstance>()
    private var textureRegistry: TextureRegistry? = null
    private var methodChannel: MethodChannel? = null

    fun register(flutterEngine: FlutterEngine, binaryMessenger: BinaryMessenger) {
        textureRegistry = flutterEngine.renderer
        
        methodChannel = MethodChannel(binaryMessenger, "zulip_native_sticker")
        methodChannel?.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val textureId = call.argument<Int>("textureId")
        
        when (call.method) {
            "create" -> {
                val assetPath = call.argument<String>("assetPath") ?: ""
                val width = call.argument<Int>("width") ?: 100
                val height = call.argument<Int>("height") ?: 100
                
                try {
                    val id = createTexture(assetPath, width, height)
                    result.success(mapOf("textureId" to id))
                } catch (e: Exception) {
                    result.error("CREATE_ERROR", e.message, null)
                }
            }
            "destroy" -> {
                textureId?.let { destroyTexture(it) }
                result.success(null)
            }
            "play" -> {
                textureId?.let { play(it) }
                result.success(null)
            }
            "pause" -> {
                textureId?.let { pause(it) }
                result.success(null)
            }
            "setLooping" -> {
                val loop = call.argument<Boolean>("loop") ?: true
                textureId?.let { setLooping(it, loop) }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun createTexture(assetPath: String, width: Int, height: Int): Int {
        val textureEntry = textureRegistry?.createSurfaceTexture() 
            ?: throw Exception("Texture registry not available")
        
        val textureId = textureEntry.id()
        val surfaceTexture = textureEntry.surfaceTexture()
        
        val instance = StickerInstance(
            context = context,
            textureId = textureId,
            surfaceTexture = surfaceTexture,
            assetPath = assetPath,
            targetWidth = width,
            targetHeight = height
        )
        
        instance.initialize()
        stickerInstances[textureId] = instance
        
        return textureId
    }

    fun destroyTexture(textureId: Int) {
        stickerInstances.remove(textureId)?.release()
    }

    fun play(textureId: Int) {
        stickerInstances[textureId]?.play()
    }

    fun pause(textureId: Int) {
        stickerInstances[textureId]?.pause()
    }

    fun setLooping(textureId: Int, loop: Boolean) {
        stickerInstances[textureId]?.setLooping(loop)
    }

    fun updateTexture(textureId: Int) {
        stickerInstances[textureId]?.updateFrame()
    }
}

class StickerInstance(
    private val context: Context,
    val textureId: Int,
    private val surfaceTexture: SurfaceTexture,
    private val assetPath: String,
    private val targetWidth: Int,
    private val targetHeight: Int
) {
    private var mediaCodec: MediaCodec? = null
    private var mediaExtractor: MediaExtractor? = null
    private var surface: Surface? = null
    private var decoderThread: HandlerThread? = null
    private var decoderHandler: Handler? = null
    private var isPlaying = false
    private var isLooping = true
    private var isReleased = false
    
    private var videoWidth = 0
    private var videoHeight = 0

    fun initialize() {
        try {
            surface = Surface(surfaceTexture)
            
            mediaExtractor = MediaExtractor()
            val afd = context.assets.openFd(assetPath)
            mediaExtractor?.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            
            for (i in 0 until (mediaExtractor?.trackCount ?: 0)) {
                val format = mediaExtractor?.getTrackFormat(i)
                val mime = format?.getString(MediaFormat.KEY_MIME)
                if (mime?.startsWith("video/") == true) {
                    mediaExtractor?.selectTrack(i)
                    videoWidth = format.getInteger(MediaFormat.KEY_WIDTH)
                    videoHeight = format.getInteger(MediaFormat.KEY_HEIGHT)
                    break
                }
            }

            val decodeFormat = MediaFormat.createVideoFormat(
                MediaFormat.MIMETYPE_VIDEO_AVC,
                videoWidth,
                videoHeight
            )
            decodeFormat.setInteger(MediaFormat.KEY_COLOR_FORMAT, 
                MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)

            mediaCodec = MediaCodec.createDecoderByType(
                MediaFormat.MIMETYPE_VIDEO_AVC
            )
            mediaCodec?.configure(decodeFormat, surface, null, 0)
            mediaCodec?.start()

            decoderThread = HandlerThread("StickerDecoder")
            decoderThread?.start()
            decoderHandler = Handler(decoderThread!!.looper)

            surfaceTexture.setDefaultBufferSize(videoWidth, videoHeight)
            
            startDecoding()
            isPlaying = true
        } catch (e: Exception) {
            e.printStackTrace()
            release()
        }
    }

    private fun startDecoding() {
        decoderHandler?.post(object : Runnable {
            override fun run() {
                if (isReleased) return
                
                try {
                    val inputBufferIndex = mediaCodec?.dequeueInputBuffer(10000) ?: -1
                    if (inputBufferIndex >= 0) {
                        val inputBuffer = mediaCodec?.getInputBuffer(inputBufferIndex)
                        val sampleSize = mediaExtractor?.readSampleData(inputBuffer!!, 0)
                        
                        if (sampleSize!! < 0) {
                            if (isLooping) {
                                mediaExtractor?.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
                                mediaCodec?.queueInputBuffer(
                                    inputBufferIndex, 0, 0, 0, 0
                                )
                            } else {
                                mediaCodec?.queueInputBuffer(
                                    inputBufferIndex, 0, 0, 0, 
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM
                                )
                            }
                        } else {
                            val presentationTime = mediaExtractor?.sampleTime ?: 0
                            mediaCodec?.queueInputBuffer(
                                inputBufferIndex, 0, sampleSize, presentationTime, 0
                            )
                            mediaExtractor?.advance()
                        }
                    }

                    val bufferInfo = MediaCodec.BufferInfo()
                    val outputBufferIndex = mediaCodec?.dequeueOutputBuffer(bufferInfo, 10000) ?: -1

                    if (outputBufferIndex >= 0) {
                        mediaCodec?.releaseOutputBuffer(outputBufferIndex, true)
                        
                        if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                            if (isLooping) {
                                mediaExtractor?.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
                            }
                        }
                    }

                    if (!isReleased) {
                        decoderHandler?.post(this)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        })
    }

    fun play() {
        isPlaying = true
    }

    fun pause() {
        isPlaying = false
    }

    fun setLooping(loop: Boolean) {
        isLooping = loop
    }

    fun updateFrame() {
        if (!isReleased) {
            surfaceTexture.updateTexImage()
        }
    }

    fun release() {
        isReleased = true
        try {
            mediaCodec?.stop()
            mediaCodec?.release()
            surface?.release()
            mediaExtractor?.release()
            decoderThread?.quitSafely()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}