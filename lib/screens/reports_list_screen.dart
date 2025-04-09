import 'package:flutter/material.dart';
import 'package:cursortest/services/report_service.dart';
import 'package:cursortest/utils/theme.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> with SingleTickerProviderStateMixin {
  final _reportService = ReportService();
  late TabController _tabController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _reportService.initialize();
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reports: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _retrySubmission(String reportId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final report = await _reportService.retrySubmission(reportId);
      if (!mounted) return;
      
      if (report.isSubmitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(report.errorMessage ?? 'Failed to submit report. It will be retried later.'),
            backgroundColor: Theme.of(context).extension<CustomColors>()?.warning ?? AppTheme.warningYellow,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _retrySubmission(report.id);
              },
            ),
          ),
        );
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteReport(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _reportService.deleteReport(reportId);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting report: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Widget _buildReportCard(FloodReport report) {
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final formattedDate = dateFormat.format(report.timestamp);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.imagePath != null)
            Image.file(
              File(report.imagePath!),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(report.severity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        report.severity,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  report.description,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Location: ${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                if (!report.isSubmitted && report.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      report.errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!report.isSubmitted)
                      TextButton.icon(
                        onPressed: () => _retrySubmission(report.id),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteReport(report.id),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildReportsList(List<FloodReport> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_problem,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return _buildReportCard(reports[index]);
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Submitted'),
            Tab(text: 'Pending'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportsList(_reportService.reports),
                _buildReportsList(_reportService.pendingReports),
              ],
            ),
    );
  }
} 