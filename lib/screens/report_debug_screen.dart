import 'package:flutter/material.dart';
import 'package:cursortest/services/supabase_service.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:intl/intl.dart';

class ReportDebugScreen extends StatefulWidget {
  const ReportDebugScreen({super.key});

  @override
  State<ReportDebugScreen> createState() => _ReportDebugScreenState();
}

class _ReportDebugScreenState extends State<ReportDebugScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _reports = [];
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
      final reports = await _supabaseService.getFloodReports();
      setState(() {
        _reports = reports;
      });
    } catch (e) {
      debugPrint('Error loading reports from Supabase: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    // Calculate or get scores with defaults
    final rainfall = (report['rainfall'] as num?)?.toDouble() ?? 0.0;
    final elevation = (report['elevation'] as num?)?.toDouble() ?? 0.0;
    final userReports = (report['user_reports_count'] as int?) ?? 0;
    final scpRiskLevel = report['scp_risk_level']?.toString() ?? 'Normal';
    final rainIntensity = (report['rain_intensity'] as num?)?.toDouble() ?? 0.0;
    final humidity = (report['humidity'] as num?)?.toDouble() ?? 0.0;

    // Calculate individual scores based on new scoring system
    final rainfallScore = rainfall > 40 ? 2 : 0;
    final elevationScore = elevation < 30 ? 2 : 0;
    
    int scpScore;
    switch (scpRiskLevel.toLowerCase()) {
      case 'above normal':
        scpScore = 2;
        break;
      case 'normal':
        scpScore = 1;
        break;
      case 'below normal':
      default:
        scpScore = 0;
    }
    
    final intensityScore = rainIntensity > 10 ? 1 : 0;
    final humidityScore = humidity > 80 ? 1 : 0;
    
    // Calculate total score (sum of all individual scores, capped at 7)
    final totalScore = (rainfallScore + elevationScore + scpScore + 
                       intensityScore + humidityScore).clamp(0, 7);
    
    // User reports override
    final isOverridden = userReports > 2;

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
                Expanded(
                  child: Text(
                    'Report ID: ${report['id']?.toString().substring(0, 8) ?? 'Unknown'}...',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  report['timestamp'] != null 
                      ? DateFormat('HH:mm - MMM d, yyyy').format(DateTime.parse(report['timestamp']))
                      : 'Unknown time',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // Location - showing coordinates and description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GPS Coordinates: ${(report['latitude'] as num?)?.toStringAsFixed(6) ?? 'Unknown'}, ${(report['longitude'] as num?)?.toStringAsFixed(6) ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
            const SizedBox(height: 16),
            
            // Risk Summary Section
            const Text(
              'Risk Assessment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildInfoChip(
                  label: 'Severity',
                  value: report['severity']?.toString() ?? 'Unknown',
                  valueBuilder: _buildSeverityTag,
                ),
                _buildInfoChip(
                  label: 'Final Risk',
                  value: _getFinalRiskLevel(totalScore),
                  valueBuilder: _buildRiskTag,
                ),
                const Spacer(),
                _buildValidationTag(report['is_validated'] == true),
              ],
            ),
            
            // Risk Score Breakdown Section
            const SizedBox(height: 16),
            const Text(
              'Risk Score Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            // Risk factors with scores
            _buildScoreItem(
              'Rainfall', 
              '${rainfall.toStringAsFixed(1)} mm',
              rainfall > 40 ? '+2' : '0',
              severity: _getSeverityFromScore(rainfall > 40 ? 2 : 0),
              tooltip: 'Rainfall > 40mm = +2 points',
            ),
            _buildScoreItem(
              'Elevation', 
              '${elevation.toStringAsFixed(1)} m',
              elevation < 30 ? '+2' : '0',
              severity: _getSeverityFromScore(elevation < 30 ? 2 : 0),
              tooltip: 'Elevation < 30m = +2 points',
            ),
            _buildScoreItem(
              'SCP Risk Level', 
              scpRiskLevel.isNotEmpty ? scpRiskLevel.toUpperCase() : 'N/A',
              scpScore > 0 ? '+$scpScore' : '0',
              severity: _getSeverityFromScore(scpScore),
              tooltip: 'SCP risk level: ${scpRiskLevel.toUpperCase()}\nAbove Normal: +2\nNormal: +1\nBelow Normal: 0',
            ),
            _buildScoreItem(
              'Rain Intensity',
              '${rainIntensity.toStringAsFixed(1)} mm/h',
              rainIntensity > 10 ? '+1' : '0',
              severity: _getSeverityFromScore(rainIntensity > 10 ? 1 : 0),
              tooltip: 'Rain intensity > 10mm/h = +1 point',
            ),
            _buildScoreItem(
              'Humidity',
              '${humidity.toStringAsFixed(0)}%',
              humidity > 80 ? '+1' : '0',
              severity: _getSeverityFromScore(humidity > 80 ? 1 : 0),
              tooltip: 'Humidity > 80% = +1 point',
            ),
            _buildScoreItem(
              'User Reports', 
              '$userReports report${userReports != 1 ? 's' : ''}',
              isOverridden ? 'OVERRIDE' : '0',
              severity: _getSeverityFromScore(isOverridden ? 2 : 0),
              tooltip: isOverridden 
                  ? '>2 reports = Automatic High Risk' 
                  : 'Number of reports in area: $userReports',
              showOverride: isOverridden,
            ),
            
            const Divider(),
            
            // Total score and alert status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTotalScore(totalScore),
                _buildAlertStatus(report['alert_triggered'] == true),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(
    String label, 
    String value, 
    String score, {
    int severity = 0, // 0=low, 1=medium, 2=high
    String tooltip = '',
    bool showOverride = false,
  }) {
    final colors = [
      Colors.green,  // Low
      Colors.orange, // Medium
      Colors.red,    // High
    ];
    
    final scoreColor = colors[severity.clamp(0, 2)];

    final scoreWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showOverride) ...[
            const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
            const SizedBox(width: 4),
          ],
          Text(
            score,
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );

    return Tooltip(
      message: tooltip.isNotEmpty ? tooltip : '$label: $value',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            scoreWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityTag(String severity) {
    Color tagColor;
    switch (severity.toLowerCase()) {
      case 'high':
        tagColor = Colors.red;
        break;
      case 'medium':
        tagColor = Colors.orange;
        break;
      case 'low':
        tagColor = Colors.green;
        break;
      default:
        tagColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity,
        style: TextStyle(
          color: tagColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRiskTag(String risk) {
    Color tagColor;
    switch (risk.toLowerCase()) {
      case 'high':
        tagColor = Colors.red;
        break;
      case 'medium':
        tagColor = Colors.orange;
        break;
      case 'low':
        tagColor = Colors.green;
        break;
      default:
        tagColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        risk,
        style: TextStyle(
          color: tagColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildValidationTag(bool isValidated) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isValidated ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValidated ? Icons.check_circle : Icons.pending,
            size: 14,
            color: isValidated ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isValidated ? 'Validated' : 'Pending',
            style: TextStyle(
              color: isValidated ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the severity level based on the score
  /// 0 = Low, 1 = Medium, 2 = High
  /// 
  /// This method is used throughout the app to ensure consistent severity calculation
  /// and is referenced in multiple places where we need to display risk indicators
  int _getSeverityFromScore(int score) {
    if (score >= 2) return 2; // High severity
    if (score == 1) return 1; // Medium severity
    return 0;                 // Low severity
  }

  String _getFinalRiskLevel(int score) {
    if (score >= 6) return 'High';
    if (score >= 3) return 'Medium';
    return 'Low';
  }

  
  Widget _buildInfoChip({
    required String label,
    required String value,
    required Widget Function(String) valueBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          valueBuilder(value),
        ],
      ),
    );
  }


  Widget _buildTotalScore(int score) {
    String riskLevel;
    Color scoreColor;
    
    if (score >= 6) {
      riskLevel = 'High Risk';
      scoreColor = Colors.red;
    } else if (score >= 3) {
      riskLevel = 'Medium Risk';
      scoreColor = Colors.orange;
    } else {
      riskLevel = 'Low Risk';
      scoreColor = Colors.green;
    }

    return Tooltip(
      message: 'Risk Level: $riskLevel\nScore: $score/7',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scoreColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scoreColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: scoreColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getRiskIcon(riskLevel),
              size: 16,
              color: scoreColor,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RISK SCORE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$score/7',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high risk':
        return Icons.warning_amber_rounded;
      case 'medium risk':
        return Icons.info_outline_rounded;
      case 'low risk':
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  Widget _buildAlertStatus(bool alertTriggered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: alertTriggered ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alertTriggered ? Colors.red.withOpacity(0.5) : Colors.grey.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            alertTriggered ? Icons.notifications_active : Icons.notifications_off,
            size: 16,
            color: alertTriggered ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            alertTriggered ? 'Alert Sent' : 'No Alert',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: alertTriggered ? Colors.red : Colors.grey,
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