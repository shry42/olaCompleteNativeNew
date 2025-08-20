package com.example.ola_maps_flutter_app

import android.content.Context
import android.view.View
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

// BASIC IMPORTS ONLY (remove navigation imports for now)
import com.ola.mapsdk.view.OlaMapView as NativeOlaMapView
import com.ola.mapsdk.interfaces.OlaMapCallback
import com.ola.mapsdk.view.OlaMap
import com.ola.mapsdk.model.OlaLatLng
import com.ola.mapsdk.model.OlaMarkerOptions

class OlaMapView(
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?,
    messenger: BinaryMessenger
) : PlatformView {
    
    private val mapView: NativeOlaMapView
    private val methodChannel: MethodChannel
    private var olaMap: OlaMap? = null
    private val markers = mutableMapOf<String, Any>()
    
    init {
        mapView = NativeOlaMapView(context)
        methodChannel = MethodChannel(messenger, "ola_maps_channel")
        
        val apiKey = creationParams?.get("apiKey") as? String
        if (apiKey != null) {
            initializeMap(apiKey)
        }
    }
    
    private fun initializeMap(apiKey: String) {
        mapView.getMap(
            apiKey = apiKey,
            olaMapCallback = object : OlaMapCallback {
                override fun onMapReady(map: OlaMap) {
                    olaMap = map
                    
                    // Automatically show current location
                    map.showCurrentLocation()
                    
                    // Wait for location to be available, then move camera
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        try {
                            val currentLocation = map.getCurrentLocation()
                            if (currentLocation != null) {
                                map.moveCameraToLatLong(currentLocation, 15.0, 1000)
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }, 2000)
                    
                    methodChannel.invokeMethod("onMapReady", null)
                }
                
                override fun onMapError(error: String) {
                    methodChannel.invokeMethod("onMapError", error)
                }
            }
        )
    }
    
    // EXISTING WORKING METHODS
    fun addMarker(markerId: String, latitude: Double, longitude: Double, title: String?, snippet: String?) {
        olaMap?.let { map ->
            val markerOptions = OlaMarkerOptions.Builder()
                .setMarkerId(markerId)
                .setPosition(OlaLatLng(latitude, longitude))
                .setIsIconClickable(true)
                .setIsAnimationEnable(true)
                .setIsInfoWindowDismissOnClick(true)
                .apply {
                    snippet?.let { setSnippet(it) }
                }
                .build()
            
            try {
                val marker = map.addMarker(markerOptions)
                if (marker != null) {
                    markers[markerId] = marker as Any
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    fun removeMarker(markerId: String) {
        markers[markerId]?.let { marker ->
            try {
                val removeMethod = marker.javaClass.getMethod("remove")
                removeMethod.invoke(marker)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        markers.remove(markerId)
    }
    
    fun zoomToLocation(latitude: Double, longitude: Double, zoomLevel: Double) {
        olaMap?.let { map ->
            try {
                map.moveCameraToLatLong(OlaLatLng(latitude, longitude), zoomLevel, 1000)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    fun showCurrentLocation() {
        olaMap?.showCurrentLocation()
    }
    
    fun hideCurrentLocation() {
        olaMap?.hideCurrentLocation()
    }
    
    fun getCurrentLocation(): OlaLatLng? {
        return try {
            olaMap?.getCurrentLocation()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    // SIMPLIFIED NAVIGATION METHODS
    fun calculateRoute(startLat: Double, startLng: Double, endLat: Double, endLng: Double, result: MethodChannel.Result) {
        try {
            // For now, just add markers and simulate route calculation
            addMarker("route_start", startLat, startLng, "Start", "Starting point")
            addMarker("route_end", endLat, endLng, "Destination", "Destination point")
            
            // Zoom to show both points
            val centerLat = (startLat + endLat) / 2
            val centerLng = (startLng + endLng) / 2
            zoomToLocation(centerLat, centerLng, 10.0)
            
            // Simulate route calculation result
            val routeInfo = mapOf(
                "distance" to 45000.0, // 45 km
                "duration" to 2700.0,  // 45 minutes
                "routeFound" to true
            )
            
            result.success(routeInfo)
            methodChannel.invokeMethod("onRouteCalculated", routeInfo)
            
        } catch (e: Exception) {
            e.printStackTrace()
            result.error("CALCULATION_ERROR", "Failed to calculate route: ${e.message}", null)
        }
    }
    
    fun startNavigation() {
        try {
            methodChannel.invokeMethod("onNavigationStarted", null)
            
            // Simulate navigation progress
            simulateNavigation()
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    fun stopNavigation() {
        try {
            // Remove route markers
            removeMarker("route_start")
            removeMarker("route_end")
            
            methodChannel.invokeMethod("onNavigationStopped", null)
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    fun enableVoiceInstructions(enabled: Boolean) {
        try {
            methodChannel.invokeMethod("onVoiceInstructionsChanged", mapOf("enabled" to enabled))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun simulateNavigation() {
        // Simulate navigation progress updates
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            val progressInfo = mapOf(
                "distanceRemaining" to 42000.0,
                "durationRemaining" to 2400.0,
                "distanceTraveled" to 3000.0,
                "fractionTraveled" to 0.1,
                "currentInstruction" to "Continue straight for 2 km"
            )
            
            methodChannel.invokeMethod("onRouteProgress", progressInfo)
        }, 3000)
    }
    
    override fun getView(): View {
        return mapView
    }
    
    override fun dispose() {
        // Clean up
    }
}