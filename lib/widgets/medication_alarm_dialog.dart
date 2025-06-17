import 'package:flutter/material.dart';
import '../models/models.dart';

class MedicationAlarmDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications, color: Colors.white, size: 32),
          ),
          SizedBox(height: 16),
          Text('Medication Reminder', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('$time - Time for your medications', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Take Now:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 16),
          ...medications.map((med) => Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFECFDF5),
              border: Border.all(color: Color(0xFF10B981), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFFA7F3D0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.medication, color: Color(0xFF047857)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(med.instructions, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      Text('💊 ${med.dosage} • 🎨 ${med.color} ${med.shape}', 
                           style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[700],
                ),
                child: Text('Snooze 5min'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onTaken?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: Text('✓ Taken'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}