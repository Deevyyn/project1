import 'dart:async';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cursortest/models/geofence_region.dart';

// This is the name of the background task
const String geofencingTaskName = 'com.floodalert.geofencing';

// This is the callback function that will be called when the background task is triggered
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (taskName == geofencingTaskName) {
        await _checkGeofences();
      }
      return true;
    } catch (e) {
      debugPrint('Error in background task: $e');
      return false;
    }
  });
}

Future<void> _checkGeofences() async {
  try {
    // Get current location
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    // Get geofence regions from shared preferences or a local database
    // For simplicity, we'll use the same sample data as in the GeofencingService
    final regions = [
      GeofenceRegion(
        id: '1',
        name: 'Downtown Flood Zone',
        latitude: 37.7749,
        longitude: -122.4194,
        radius: 500,
        severity: 'High',
        description: 'Frequently flooded area during heavy rains',
      ),
      GeofenceRegion(
        id: '2',
        name: 'Riverside Park',
        latitude: 37.7833,
        longitude: -122.4167,
        radius: 300,
        severity: 'Medium',
        description: 'Low-lying area prone to flooding',
      ),
      GeofenceRegion(
        id: '3',
        name: 'North District',
        latitude: 37.7935,
        longitude: -122.4399,
        radius: 800,
        severity: 'Critical',
        description: 'Severe flooding risk during storms',
      ),
    ];
    
    // Check if the user is in any geofence region
    for (final region in regions) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        region.latitude,
        region.longitude,
      );
      
      if (distance <= region.radius) {
        // Trigger notification
        // In a real app, this would use a local notification plugin
        debugPrint('User entered geofence region: ${region.name}');
      }
    }
  } catch (e) {
    debugPrint('Error checking geofences: $e');
  }
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();
  
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
  }
  
  Future<void> startGeofencing() async {
    await Workmanager().registerPeriodicTask(
      'geofencing',
      geofencingTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }
  
  Future<void> stopGeofencing() async {
    await Workmanager().cancelByUniqueName('geofencing');
  }
} 