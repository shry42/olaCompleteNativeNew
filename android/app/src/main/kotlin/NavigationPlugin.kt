package com.example.ola_maps_flutter_app

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NavigationPlugin(private val activity: Activity) {

    fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            
            // ==========================================
            // PLACES SEARCH METHODS
            // ==========================================
            
            "searchPlaces" -> {
                val query = call.argument<String>("query")
                if (query != null && query.length >= 3) {
                    NavigationViewFactory.currentView?.searchPlaces(query, result)
                } else {
                    result.success(emptyList<Map<String, Any>>())
                }
            }

            "getPlaceDetails" -> {
                val placeId = call.argument<String>("placeId")
                if (placeId != null) {
                    NavigationViewFactory.currentView?.getPlaceDetails(placeId, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Place ID is required", null)
                }
            }

            // ==========================================
            // REAL ROUTE CALCULATION METHODS
            // ==========================================
            
            "calculateRoute" -> {
                val startLat = call.argument<Double>("startLatitude")
                val startLng = call.argument<Double>("startLongitude")
                val endLat = call.argument<Double>("endLatitude")
                val endLng = call.argument<Double>("endLongitude")
                
                if (startLat != null && startLng != null && endLat != null && endLng != null) {
                    NavigationViewFactory.currentView?.calculateRoute(startLat, startLng, endLat, endLng, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Start and end coordinates required", null)
                }
            }
            
            "showRoutePreview" -> {
                NavigationViewFactory.currentView?.showRoutePreview(result)
            }

            // ==========================================
            // NAVIGATION CONTROL METHODS
            // ==========================================
            
            "startNavigationToCoordinates" -> {
                val latitude = call.argument<Double>("latitude")
                val longitude = call.argument<Double>("longitude")
                val destinationName = call.argument<String>("destinationName") ?: "Destination"
                
                if (latitude != null && longitude != null) {
                    NavigationViewFactory.currentView?.startNavigationToCoordinates(latitude, longitude, destinationName, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Latitude and longitude required", null)
                }
            }

            "stopNavigation" -> {
                NavigationViewFactory.currentView?.stopNavigation()
                result.success(true)
            }

            "recenterMap" -> {
                NavigationViewFactory.currentView?.recenterToCurrentLocation()
                result.success(true)
            }

            "clearAllRoutes" -> {
                try {
                     NavigationViewFactory.currentView?.clearAllRoutes()
                     result.success(true)
                 } catch (e: Exception) {
                     result.error("CLEAR_ERROR", "Failed to clear routes: ${e.message}", null)
                    }
            }
            
            "enableVoiceInstructions" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                try {
                    // This would be implemented in NavigationView if SDK supports it
                    result.success(true)
                } catch (e: Exception) {
                    result.error("VOICE_ERROR", "Failed to toggle voice instructions: ${e.message}", null)
                }
            }

            // ==========================================
            // LOCATION AND MAP METHODS
            // ==========================================
            
            "getCurrentLocation" -> {
                try {
                    val location = NavigationViewFactory.currentView?.getCurrentLocation()
                    if (location != null) {
                        result.success(location)
                    } else {
                        result.success(null)
                    }
                } catch (e: Exception) {
                    result.error("LOCATION_ERROR", "Failed to get current location: ${e.message}", null)
                }
            }

            "addMarker" -> {
                val markerId = call.argument<String>("markerId")
                val latitude = call.argument<Double>("latitude")
                val longitude = call.argument<Double>("longitude")
                val title = call.argument<String>("title")
                val snippet = call.argument<String>("snippet")
                
                if (markerId != null && latitude != null && longitude != null) {
                    NavigationViewFactory.currentView?.addMarker(markerId, latitude, longitude, title, snippet)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Required arguments missing", null)
                }
            }

            "removeMarker" -> {
                val markerId = call.argument<String>("markerId")
                if (markerId != null) {
                    NavigationViewFactory.currentView?.removeMarker(markerId)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Marker ID is required", null)
                }
            }

            

            // ==========================================
            // BASIC MAP METHODS
            // ==========================================
            
            "initializeMap" -> {
                val apiKey = call.argument<String>("apiKey")
                if (apiKey != null) {
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "API key is required", null)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }
}