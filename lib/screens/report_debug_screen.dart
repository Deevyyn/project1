import 'package:flutter/material.dart';
import 'package:cursortest/services/report_service.dart';
import 'package:cursortest/utils/theme.dart';
import 'dart:io';

class ReportDebugScreen extends StatefulWidget {
  const ReportDebugScreen({super.key});

  @override
  State<ReportDebugScreen> createState() => _ReportDebugScreenState();
}

class _ReportDebugScreenState extends State<ReportDebugScreen> {
  final ReportService _reportService = ReportService();
  List<FloodReport> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _reportService.initialize();
      _reports = _reportService.reports;
    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildReportCard(FloodReport report) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with ID and Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report ID: ${report.id.substring(0, 8)}...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${report.timestamp.hour}:${report.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // Location
            Text(
              'Location: ${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              'Description: ${report.description}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            
            // Image if available
            if (report.imagePath != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Image:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(report.imagePath!),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            
            // Risk Assessment Section
            const Text(
              'Risk Assessment:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildRiskInfo('Risk Level', report.riskLevel ?? 'Not assessed'),
            if (report.elevation != null)
              _buildRiskInfo('Elevation', '${report.elevation!.toStringAsFixed(1)}m'),
            _buildRiskInfo('Image Validated', report.imageValidated ? 'Yes' : 'No'),
            _buildRiskInfo('Severity', report.severity),
            
            // Environmental Data Section
            const SizedBox(height: 16),
            const Text(
              'Environmental Data:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildRiskInfo('Rainfall', '0.0 mm'), // Placeholder
            _buildRiskInfo('SCP Risk Level', 'Normal'), // Placeholder
            _buildRiskInfo('Historical Flood Data', 'Not available'), // Placeholder
          ],
        ),
      ),
    );
  }

  Widget _buildRiskInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bug_report,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reports available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    return _buildReportCard(_reports[index]);
                  },
                ),
    );
  }
} 