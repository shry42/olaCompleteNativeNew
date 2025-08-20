package com.example.ola_maps_flutter_app

import android.content.Context
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec

class OlaMapViewFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    companion object {
        var currentMapView: OlaMapView? = null
    }
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        val mapView = OlaMapView(context, viewId, creationParams, messenger)
        currentMapView = mapView
        return mapView
    }
}