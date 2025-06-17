import 'package:flutter/material.dart';
import '../data/app_data.dart';
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
  int _currentMotivation = 0;
  List<DailyTask> _dailyTasks = List.from(AppData.dailyTasks);

  @override
  void initState() {
    super.initState();
    // Rotate motivational messages
    Stream.periodic(Duration(seconds: 8)).listen((_) {
      if (mounted) {
        setState(() {
          _currentMotivation = (_currentMotivation + 1) % AppData.motivationalMessages.length;
        });
      }
    });
  }

  void _completeTask(int taskId) {
    setState(() {
      int index = _dailyTasks.indexWhere((task) => task.id == taskId);
      if (index != -1 && !_dailyTasks[index].completed) {
        _dailyTasks[index] = DailyTask(
          id: _dailyTasks[index].id,
          task: _dailyTasks[index].task,
          completed: true,
          medicationId: _dailyTasks[index].medicationId,
          time: _dailyTasks[index].time,
          category: _dailyTasks[index].category,
        );
        widget.onCelebration?.call();
      }
    });
  }

  void _showMedicationAlarm(String time) {
    List<Medication> medsAtTime = AppData.medications
        .where((med) => med.times.contains(time))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MedicationAlarmDialog(
          time: time,
          medications: medsAtTime,
          onTaken: widget.onCelebration,
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    AppData.motivationalMessages[_currentMotivation],
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
                          AppData.user.name[0],
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppData.user.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('Healthcare Journey', style: TextStyle(color: Colors.grey[600])),
                          Text(AppData.user.location, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
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
                            Text('${AppData.user.adherenceStreak} Day Streak', 
                                 style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Color(0xFF0D9488), size: 20),
                            SizedBox(width: 4),
                            Text('Next: ${AppData.user.nextAppointment}', 
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
                            Text(AppData.user.viralLoad, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
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
                            Text(AppData.user.cd4Count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
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
                      Text('Chat with our AI assistant for instant support', style: TextStyle(color: Colors.grey[600])),
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
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🔔 Morning medications in 30 minutes (08:00)', style: TextStyle(color: Colors.blue[700])),
                    ElevatedButton(
                      onPressed: () => _showMedicationAlarm("08:00"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: Size(60, 24),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: Text('Preview', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text('💊 Collect multivitamin in ${AppData.medications[1].daysUntilCollection} days', 
                     style: TextStyle(color: Colors.orange[700])),
                SizedBox(height: 4),
                Text('🚐 Mobile clinic nearby tomorrow (Soweto)', style: TextStyle(color: Colors.green[700])),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Low Stock Alert
          if (AppData.medications.any((med) => med.pillsLeft <= 10))
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Color(0xFFFFF7ED),
                border: Border(left: BorderSide(color: Colors.orange, width: 4)),
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
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Medication Stock Alert', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange[800])),
                    ],
                  ),
                  SizedBox(height: 8),
                  ...AppData.medications
                      .where((med) => med.pillsLeft <= 10)
                      .map((med) => Text('⚠️ ${med.name}: ${med.pillsLeft} pills remaining', 
                                        style: TextStyle(color: Colors.orange[700])))
                      ,
                ],
              ),
            ),

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
                ..._dailyTasks.map((task) => Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: task.completed ? null : () => _completeTask(task.id),
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
    );
  }
}