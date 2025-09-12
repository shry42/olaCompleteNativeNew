package com.mfb.field

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.ola.mapsdk.model.OlaLatLng

class OlaMapPlugin(private val activity: Activity) {
    
    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initializeMap" -> {
                val apiKey = call.argument<String>("apiKey")
                if (apiKey != null) {
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "API key is required", null)
                }
            }
            
            // EXISTING METHODS
            "addMarker" -> {
                val markerId = call.argument<String>("markerId")
                val latitude = call.argument<Double>("latitude")
                val longitude = call.argument<Double>("longitude")
                val title = call.argument<String>("title")
                val snippet = call.argument<String>("snippet")
                
                if (markerId != null && latitude != null && longitude != null) {
                    addMarker(markerId, latitude, longitude, title, snippet)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Required arguments missing", null)
                }
            }
            
            "removeMarker" -> {
                val markerId = call.argument<String>("markerId")
                if (markerId != null) {
                    removeMarker(markerId)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Marker ID is required", null)
                }
            }
            
            "zoomToLocation" -> {
                val latitude = call.argument<Double>("latitude")
                val longitude = call.argument<Double>("longitude")
                val zoomLevel = call.argument<Double>("zoomLevel")
                
                if (latitude != null && longitude != null && zoomLevel != null) {
                    zoomToLocation(latitude, longitude, zoomLevel)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Required arguments missing", null)
                }
            }
            
            "showCurrentLocation" -> {
                showCurrentLocation()
                result.success(true)
            }
            
            "hideCurrentLocation" -> {
                hideCurrentLocation()
                result.success(true)
            }
            
            "getCurrentLocation" -> {
                val location = getCurrentLocation()
                if (location != null) {
                    val locationMap = mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude
                    )
                    result.success(locationMap)
                } else {
                    result.success(null)
                }
            }
            
            // NEW NAVIGATION METHODS
            "calculateroute" -> {
                val startLat = call.argument<Double>("startLatitude")
                val startLng = call.argument<Double>("startLongitude")
                val endLat = call.argument<Double>("endLatitude")
                val endLng = call.argument<Double>("endLongitude")
                
                if (startLat != null && startLng != null && endLat != null && endLng != null) {
                    calculateRoute(startLat, startLng, endLat, endLng, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Start and end coordinates required", null)
                }
            }
            
            "startNavigation" -> {
                startNavigation()
                result.success(true)
            }
            
            "stopNavigation" -> {
                stopNavigation()
                result.success(true)
            }
            
            "enableVoiceInstructions" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                enableVoiceInstructions(enabled)
                result.success(true)
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    // EXISTING METHODS
    private fun addMarker(markerId: String, latitude: Double, longitude: Double, title: String?, snippet: String?) {
        OlaMapViewFactory.currentMapView?.addMarker(markerId, latitude, longitude, title, snippet)
    }
    
    private fun removeMarker(markerId: String) {
        OlaMapViewFactory.currentMapView?.removeMarker(markerId)
    }
    
    private fun zoomToLocation(latitude: Double, longitude: Double, zoomLevel: Double) {
        OlaMapViewFactory.currentMapView?.zoomToLocation(latitude, longitude, zoomLevel)
    }
    
    private fun showCurrentLocation() {
        OlaMapViewFactory.currentMapView?.showCurrentLocation()
    }
    
    private fun hideCurrentLocation() {
        OlaMapViewFactory.currentMapView?.hideCurrentLocation()
    }
    
    private fun getCurrentLocation(): OlaLatLng? {
        return OlaMapViewFactory.currentMapView?.getCurrentLocation()
    }
    
    // NEW NAVIGATION METHODS
    private fun calculateRoute(startLat: Double, startLng: Double, endLat: Double, endLng: Double, result: MethodChannel.Result) {
        OlaMapViewFactory.currentMapView?.calculateRoute(startLat, startLng, endLat, endLng, result)
    }
    
    private fun startNavigation() {
        OlaMapViewFactory.currentMapView?.startNavigation()
    }
    
    private fun stopNavigation() {
        OlaMapViewFactory.currentMapView?.stopNavigation()
    }
    
    private fun enableVoiceInstructions(enabled: Boolean) {
        OlaMapViewFactory.currentMapView?.enableVoiceInstructions(enabled)
    }
}