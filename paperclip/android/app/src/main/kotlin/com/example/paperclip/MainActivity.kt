package com.example.paperclip // Make sure this matches your package name

import android.content.ContentResolver
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.paperclip/screenshots" // Ensure this matches your Dart code
    private lateinit var channel: MethodChannel
    private var screenshotObserver: ContentObserver? = null

    // Debouncing mechanism
    private val handler = Handler()
    private var lastScreenshotTime: Long = 0
    private val DEBOUNCE_DELAY_MS = 2000L // 2 seconds, adjust as needed

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        channel.setMethodCallHandler { call, result ->
            if (call.method == "startScreenshotListener") {
                startWatchingScreenshots()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startWatchingScreenshots() {
        screenshotObserver = object : ContentObserver(Handler()) { // Keep this handler for ContentObserver's thread
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                uri?.let {
                    // Check if it's likely an image file change
                    if (it.toString().startsWith(MediaStore.Images.Media.EXTERNAL_CONTENT_URI.toString()) ||
                        it.toString().startsWith(MediaStore.Images.Media.INTERNAL_CONTENT_URI.toString())) {

                        val currentTime = System.currentTimeMillis()
                        // If enough time has passed since the last detected screenshot,
                        // or if it's the very first one, trigger the event.
                        if (currentTime - lastScreenshotTime > DEBOUNCE_DELAY_MS) {
                            lastScreenshotTime = currentTime
                            // Post to the main thread to invoke MethodChannel
                            handler.post {
                                channel.invokeMethod("screenshotTaken", null)
                            }
                        } else {
                            println("Screenshot event debounced.")
                        }
                    }
                }
            }
        }
        contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            screenshotObserver!!
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        screenshotObserver?.let {
            contentResolver.unregisterContentObserver(it)
        }
    }
}