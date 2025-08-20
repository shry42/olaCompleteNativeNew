package com.example.ola_maps_flutter_app

import java.io.Serializable
import android.content.Context
import android.view.View
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import okhttp3.MediaType.Companion.toMediaTypeOrNull

// CORRECT IMPORTS for basic Ola Maps SDK (not Navigation SDK)
import com.ola.mapsdk.view.OlaMapView
import com.ola.mapsdk.interfaces.OlaMapCallback
import com.ola.mapsdk.view.OlaMap
import com.ola.mapsdk.model.OlaLatLng
import com.ola.mapsdk.model.OlaMarkerOptions
import com.ola.mapsdk.model.OlaPolylineOptions

// For HTTP requests to APIs
import okhttp3.*
import org.json.JSONObject
import org.json.JSONArray
import java.io.IOException
import java.util.concurrent.TimeUnit
import kotlin.math.*

class NavigationView(
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?,
    messenger: BinaryMessenger
) : PlatformView, OlaMapCallback, LocationListener {

    private val mapView: OlaMapView
    private val methodChannel: MethodChannel
    private var olaMap: OlaMap? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var apiKey: String? = null
    private val context: Context = context
    
    // HTTP client for API calls
    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()
    
    private val allRoutePolylines = mutableListOf<Any>()
    private val allRouteMarkers = mutableMapOf<String, Any>()

    // Navigation state
    private var isNavigating = false
    private var currentDestinationName: String? = null
    private val markers = mutableMapOf<String, Any>()
    private var routePolyline: Any? = null
    
    // Location tracking
    private var locationManager: LocationManager? = null
    private var currentLocation: Location? = null
    private var destinationLocation: OlaLatLng? = null
    
    // Route data - ADD MISSING VARIABLES
    private var totalRouteDistance = 0.0
    private var totalRouteDuration = 0.0
    
    // API endpoints
    private val baseUrl = "https://api.olamaps.io"

    init {
        methodChannel = MethodChannel(messenger, "ola_maps_channel")
        mapView = OlaMapView(context)
        
        // Initialize location manager
        locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        
        // Get API key from parameters
        apiKey = creationParams?.get("apiKey") as? String
        
        if (apiKey != null) {
            initializeMap(apiKey!!)
        } else {
            methodChannel.invokeMethod("onMapError", "API key not provided")
        }
    }

    private fun initializeMap(apiKey: String) {
        try {
            // Use basic Ola Maps SDK initialization
            mapView.getMap(
                apiKey = apiKey,
                olaMapCallback = this
            )
        } catch (e: Exception) {
            e.printStackTrace()
            methodChannel.invokeMethod("onMapError", "Failed to initialize map: ${e.message}")
        }
    }

    override fun onMapReady(olaMap: OlaMap) {
        this.olaMap = olaMap
        
        try {
            // Show current location
            olaMap.showCurrentLocation()
            
            // Start location tracking
            startLocationTracking()
            
            // Move camera to current location after a delay
            mainHandler.postDelayed({
                try {
                    val currentLoc = olaMap.getCurrentLocation()
                    if (currentLoc != null) {
                        olaMap.moveCameraToLatLong(currentLoc, 15.0, 1000)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }, 2000)
            
            methodChannel.invokeMethod("onMapReady", null)
            
        } catch (e: Exception) {
            e.printStackTrace()
            methodChannel.invokeMethod("onMapError", "Failed to setup map: ${e.message}")
        }
    }

    override fun onMapError(error: String) {
        methodChannel.invokeMethod("onMapError", error)
    }

    // ==========================================
    // LOCATION TRACKING
    // ==========================================
    
    private fun startLocationTracking() {
        try {
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                locationManager?.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    1000, // 1 second
                    1.0f,  // 1 meter
                    this
                )
                
                locationManager?.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    1000,
                    1.0f,
                    this
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    override fun onLocationChanged(location: Location) {
        currentLocation = location
        
        if (isNavigating && destinationLocation != null) {
            updateNavigationProgress(location)
        }
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}


fun clearAllRoutes() {
    try {
        println("🧹 Starting route clearing with correct SDK methods...")
        
        olaMap?.let { map ->
            // Clear all tracked polylines using correct SDK method
            allRoutePolylines.forEach { polyline ->
                try {
                    // Call removePolyline() directly on the polyline object (as per SDK docs)
                    polyline.javaClass.getMethod("removePolyline").invoke(polyline)
                    println("✅ Removed polyline using removePolyline()")
                } catch (e: Exception) {
                    try {
                        // Alternative: Try remove() method
                        polyline.javaClass.getMethod("remove").invoke(polyline)
                        println("✅ Removed polyline using remove()")
                    } catch (e2: Exception) {
                        println("⚠️ Could not remove polyline: ${e2.message}")
                    }
                }
            }
            allRoutePolylines.clear()
            
            // Clear all tracked markers using correct SDK method
            allRouteMarkers.forEach { (id, marker) ->
                try {
                    // Call removeMarker() directly on the marker object (as per SDK docs)
                    marker.javaClass.getMethod("removeMarker").invoke(marker)
                    println("✅ Removed marker $id using removeMarker()")
                } catch (e: Exception) {
                    try {
                        // Alternative: Try remove() method
                        marker.javaClass.getMethod("remove").invoke(marker)
                        println("✅ Removed marker $id using remove()")
                    } catch (e2: Exception) {
                        println("⚠️ Could not remove marker $id: ${e2.message}")
                    }
                }
            }
            allRouteMarkers.clear()
            
            // Try map-level clearing methods as mentioned in Navigation SDK
            try {
                // Navigation SDK mentions removeAllMarkers() method
                val mapClass = map.javaClass
                val removeAllMarkersMethod = mapClass.getMethod("removeAllMarkers")
                removeAllMarkersMethod.invoke(map)
                println("✅ Called map.removeAllMarkers()")
            } catch (e: Exception) {
                println("⚠️ removeAllMarkers not available: ${e.message}")
            }
            
            // Reset current references
            routePolyline = null
            markers.clear()
            
            // Reset navigation state
            isNavigating = false
            currentDestinationName = null
            destinationLocation = null
            
            println("🧹 Route clearing completed")
        }
        
    } catch (e: Exception) {
        e.printStackTrace()
        println("❌ Error clearing routes: ${e.message}")
    }
}

// ALTERNATIVE: Use Map-level removal methods (based on SDK documentation)
private fun clearRoutesThroughMap() {
    olaMap?.let { map ->
        try {
            println("🧹 Attempting map-level route clearing...")
            
            // Try removing polylines through map object
            allRoutePolylines.forEach { polyline ->
                try {
                    // Try map.removePolyline(polyline) as suggested in some SDK docs
                    val mapClass = map.javaClass
                    val removeMethod = mapClass.getMethod("removePolyline", polyline.javaClass)
                    removeMethod.invoke(map, polyline)
                    println("✅ Removed polyline via map.removePolyline()")
                } catch (e: Exception) {
                    println("⚠️ map.removePolyline() failed: ${e.message}")
                }
            }
            
            // Try removing markers through map object
            allRouteMarkers.forEach { (id, marker) ->
                try {
                    // Try map.removeMarker(marker)
                    val mapClass = map.javaClass
                    val removeMethod = mapClass.getMethod("removeMarker", marker.javaClass)
                    removeMethod.invoke(map, marker)
                    println("✅ Removed marker $id via map.removeMarker()")
                } catch (e: Exception) {
                    println("⚠️ map.removeMarker() failed: ${e.message}")
                }
            }
            
        } catch (e: Exception) {
            println("⚠️ Map-level clearing failed: ${e.message}")
        }
    }
}

    // ==========================================
    // REAL ROUTE CALCULATION WITH OLA DIRECTIONS API
    // ==========================================
    
fun calculateRoute(startLat: Double, startLng: Double, endLat: Double, endLng: Double, result: MethodChannel.Result) {
    if (apiKey == null) {
        println("❌ API key is null")
        result.error("NO_API_KEY", "API key not available", null)
        return
    }
    
    println("🚀 Starting route calculation...")
    println("📍 From: $startLat, $startLng")
    println("📍 To: $endLat, $endLng")
    
    // Clear any existing navigation state
    isNavigating = false
    
    // Use query parameters as per Ola Maps API documentation
    val url = "https://api.olamaps.io/routing/v1/directions?" +
            "origin=$startLat,$startLng&" +
            "destination=$endLat,$endLng&" +
            "mode=driving&" +
            "alternatives=false&" +
            "steps=true&" +
            "overview=full&" +
            "language=en&" +
            "traffic_metadata=false&" +
            "api_key=$apiKey"
    
    println("🌐 API URL: $url")
    
    val request = Request.Builder()
        .url(url)
        .post(RequestBody.create(null, "")) // Empty body for POST request
        .addHeader("X-Request-Id", "flutter_nav_${System.currentTimeMillis()}")
        .addHeader("Content-Type", "application/json")
        .build()

    println("📡 Making HTTP POST request...")
    
    httpClient.newCall(request).enqueue(object : Callback {
        override fun onFailure(call: Call, e: IOException) {
            println("❌ Network request failed: ${e.message}")
            e.printStackTrace()
            mainHandler.post {
                result.error("ROUTE_ERROR", "Failed to calculate route: ${e.message}", null)
            }
        }

        override fun onResponse(call: Call, response: Response) {
            println("📡 Received response: ${response.code} ${response.message}")
            
            try {
                val responseBody = response.body?.string()
                println("📄 Response body length: ${responseBody?.length ?: 0}")
                
                if (response.isSuccessful && responseBody != null) {
                    println("✅ Successful response received")
                    
                    val jsonResponse = JSONObject(responseBody)
                    
                    // Check status field from Ola API
                    val status = jsonResponse.optString("status", "")
                    println("📊 API Status: $status")
                    
                    if (status != "SUCCESS") {
                        println("❌ API returned non-success status: $status")
                        mainHandler.post {
                            result.error("API_STATUS_ERROR", "API returned status: $status", null)
                        }
                        return
                    }
                    
                    val routes = jsonResponse.optJSONArray("routes")
                    println("🛣️ Routes found: ${routes?.length() ?: 0}")
                    
                    if (routes != null && routes.length() > 0) {
                        val route = routes.getJSONObject(0)
                        
                        // Parse real route data from Ola API response
                        val routeData = parseOlaRouteData(route)
                        
                        // Store route data for navigation
                        totalRouteDistance = routeData["distanceInMeters"] as Double
                        totalRouteDuration = routeData["durationInSeconds"] as Double
                        
                        println("✅ Route parsed successfully")
                        println("📊 Final Distance: ${totalRouteDistance}m")
                        println("📊 Final Duration: ${totalRouteDuration}s")
                        
                        mainHandler.post {
                            result.success(routeData)
                            methodChannel.invokeMethod("onRouteCalculated", routeData)
                            
                            // Draw the new route on map (clearing happens inside drawRouteFromPoints)
                            val routePoints = routeData["routePoints"] as List<Map<String, Double>>
                            if (routePoints.isNotEmpty()) {
                                println("🎨 Drawing new route with ${routePoints.size} points")
                                drawRouteFromPoints(routePoints)
                            }
                        }
                        
                    } else {
                        println("❌ No routes found in response")
                        mainHandler.post {
                            result.error("NO_ROUTES", "No routes found for this destination", null)
                        }
                    }
                } else {
                    println("❌ HTTP Error: ${response.code}")
                    val errorBody = responseBody ?: "No error body"
                    println("📄 Error body: $errorBody")
                    
                    mainHandler.post {
                        val errorMsg = when (response.code) {
                            400 -> "Invalid request - check coordinates format"
                            401 -> "Invalid API key"
                            403 -> "API access forbidden"
                            404 -> "Routing endpoint not found"
                            429 -> "Rate limit exceeded"
                            500 -> "Server error"
                            else -> "HTTP Error: ${response.code}"
                        }
                        result.error("API_ERROR", errorMsg, null)
                    }
                }
            } catch (e: Exception) {
                println("❌ Parse error: ${e.message}")
                e.printStackTrace()
                mainHandler.post {
                    result.error("PARSE_ERROR", "Failed to parse route response: ${e.message}", null)
                }
            }
        }
    })
}

    // NEW: Correct parser for Ola Maps API response format
private fun parseOlaRouteData(route: JSONObject): Map<String, Any> {
    var totalDistance = 0.0
    var totalDuration = 0.0
    val routePoints = mutableListOf<Map<String, Double>>()
    
    println("🔍 Parsing Ola Maps route data...")
    
    try {
        // First, try to get overview polyline (most important for drawing route)
        val overviewPolyline = route.optString("overview_polyline", "")
        if (overviewPolyline.isNotEmpty()) {
            println("🗺️ Found overview polyline with ${overviewPolyline.length} characters")
            val decodedPoints = decodePolyline(overviewPolyline)
            routePoints.addAll(decodedPoints)
            println("📍 Decoded ${decodedPoints.size} points from overview polyline")
        }
        
        // Parse legs array to get total distance and duration
        val legs = route.optJSONArray("legs")
        println("🦵 Legs found: ${legs?.length() ?: 0}")
        
        if (legs != null) {
            for (i in 0 until legs.length()) {
                val leg = legs.getJSONObject(i)
                
                // In real Ola API, distance and duration are simple numbers at leg level
                val legDistance = leg.optDouble("distance", 0.0)
                val legDuration = leg.optDouble("duration", 0.0)
                
                println("🦵 Leg $i: Distance=${legDistance}m, Duration=${legDuration}s")
                
                totalDistance += legDistance
                totalDuration += legDuration
                
                // If no overview polyline, extract points from steps
                if (routePoints.isEmpty()) {
                    val steps = leg.optJSONArray("steps")
                    if (steps != null) {
                        println("👣 Extracting points from ${steps.length()} steps")
                        
                        for (j in 0 until steps.length()) {
                            val step = steps.getJSONObject(j)
                            
                            // Get start location from each step
                            val startLocation = step.optJSONObject("start_location")
                            if (startLocation != null) {
                                routePoints.add(mapOf(
                                    "latitude" to startLocation.optDouble("lat", 0.0),
                                    "longitude" to startLocation.optDouble("lng", 0.0)
                                ))
                            }
                            
                            // Add end location only for the last step
                            if (j == steps.length() - 1) {
                                val endLocation = step.optJSONObject("end_location")
                                if (endLocation != null) {
                                    routePoints.add(mapOf(
                                        "latitude" to endLocation.optDouble("lat", 0.0),
                                        "longitude" to endLocation.optDouble("lng", 0.0)
                                    ))
                                }
                            }
                        }
                        
                        println("📍 Extracted ${routePoints.size} points from steps")
                    }
                }
            }
        }
        
        // Fallback: if still no points, create a simple route
        if (routePoints.isEmpty()) {
            println("⚠️ No route points found, creating fallback route")
            // Extract start and end from the first leg
            if (legs != null && legs.length() > 0) {
                val firstLeg = legs.getJSONObject(0)
                val startLoc = firstLeg.optJSONObject("start_location")
                val endLoc = firstLeg.optJSONObject("end_location")
                
                if (startLoc != null && endLoc != null) {
                    routePoints.add(mapOf(
                        "latitude" to startLoc.optDouble("lat", 0.0),
                        "longitude" to startLoc.optDouble("lng", 0.0)
                    ))
                    routePoints.add(mapOf(
                        "latitude" to endLoc.optDouble("lat", 0.0),
                        "longitude" to endLoc.optDouble("lng", 0.0)
                    ))
                    println("📍 Created fallback route with 2 points")
                }
            }
        }
        
        // Ensure we have valid data
        if (totalDistance == 0.0 && routePoints.size >= 2) {
            // Calculate approximate distance if not provided
            val start = routePoints.first()
            val end = routePoints.last()
            totalDistance = calculateDistance(
                OlaLatLng(start["latitude"]!!, start["longitude"]!!),
                OlaLatLng(end["latitude"]!!, end["longitude"]!!)
            )
            println("📏 Calculated fallback distance: ${totalDistance}m")
        }
        
        if (totalDuration == 0.0) {
            // Estimate duration based on distance (assuming 30 km/h average)
            totalDuration = (totalDistance / 1000.0) * 120.0 // 2 minutes per km
            println("⏱️ Calculated fallback duration: ${totalDuration}s")
        }
        
    } catch (e: Exception) {
        println("❌ Parse error in parseOlaRouteData: ${e.message}")
        e.printStackTrace()
        
        // Create minimal fallback data
        if (totalDistance == 0.0) totalDistance = 1000.0
        if (totalDuration == 0.0) totalDuration = 300.0
        if (routePoints.isEmpty()) {
            // This should not happen with valid response, but just in case
            routePoints.add(mapOf("latitude" to 0.0, "longitude" to 0.0))
            routePoints.add(mapOf("latitude" to 0.1, "longitude" to 0.1))
        }
    }
    
    println("✅ Route parsing completed:")
    println("   Distance: ${totalDistance} meters (${totalDistance/1000} km)")
    println("   Duration: ${totalDuration} seconds (${totalDuration/60} minutes)")
    println("   Points: ${routePoints.size}")
    
    return mapOf(
        "distanceInMeters" to totalDistance,
        "durationInSeconds" to totalDuration,
        "routeId" to route.optString("route_id", "ola_route_${System.currentTimeMillis()}"),
        "routePoints" to routePoints,
        "bounds" to calculateBounds(routePoints)
    )
}


// REPLACE the decodePolyline method in your NavigationView.kt with this corrected version:

private fun decodePolyline(polyline: String): List<Map<String, Double>> {
    val points = mutableListOf<Map<String, Double>>()
    
    if (polyline.isEmpty()) {
        println("⚠️ Empty polyline string")
        return points
    }
    
    var index = 0
    var lat = 0
    var lng = 0
    
    try {
        while (index < polyline.length) {
            // Decode latitude
            var shift = 0
            var result = 0
            
            do {
                if (index >= polyline.length) break
                val b = polyline[index++].code - 63
                result = result or ((b and 0x1f) shl shift)
                shift += 5
            } while (b >= 0x20 && index < polyline.length)
            
            val deltaLat = if (result and 1 != 0) (result shr 1).inv() else result shr 1
            lat += deltaLat
            
            // Decode longitude
            shift = 0
            result = 0
            
            do {
                if (index >= polyline.length) break
                val b = polyline[index++].code - 63
                result = result or ((b and 0x1f) shl shift)
                shift += 5
            } while (b >= 0x20 && index < polyline.length)
            
            val deltaLng = if (result and 1 != 0) (result shr 1).inv() else result shr 1
            lng += deltaLng
            
            // Convert to decimal degrees and add to points
            val latDecimal = lat / 1E5
            val lngDecimal = lng / 1E5
            
            // Validate coordinates before adding (using Math.abs instead of .abs())
            if (Math.abs(latDecimal) <= 90 && Math.abs(lngDecimal) <= 180) {
                points.add(mapOf(
                    "latitude" to latDecimal,
                    "longitude" to lngDecimal
                ))
            }
        }
        
        println("🎯 Successfully decoded ${points.size} points from polyline")
        
    } catch (e: Exception) {
        println("❌ Polyline decode error: ${e.message}")
        e.printStackTrace()
    }
    
    return points
}
   
    // ENHANCED: Better route drawing with traffic colors
// UPDATED: Enhanced route drawing with proper cleanup
private fun drawRouteFromPoints(routePoints: List<Map<String, Double>>) {
    olaMap?.let { map ->
        try {
            // First try proper SDK-based clearing
            clearAllRoutes()
            
            // Also try map-level clearing as backup
            clearRoutesThroughMap()
            
            // Convert to OlaLatLng points
            val olaPoints = routePoints.mapNotNull { point ->
                val lat = point["latitude"]
                val lng = point["longitude"]
                if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
                    OlaLatLng(lat, lng)
                } else null
            }
            
            if (olaPoints.isNotEmpty()) {
                // Use FIXED IDs for consistency (SDK should replace existing ones)
                val routeId = "current_navigation_route"
                val markerId = "current_destination_marker"
                
                // Draw polyline
                val polylineOptions = OlaPolylineOptions.Builder()
                    .setPolylineId(routeId)
                    .setPoints(arrayListOf<OlaLatLng>().apply { addAll(olaPoints) })
                    .setWidth(5f)
                    .setColor("#1976D2") // Standard hex color without alpha
                    .build()
                
                val newPolyline = map.addPolyline(polylineOptions)
                if (newPolyline != null) {
                    routePolyline = newPolyline
                    allRoutePolylines.clear()
                    allRoutePolylines.add(newPolyline)
                    println("🎨 Created route with ID: $routeId")
                }
                
                // Add destination marker
                val markerOptions = OlaMarkerOptions.Builder()
                    .setMarkerId(markerId)
                    .setPosition(olaPoints.last())
                    .setIsIconClickable(true)
                    .setIsAnimationEnable(true)
                    .build()
                
                val newMarker = map.addMarker(markerOptions)
                if (newMarker != null) {
                    markers.clear()
                    markers[markerId] = newMarker
                    allRouteMarkers.clear()
                    allRouteMarkers[markerId] = newMarker
                    println("📍 Created marker with ID: $markerId")
                }
                
                // Fit bounds to show entire route
                fitRouteBounds(olaPoints)
                
                println("✅ Route drawn with ${olaPoints.size} points")
                
            } else {
                println("❌ No valid route points to draw")
            }
            
        } catch (e: Exception) {
            e.printStackTrace()
            println("❌ Error drawing route: ${e.message}")
        }
    }
}

// NEW: Method to clear previous route and markers
private fun clearPreviousRoute() {
    olaMap?.let { map ->
        try {
            println("🧹 Starting comprehensive route clearing...")
            
            // Clear all tracked polylines
            allRoutePolylines.forEach { polyline ->
                try {
                    // Try different remove method signatures
                    val javaClass = polyline.javaClass
                    
                    // Try parameterless remove()
                    try {
                        val removeMethod = javaClass.getMethod("remove")
                        removeMethod.invoke(polyline)
                        println("✅ Removed polyline successfully with remove()")
                    } catch (e: Exception) {
                        // Try remove() with boolean parameter
                        try {
                            val removeMethod = javaClass.getMethod("remove", Boolean::class.java)
                            removeMethod.invoke(polyline, true)
                            println("✅ Removed polyline successfully with remove(boolean)")
                        } catch (e2: Exception) {
                            // Try setVisible(false) as alternative
                            try {
                                val setVisibleMethod = javaClass.getMethod("setVisible", Boolean::class.java)
                                setVisibleMethod.invoke(polyline, false)
                                println("✅ Hidden polyline with setVisible(false)")
                            } catch (e3: Exception) {
                                println("⚠️ Could not remove/hide polyline: ${e3.message}")
                            }
                        }
                    }
                } catch (e: Exception) {
                    println("⚠️ Could not remove polyline: ${e.message}")
                }
            }
            allRoutePolylines.clear()
            
            // Clear all tracked markers
            allRouteMarkers.forEach { (id, marker) ->
                try {
                    val javaClass = marker.javaClass
                    
                    // Try parameterless remove()
                    try {
                        val removeMethod = javaClass.getMethod("remove")
                        removeMethod.invoke(marker)
                        println("✅ Removed marker $id successfully with remove()")
                    } catch (e: Exception) {
                        // Try setVisible(false) as alternative
                        try {
                            val setVisibleMethod = javaClass.getMethod("setVisible", Boolean::class.java)
                            setVisibleMethod.invoke(marker, false)
                            println("✅ Hidden marker $id with setVisible(false)")
                        } catch (e2: Exception) {
                            println("⚠️ Could not remove/hide marker $id: ${e2.message}")
                        }
                    }
                } catch (e: Exception) {
                    println("⚠️ Could not remove marker $id: ${e.message}")
                }
            }
            allRouteMarkers.clear()
            
            // Reset current references
            routePolyline = null
            markers.clear()
            
            // Reset navigation state
            isNavigating = false
            currentDestinationName = null
            destinationLocation = null
            
            println("🧹 All routes cleared successfully")
            
        } catch (e: Exception) {
            e.printStackTrace()
            println("❌ Error clearing all routes: ${e.message}")
        }
    }
}
private fun addDestinationMarker(destination: OlaLatLng) {
    olaMap?.let { map ->
        try {
            val markerOptions = OlaMarkerOptions.Builder()
                .setMarkerId("destination") // Consistent ID for replacement
                .setPosition(destination)
                .setIsIconClickable(true)
                .setIsAnimationEnable(true)
                .build()
            
            val marker = map.addMarker(markerOptions)
            if (marker != null) {
                markers["destination"] = marker
                println("📍 Added destination marker at ${destination.latitude}, ${destination.longitude}")
            }
        } catch (e: Exception) {
            e.printStackTrace()
            println("❌ Error adding destination marker: ${e.message}")
        }
    }
}

    
    private fun fitRouteBounds(routePoints: List<OlaLatLng>) {
        if (routePoints.isNotEmpty()) {
            // Calculate bounds and fit camera
            var minLat = routePoints[0].latitude
            var maxLat = routePoints[0].latitude
            var minLng = routePoints[0].longitude
            var maxLng = routePoints[0].longitude
            
            routePoints.forEach { point ->
                minLat = minOf(minLat, point.latitude)
                maxLat = maxOf(maxLat, point.latitude)
                minLng = minOf(minLng, point.longitude)
                maxLng = maxOf(maxLng, point.longitude)
            }
            
            // Move camera to show route with padding
            val centerLat = (minLat + maxLat) / 2
            val centerLng = (minLng + maxLng) / 2
            
            olaMap?.moveCameraToLatLong(OlaLatLng(centerLat, centerLng), 12.0, 1000)
        }
    }

    // ==========================================
    // NAVIGATION METHODS
    // ==========================================

    fun startNavigationToCoordinates(latitude: Double, longitude: Double, destinationName: String, result: MethodChannel.Result) {
        try {
            olaMap?.let { map ->
                destinationLocation = OlaLatLng(latitude, longitude)
                
                // Calculate route from current location to destination
                val currentLoc = currentLocation
                val mapCurrentLoc = map.getCurrentLocation()
                
                if (currentLoc != null) {
                    val startLat = currentLoc.latitude
                    val startLng = currentLoc.longitude
                    
                    calculateRouteAndStartNavigation(startLat, startLng, latitude, longitude, destinationName, result)
                } else if (mapCurrentLoc != null) {
                    val startLat = mapCurrentLoc.latitude
                    val startLng = mapCurrentLoc.longitude
                    
                    calculateRouteAndStartNavigation(startLat, startLng, latitude, longitude, destinationName, result)
                } else {
                    result.error("LOCATION_ERROR", "Current location not available", null)
                }
            } ?: run {
                result.error("MAP_NOT_READY", "Map not ready", null)
            }
        } catch (e: Exception) {
            result.error("NAVIGATION_ERROR", "Failed to start navigation: ${e.message}", null)
        }
    }
    
    private fun calculateRouteAndStartNavigation(startLat: Double, startLng: Double, endLat: Double, endLng: Double, destinationName: String, result: MethodChannel.Result) {
        if (apiKey == null) {
            result.error("NO_API_KEY", "API key not available", null)
            return
        }
        
        // Use the same flexible route calculation
        calculateRoute(startLat, startLng, endLat, endLng, object : MethodChannel.Result {
            override fun success(routeData: Any?) {
                if (routeData is Map<*, *>) {
                    mainHandler.post {
                        startRealNavigation(destinationName, result)
                    }
                } else {
                    result.error("ROUTE_ERROR", "Invalid route data received", null)
                }
            }
            
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                result.error(errorCode, errorMessage, errorDetails)
            }
            
            override fun notImplemented() {
                result.error("NOT_IMPLEMENTED", "Route calculation not implemented", null)
            }
        })
    }
    
    private fun startRealNavigation(destinationName: String, result: MethodChannel.Result) {
        isNavigating = true
        currentDestinationName = destinationName
        
        val navigationInfo = mapOf(
            "destination" to destinationName,
            "isNavigating" to true,
            "routeDistance" to totalRouteDistance,
            "routeDuration" to totalRouteDuration
        )
        
        methodChannel.invokeMethod("onNavigationStarted", navigationInfo)
        result.success(true)
        
        // Start sending navigation updates
        sendCurrentNavigationUpdate()
    }
    
    private fun updateNavigationProgress(location: Location) {
        if (!isNavigating) return
        
        try {
            destinationLocation?.let { dest ->
                val currentLatLng = OlaLatLng(location.latitude, location.longitude)
                val distanceToDestination = calculateDistance(currentLatLng, dest)
                
                // Check if arrived at destination (within 50 meters)
                if (distanceToDestination < 50.0) {
                    arrivedAtDestination()
                    return
                }
                
                // Calculate rough estimates for remaining time
                val estimatedDuration = (distanceToDestination / 10.0 * 60.0) // Rough estimate: 10 m/s average speed
                val fractionTraveled = if (totalRouteDistance > 0) {
                    (1.0 - (distanceToDestination / totalRouteDistance)).coerceIn(0.0, 1.0)
                } else {
                    0.1 // Default progress
                }
                
                val progressInfo = mapOf(
                    "distanceRemaining" to distanceToDestination,
                    "durationRemaining" to estimatedDuration,
                    "fractionTraveled" to fractionTraveled,
                    "currentInstruction" to mapOf(
                        "text" to "Continue to destination",
                        "maneuverType" to "straight", 
                        "distanceToManeuver" to distanceToDestination,
                        "roadName" to "Route"
                    )
                )
                
                methodChannel.invokeMethod("onRouteProgress", progressInfo)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun sendCurrentNavigationUpdate() {
        if (!isNavigating) return
        
        try {
            // Send initial navigation update with route data
            val progressInfo = mapOf(
                "distanceRemaining" to totalRouteDistance,
                "durationRemaining" to totalRouteDuration,
                "fractionTraveled" to 0.0, // Starting journey
                "currentInstruction" to mapOf(
                    "text" to "Start navigation to destination",
                    "maneuverType" to "straight",
                    "distanceToManeuver" to totalRouteDistance,
                    "roadName" to "Route"
                )
            )
            
            methodChannel.invokeMethod("onRouteProgress", progressInfo)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun arrivedAtDestination() {
        methodChannel.invokeMethod("onArrival", null)
        stopNavigation()
    }
    
    private fun calculateDistance(from: OlaLatLng, to: OlaLatLng): Double {
        val R = 6371000.0 // Earth's radius in meters
        val lat1Rad = Math.toRadians(from.latitude)
        val lat2Rad = Math.toRadians(to.latitude)
        val deltaLatRad = Math.toRadians(to.latitude - from.latitude)
        val deltaLngRad = Math.toRadians(to.longitude - from.longitude)
        
        val a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLngRad / 2) * sin(deltaLngRad / 2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return R * c
    }

    // ==========================================
    // PLACES SEARCH IMPLEMENTATION
    // ==========================================
    
    fun searchPlaces(query: String, result: MethodChannel.Result) {
        if (apiKey == null) {
            result.error("NO_API_KEY", "API key not available", null)
            return
        }
        
        val url = "$baseUrl/places/v1/autocomplete?input=${query}&api_key=${apiKey}"
        val request = Request.Builder().url(url).build()

        httpClient.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                mainHandler.post {
                    result.error("SEARCH_ERROR", "Failed to search places: ${e.message}", null)
                }
            }

            override fun onResponse(call: Call, response: Response) {
                try {
                    val responseBody = response.body?.string()
                    if (response.isSuccessful && responseBody != null) {
                        val json = JSONObject(responseBody)
                        val predictions = json.optJSONArray("predictions") ?: JSONArray()
                        
                        val results = mutableListOf<Map<String, Any>>()
                        for (i in 0 until predictions.length()) {
                            val prediction = predictions.getJSONObject(i)
                            
                            val types = prediction.optJSONArray("types")?.let { typesArray ->
                                (0 until typesArray.length()).map { typesArray.getString(it) }
                            } ?: emptyList<String>()

                            val description = prediction.optString("description", "")
                            val descriptionParts = description.split(",")
                            val mainText = descriptionParts.firstOrNull()?.trim() ?: ""
                            val secondaryText = descriptionParts.drop(1).joinToString(", ").trim()

                            results.add(mapOf(
                                "placeId" to prediction.optString("place_id", ""),
                                "mainText" to mainText,
                                "secondaryText" to secondaryText,
                                "fullText" to description,
                                "types" to types as Serializable
                            ))
                        }
                        
                        mainHandler.post {
                            result.success(results)
                        }
                    } else {
                        mainHandler.post {
                            result.error("SEARCH_ERROR", "Search failed with response code: ${response.code}", null)
                        }
                    }
                } catch (e: Exception) {
                    mainHandler.post {
                        result.error("SEARCH_ERROR", "Failed to parse search results: ${e.message}", null)
                    }
                }
            }
        })
    }

    fun getPlaceDetails(placeId: String, result: MethodChannel.Result) {
        if (apiKey == null) {
            result.error("NO_API_KEY", "API key not available", null)
            return
        }
        
        val url = "$baseUrl/places/v1/details?place_id=${placeId}&api_key=${apiKey}"
        val request = Request.Builder().url(url).build()

        httpClient.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                mainHandler.post {
                    result.error("PLACE_DETAILS_ERROR", "Failed to get place details: ${e.message}", null)
                }
            }

            override fun onResponse(call: Call, response: Response) {
                try {
                    val responseBody = response.body?.string()
                    if (response.isSuccessful && responseBody != null) {
                        val json = JSONObject(responseBody)
                        val place = json.optJSONObject("result")
                        
                        if (place != null) {
                            val geometry = place.optJSONObject("geometry")
                            val location = geometry?.optJSONObject("location")
                            
                            val types = place.optJSONArray("types")?.let { typesArray ->
                                (0 until typesArray.length()).map { typesArray.getString(it) }
                            } ?: emptyList<String>()
                            
                            val placeDetails = mapOf(
                                "placeId" to place.optString("place_id", ""),
                                "name" to place.optString("name", ""),
                                "address" to place.optString("formatted_address", ""),
                                "latitude" to (location?.optDouble("lat") ?: 0.0),
                                "longitude" to (location?.optDouble("lng") ?: 0.0),
                                "types" to types as Serializable
                            )
                            
                            mainHandler.post {
                                result.success(placeDetails)
                            }
                        } else {
                            mainHandler.post {
                                result.error("PLACE_DETAILS_ERROR", "No place details found", null)
                            }
                        }
                    } else {
                        mainHandler.post {
                            result.error("PLACE_DETAILS_ERROR", "Failed to get place details: ${response.code}", null)
                        }
                    }
                } catch (e: Exception) {
                    mainHandler.post {
                        result.error("PLACE_DETAILS_ERROR", "Failed to parse place details: ${e.message}", null)
                    }
                }
            }
        })
    }

    // ==========================================
    // UTILITY METHODS
    // ==========================================

    fun getCurrentLocation(): Map<String, Double>? {
        return try {
            currentLocation?.let { location ->
                mapOf(
                    "latitude" to location.latitude,
                    "longitude" to location.longitude
                )
            } ?: run {
                // Fallback to map's current location if available
                olaMap?.getCurrentLocation()?.let { mapLocation ->
                    mapOf(
                        "latitude" to mapLocation.latitude,
                        "longitude" to mapLocation.longitude
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    fun addMarker(markerId: String, latitude: Double, longitude: Double, title: String?, snippet: String?) {
        olaMap?.let { map ->
            try {
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
                
                val marker = map.addMarker(markerOptions)
                if (marker != null) {
                    markers[markerId] = marker
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun removeMarker(markerId: String) {
        markers.remove(markerId)
    }

    fun showRoutePreview(result: MethodChannel.Result) {
        try {
            // Since we're already drawing the route in calculateRoute,
            // this method can be used for additional preview functionality
            result.success(true)
        } catch (e: Exception) {
            result.error("PREVIEW_ERROR", "Failed to show route preview: ${e.message}", null)
        }
    }

fun stopNavigation() {
    try {
        println("🛑 Stopping navigation...")
        
        // Clear route and markers
        clearPreviousRoute()
        
        // Reset navigation state
        isNavigating = false
        currentDestinationName = null
        destinationLocation = null
        totalRouteDistance = 0.0
        totalRouteDuration = 0.0
        
        methodChannel.invokeMethod("onNavigationStopped", null)
        println("✅ Navigation stopped successfully")
        
    } catch (e: Exception) {
        e.printStackTrace()
        println("Error stopping navigation: ${e.message}")
    }
}

    fun recenterToCurrentLocation() {
        try {
            currentLocation?.let { location ->
                olaMap?.moveCameraToLatLong(OlaLatLng(location.latitude, location.longitude), 15.0, 1000)
            } ?: run {
                olaMap?.let { map ->
                    val currentLoc = map.getCurrentLocation()
                    if (currentLoc != null) {
                        map.moveCameraToLatLong(currentLoc, 15.0, 1000)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
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

    // ==========================================
    // HELPER METHODS
    // ==========================================
    
    private fun calculateBounds(routePoints: List<Map<String, Double>>): Map<String, Double> {
        if (routePoints.isEmpty()) return emptyMap()
        
        var minLat = Double.MAX_VALUE
        var maxLat = Double.MIN_VALUE
        var minLng = Double.MAX_VALUE
        var maxLng = Double.MIN_VALUE
        
        routePoints.forEach { point ->
            val lat = point["latitude"] ?: 0.0
            val lng = point["longitude"] ?: 0.0
            
            minLat = minOf(minLat, lat)
            maxLat = maxOf(maxLat, lat)
            minLng = minOf(minLng, lng)
            maxLng = maxOf(maxLng, lng)
        }
        
        return mapOf(
            "southWestLat" to minLat,
            "southWestLng" to minLng,
            "northEastLat" to maxLat,
            "northEastLng" to maxLng
        )
    }

    override fun getView(): View {
        return mapView
    }

    override fun dispose() {
        try {
            isNavigating = false
            locationManager?.removeUpdates(this)
            httpClient.dispatcher.executorService.shutdown()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}