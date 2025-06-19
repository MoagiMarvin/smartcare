import 'package:flutter/material.dart';
import '../services/data_manager.dart';
import '../models/models.dart';
import '../widgets/medication_alarm_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onCelebration;
  final VoidCallback? onNavigateToChat;

  const DashboardScreen({
    super.key,
    this.onCelebration,
    this.onNavigateToChat,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DataManager _dataManager = DataManager();
  int _currentMotivation = 0;
  
  User? _user;
  List<Medication> _medications = [];
  List<DailyTask> _dailyTasks = [];
  List<Map<String, dynamic>> _todaysSchedule = [];
  Map<String, dynamic> _healthInsights = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Rotate motivational messages
    Stream.periodic(Duration(seconds: 8)).listen((_) {
      if (mounted) {
        setState(() {
          _currentMotivation = (_currentMotivation + 1) % DataManager.motivationalMessages.length;
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Generate daily tasks if needed
      await _dataManager.generateDailyTasks();
      
      // Load all data
      final user = await _dataManager.getUser();
      final medications = await _dataManager.getMedications();
      final dailyTasks = await _dataManager.getTodaysTasks();
      final schedule = await _dataManager.getTodaysMedicationSchedule();
      final insights = await _dataManager.getHealthInsights();
      
      setState(() {
        _user = user;
        _medications = medications;
        _dailyTasks = dailyTasks;
        _todaysSchedule = schedule;
        _healthInsights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _completeTask(int taskId) async {
    try {
      bool success = await _dataManager.completeTask(taskId);
      if (success) {
        await _loadData(); // Refresh data
        widget.onCelebration?.call();
      } else {
        _showErrorSnackBar('Failed to complete task');
      }
    } catch (e) {
      _showErrorSnackBar('Error completing task: $e');
    }
  }

  void _showMedicationAlarm(String time) {
    List<Medication> medsAtTime = _medications
        .where((med) => med.alarms.any((alarm) => alarm.time == time))
        .toList();

    if (medsAtTime.isEmpty) {
      _showErrorSnackBar('No medications scheduled for $time');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MedicationAlarmDialog(
          time: time,
          medications: medsAtTime,
          onTaken: () {
            widget.onCelebration?.call();
            _loadData(); // Refresh data after taking medication
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'medication':
        return Icons.medication;
      case 'wellness':
        return Icons.favorite;
      case 'social':
        return Icons.people;
      default:
        return Icons.check_circle;
    }
  }

  Widget _buildMedicationScheduleCard() {
    final upcomingAlarms = _todaysSchedule.where((item) => !item['taken']).toList();
    final completedAlarms = _todaysSchedule.where((item) => item['taken']).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFF10B981), size: 24),
              SizedBox(width: 8),
              Text('Today\'s Medication Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          
          if (_todaysSchedule.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'No medications scheduled for today or all completed! 🎉',
                      style: TextStyle(fontSize: 16, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Upcoming medications
            if (upcomingAlarms.isNotEmpty) ...[
              Text('Upcoming:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              SizedBox(height: 8),
              ...upcomingAlarms.take(3).map((item) {
                final medication = item['medication'] as Medication;
                final alarm = item['alarm'] as MedicationAlarm;
                final isLowStock = medication.currentStock < alarm.pillsPerDose;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.red[50] : Color(0xFFF0F8FF),
                    border: Border.all(
                      color: isLowStock ? Colors.red[300]! : Colors.blue[200]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isLowStock ? Colors.red[100] : Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLowStock ? Icons.warning : Icons.access_time,
                          color: isLowStock ? Colors.red[700] : Colors.blue[700],
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${alarm.time} - ${medication.name}',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${alarm.pillsPerDose} pills',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            if (alarm.notes != null)
                              Text(
                                alarm.notes!,
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            if (isLowStock)
                              Text(
                                'Low stock: ${medication.currentStock} pills left!',
                                style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showMedicationAlarm(alarm.time),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLowStock ? Colors.red : Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          minimumSize: Size(60, 32),
                        ),
                        child: Text(isLowStock ? 'Check' : 'Take'),
                      ),
                    ],
                  ),
                );
              }),
            ],
            
            // Completed medications
            if (completedAlarms.isNotEmpty) ...[
              if (upcomingAlarms.isNotEmpty) SizedBox(height: 16),
              Text('Completed:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              SizedBox(height: 8),
              ...completedAlarms.take(2).map((item) {
                final medication = item['medication'] as Medication;
                final alarm = item['alarm'] as MedicationAlarm;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFECFDF5),
                    border: Border.all(color: Color(0xFF10B981)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFA7F3D0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle, color: Color(0xFF047857), size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${alarm.time} - ${medication.name}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.lineThrough,
                                color: Color(0xFF047857),
                              ),
                            ),
                            Text(
                              'Took ${alarm.pillsPerDose} pills ✓',
                              style: TextStyle(color: Color(0xFF047857), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStockAlertsCard() {
    final lowStockMeds = _medications.where((med) => med.needsRefillSoon).toList();
    final criticalStockMeds = _medications.where((med) => med.isCriticallyLow).toList();
    
    if (lowStockMeds.isEmpty) return Container();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: criticalStockMeds.isNotEmpty ? Color(0xFFFEF2F2) : Color(0xFFFFF7ED),
        border: Border(left: BorderSide(
          color: criticalStockMeds.isNotEmpty ? Colors.red : Colors.orange,
          width: 4,
        )),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                criticalStockMeds.isNotEmpty ? Icons.error : Icons.warning,
                color: criticalStockMeds.isNotEmpty ? Colors.red : Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                criticalStockMeds.isNotEmpty ? 'Critical Stock Alert' : 'Medication Stock Alert',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: criticalStockMeds.isNotEmpty ? Colors.red[800] : Colors.orange[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...lowStockMeds.take(3).map((med) => Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              '${med.isCriticallyLow ? '🚨' : '⚠️'} ${med.name}: ${med.currentStock} pills (${med.daysRemaining} days)',
              style: TextStyle(
                color: med.isCriticallyLow ? Colors.red[700] : Colors.orange[700],
              ),
            ),
          )),
          if (lowStockMeds.length > 3) ...[
            SizedBox(height: 4),
            Text(
              '+ ${lowStockMeds.length - 3} more medications need attention',
              style: TextStyle(
                color: criticalStockMeds.isNotEmpty ? Colors.red[600] : Colors.orange[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF10B981)),
            SizedBox(height: 16),
            Text('Loading your health data...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('Unable to load user data', style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Color(0xFF10B981),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Daily Motivation
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DataManager.motivationalMessages[_currentMotivation],
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // User Overview
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0D9488)]),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _user!.name[0],
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_user!.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('Healthcare Journey', style: TextStyle(color: Colors.grey[600])),
                            Text(_user!.location, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.track_changes, color: Color(0xFF10B981), size: 20),
                              SizedBox(width: 4),
                              Text('${_user!.adherenceStreak} Day Streak', 
                                   style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Color(0xFF0D9488), size: 20),
                              SizedBox(width: 4),
                              Text('Next: ${_user!.nextAppointment}', 
                                   style: TextStyle(fontSize: 12, color: Color(0xFF0D9488))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Viral Load', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              Text(_user!.viralLoad, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CD4 Count', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              Text(_user!.cd4Count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Today's Medication Schedule
            _buildMedicationScheduleCard(),
            SizedBox(height: 24),

            // Quick Chat Access
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF0F8FF),
                border: Border(left: BorderSide(color: Color(0xFF10B981), width: 4)),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.smart_toy, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Need Health Advice?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        Text('Ask about medications, side effects, or interactions', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.onNavigateToChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Chat Now'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Stock Alerts
            _buildStockAlertsCard(),

            // Important Alerts
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFEFF6FF),
                border: Border(left: BorderSide(color: Colors.blue, width: 4)),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Upcoming Reminders', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[800])),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('🚐 Mobile clinic nearby tomorrow (Soweto)', style: TextStyle(color: Colors.green[700])),
                  SizedBox(height: 4),
                  Text('📅 Next appointment: ${_user!.nextAppointment}', style: TextStyle(color: Colors.blue[700])),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Today's Care Tasks
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Color(0xFF10B981), size: 24),
                      SizedBox(width: 8),
                      Text('Today\'s Care Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (_dailyTasks.isEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                          SizedBox(width: 12),
                          Text('All tasks completed for today! 🎉', 
                               style: TextStyle(fontSize: 16, color: Color(0xFF047857))),
                        ],
                      ),
                    )
                  else
                    ..._dailyTasks.map((task) => Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: task.completed ? null : () => _completeTask(task.id!),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: task.completed ? Color(0xFFECFDF5) : Colors.grey[50],
                            border: Border.all(
                              color: task.completed ? Color(0xFF10B981) : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: task.completed ? Color(0xFFA7F3D0) : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getCategoryIcon(task.category),
                                  color: task.completed ? Color(0xFF047857) : Colors.grey[600],
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.task,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: task.completed ? Color(0xFF047857) : Colors.grey[800],
                                        decoration: task.completed ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    if (task.time != null)
                                      Text('⏰ ${task.time}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                    if (task.pillsToTake != null)
                                      Text('💊 ${task.pillsToTake} pills', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ],
                                ),
                              ),
                              if (task.completed)
                                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                            ],
                          ),
                        ),
                      ),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}