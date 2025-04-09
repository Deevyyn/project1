import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cursortest/models/geofence_region.dart';

class GeofencingService {
  static final GeofencingService _instance = GeofencingService._internal();
  factory GeofencingService() => _instance;
  GeofencingService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final StreamController<GeofenceRegion> _geofenceTriggerController = StreamController<GeofenceRegion>.broadcast();
  Timer? _locationCheckTimer;
  bool _isMonitoring = false;
  List<GeofenceRegion> _regions = [];
  
  // User preferences
  bool _notificationsEnabled = true;
  double _notificationRadius = 1000; // meters
  
  Stream<GeofenceRegion> get geofenceTriggerStream => _geofenceTriggerController.stream;
  
  Future<void> initialize() async {
    // Initialize notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
    
    // Load user preferences
    await _loadPreferences();
    
    // Load geofence regions
    await _loadGeofenceRegions();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('geofence_notifications_enabled') ?? true;
    _notificationRadius = prefs.getDouble('geofence_notification_radius') ?? 1000;
  }
  
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('geofence_notifications_enabled', _notificationsEnabled);
    await prefs.setDouble('geofence_notification_radius', _notificationRadius);
  }
  
  Future<void> _loadGeofenceRegions() async {
    // In a real app, this would load from a database or API
    // For now, we'll use sample data
    _regions = [
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
  }
  
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    
    // Start periodic location checks
    _locationCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkLocation();
    });
    
    // Check immediately
    _checkLocation();
    
    _isMonitoring = true;
  }
  
  Future<void> stopMonitoring() async {
    _locationCheckTimer?.cancel();
    _locationCheckTimer = null;
    _isMonitoring = false;
  }
  
  Future<void> _checkLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      for (final region in _regions) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          region.latitude,
          region.longitude,
        );
        
        if (distance <= region.radius) {
          _triggerGeofence(region);
        }
      }
    } catch (e) {
      debugPrint('Error checking location: $e');
    }
  }
  
  void _triggerGeofence(GeofenceRegion region) {
    // Notify listeners
    _geofenceTriggerController.add(region);
    
    // Show notification if enabled
    if (_notificationsEnabled) {
      _showNotification(region);
    }
  }
  
  Future<void> _showNotification(GeofenceRegion region) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Alerts',
      channelDescription: 'Notifications for flood-prone areas',
      importance: Importance.high,
      priority: Priority.high,
      color: _getSeverityColor(region.severity),
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      region.id.hashCode,
      'Flood Alert: ${region.name}',
      'You are entering a ${region.severity.toLowerCase()} risk flood zone. ${region.description}',
      details,
      payload: region.id,
    );
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return const Color(0xFF4CAF50); // Green
      case 'medium':
        return const Color(0xFFFF9800); // Orange
      case 'high':
      case 'critical':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }
  
  // User preference methods
  bool get notificationsEnabled => _notificationsEnabled;
  double get notificationRadius => _notificationRadius;
  
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _savePreferences();
  }
  
  Future<void> setNotificationRadius(double radius) async {
    _notificationRadius = radius;
    await _savePreferences();
  }
  
  // Geofence region methods
  List<GeofenceRegion> get regions => List.unmodifiable(_regions);
  
  Future<void> addRegion(GeofenceRegion region) async {
    _regions.add(region);
    // In a real app, this would save to a database or API
  }
  
  Future<void> removeRegion(String id) async {
    _regions.removeWhere((region) => region.id == id);
    // In a real app, this would save to a database or API
  }
  
  Future<void> updateRegion(GeofenceRegion region) async {
    final index = _regions.indexWhere((r) => r.id == region.id);
    if (index != -1) {
      _regions[index] = region;
      // In a real app, this would save to a database or API
    }
  }
  
  void dispose() {
    stopMonitoring();
    _geofenceTriggerController.close();
  }
} 