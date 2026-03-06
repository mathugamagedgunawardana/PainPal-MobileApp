package com.example.painpal

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.painpal.voice.VoiceInputHandler

class MainActivity : FlutterActivity() {
    private lateinit var voiceInputHandler: VoiceInputHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize voice input handler
        voiceInputHandler = VoiceInputHandler(this, this)
        voiceInputHandler.setupMethodChannel(flutterEngine)
    }
}
