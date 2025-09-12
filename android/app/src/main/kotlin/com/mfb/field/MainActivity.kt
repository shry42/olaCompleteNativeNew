package com.mfb.field

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private lateinit var methodChannel: MethodChannel
    private lateinit var navigationPlugin: NavigationPlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize navigation plugin
        navigationPlugin = NavigationPlugin(this)
        
        // Register the platform view with correct view type
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("ola_navigation_view", NavigationViewFactory(flutterEngine.dartExecutor.binaryMessenger))
        
        // Setup method channel for navigation commands
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ola_maps_channel")
        methodChannel.setMethodCallHandler { call, result ->
            navigationPlugin.onMethodCall(call, result)
            
        }
    }
}