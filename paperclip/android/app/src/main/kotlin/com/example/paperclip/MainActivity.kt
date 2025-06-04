package com.example.paperclip

import android.content.ContentResolver
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.provider.MediaStore
import androidx.annotation.NonNull
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Looper
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.paperclip/screenshots"
    private lateinit var channel: MethodChannel
    private var screenshotObserver: ContentObserver? = null

    private val handler = Handler(Looper.getMainLooper())
    private var lastScreenshotTime: Long = 0
    private val DEBOUNCE_DELAY_MS = 2000L

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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationChannel = NotificationChannel(
                "paperclip_monitoring_channel",
                "Paperclip Monitoring",
                NotificationManager.IMPORTANCE_HIGH
            )
            notificationChannel.description = "Background monitoring for Paperclip sessions"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(notificationChannel)
        }
    }

    private fun startWatchingScreenshots() {
        screenshotObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                uri?.let {
                    if (it.toString().startsWith(MediaStore.Images.Media.EXTERNAL_CONTENT_URI.toString()) ||
                        it.toString().startsWith(MediaStore.Images.Media.INTERNAL_CONTENT_URI.toString())) {

                        val currentTime = System.currentTimeMillis()
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