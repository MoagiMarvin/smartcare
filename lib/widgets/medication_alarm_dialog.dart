import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_manager.dart';

class MedicationAlarmDialog extends StatefulWidget {
  final String time;
  final List<Medication> medications;
  final VoidCallback? onTaken;

  const MedicationAlarmDialog({
    super.key,
    required this.time,
    required this.medications,
    this.onTaken,
  });

  @override
  _MedicationAlarmDialogState createState() => _MedicationAlarmDialogState();
}

class _MedicationAlarmDialogState extends State<MedicationAlarmDialog> {
  final DataManager _dataManager = DataManager();
  final Map<int, bool> _medicationTaken = {};
  final Map<int, int> _customPillCounts = {};
  final Map<int, TextEditingController> _notesControllers = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Initialize state for each medication
    for (final medication in widget.medications) {
      _medicationTaken[medication.id!] = false;
      _notesControllers[medication.id!] = TextEditingController();
      
      // Find the specific alarm for this time
      final alarm = medication.alarms.firstWhere(
        (alarm) => alarm.time == widget.time,
        orElse: () => medication.alarms.first,
      );
      _customPillCounts[medication.id!] = alarm.pillsPerDose;
    }
  }

  @override
  void dispose() {
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _takeMedication(Medication medication) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      final medicationId = medication.id!;
      final pillsToTake = _customPillCounts[medicationId] ?? 1;
      final notes = _notesControllers[medicationId]?.text.trim();

      // Check if enough stock
      if (medication.currentStock < pillsToTake) {
        _showStockError(medication, pillsToTake);
        setState(() => _isProcessing = false);
        return;
      }

      // Take the medication
      bool success = await _dataManager.takeMedication(
        medicationId,
        widget.time,
        pillsToTake,
        notes: notes?.isNotEmpty == true ? notes : null,
      );

      if (success) {
        setState(() {
          _medicationTaken[medicationId] = true;
        });
        _showSuccessMessage(medication, pillsToTake);
      } else {
        _showErrorMessage('Failed to record medication. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    }

    setState(() => _isProcessing = false);
  }

  void _showStockError(Medication medication, int requestedPills) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Low Stock Warning'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Not enough ${medication.name} remaining.'),
            SizedBox(height: 8),
            Text('Requested: $requestedPills pills'),
            Text('Available: ${medication.currentStock} pills'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Contact your pharmacy for a refill or adjust the dose.',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _adjustDose(medication);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text('Adjust Dose'),
          ),
        ],
      ),
    );
  }

  void _adjustDose(Medication medication) {
    final controller = TextEditingController(
      text: medication.currentStock.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Dose'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many ${medication.name} will you take?'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Pills to take',
                border: OutlineInputBorder(),
                suffixText: 'Available: ${medication.currentStock}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newCount = int.tryParse(controller.text) ?? 0;
              if (newCount > 0 && newCount <= medication.currentStock) {
                setState(() {
                  _customPillCounts[medication.id!] = newCount;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(Medication medication, int pillsTaken) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Took $pillsTaken ${medication.name}. Stock updated.'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _snoozeAlarm() async {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarm snoozed for 15 minutes'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            // In a real app, this would cancel the snooze
          },
        ),
      ),
    );
  }

  Future<void> _markAllTaken() async {
    if (_isProcessing) return;

    bool allTaken = true;
    for (final medication in widget.medications) {
      if (!_medicationTaken[medication.id!]!) {
        await _takeMedication(medication);
        if (!_medicationTaken[medication.id!]!) {
          allTaken = false;
          break;
        }
      }
    }

    if (allTaken) {
      Navigator.of(context).pop();
      widget.onTaken?.call();
    }
  }

  Widget _buildMedicationCard(Medication medication) {
    final medicationId = medication.id!;
    final taken = _medicationTaken[medicationId] ?? false;
    final pillsToTake = _customPillCounts[medicationId] ?? 1;
    
    // Find the specific alarm for this time
    final alarm = medication.alarms.firstWhere(
      (alarm) => alarm.time == widget.time,
      orElse: () => medication.alarms.first,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: taken ? Color(0xFFECFDF5) : Color(0xFFFFF7ED),
        border: Border.all(
          color: taken ? Color(0xFF10B981) : Colors.orange[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with medication name and status
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: taken ? Color(0xFFA7F3D0) : Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  taken ? Icons.check_circle : Icons.medication,
                  color: taken ? Color(0xFF047857) : Colors.orange[700],
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: taken ? TextDecoration.lineThrough : null,
                        color: taken ? Color(0xFF047857) : Colors.grey[800],
                      ),
                    ),
                    Text(
                      medication.instructions,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (taken)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TAKEN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Medication details
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dose', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text('$pillsToTake pills', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stock', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Row(
                        children: [
                          Text(
                            '${medication.currentStock} left',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: medication.currentStock < pillsToTake ? Colors.red : Colors.grey[800],
                            ),
                          ),
                          if (medication.currentStock < pillsToTake)
                            Icon(Icons.warning, color: Colors.red, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pill Info', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text('${medication.color} ${medication.shape}', 
                           style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Special instructions or notes
          if (alarm.notes != null) ...[
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alarm.notes!,
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Food requirements
          if (medication.foodRequirements != null) ...[
            SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant, color: Colors.green[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      medication.foodRequirements!,
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Notes input and action buttons
          if (!taken) ...[
            SizedBox(height: 12),
            TextField(
              controller: _notesControllers[medicationId],
              decoration: InputDecoration(
                hintText: 'Add notes (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              maxLines: 1,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                if (medication.currentStock >= pillsToTake)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () => _takeMedication(medication),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      child: _isProcessing 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('✓ Take $pillsToTake'),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _adjustDose(medication),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Adjust Dose'),
                    ),
                  ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () => _adjustDose(medication),
                  icon: Icon(Icons.edit),
                  tooltip: 'Adjust dose',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTaken = widget.medications.every((med) => _medicationTaken[med.id!] == true);

    return AlertDialog(
      title: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: allTaken ? Color(0xFF10B981) : Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Icon(
              allTaken ? Icons.check_circle : Icons.notifications_active,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(height: 16),
          Text(
            allTaken ? 'All Medications Taken!' : 'Medication Reminder',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            '${widget.time} - Time for your medications',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!allTaken) ...[
                Text(
                  'Medications to take:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 16),
              ],
              ...widget.medications.map((med) => _buildMedicationCard(med)),
            ],
          ),
        ),
      ),
      actions: [
        if (!allTaken) ...[
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isProcessing ? null : _snoozeAlarm,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[700],
                  ),
                  child: Text('Snooze 15min'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _markAllTaken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('✓ Take All'),
                ),
              ),
            ],
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onTaken?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('✓ Done'),
            ),
          ),
        ],
      ],
    );
  }
}