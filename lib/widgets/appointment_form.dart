import 'package:flutter/material.dart';
import '../models/models.dart';

class AppointmentForm extends StatefulWidget {
  final Appointment? existingAppointment;
  final VoidCallback? onSaved;

  const AppointmentForm({
    super.key,
    this.existingAppointment,
    this.onSaved,
  });

  @override
  _AppointmentFormState createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _doctorController;
  late TextEditingController _notesController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedType;
  late Duration _selectedDuration;

  @override
  void initState() {
    super.initState();
    
    _titleController = TextEditingController(text: widget.existingAppointment?.title ?? '');
    _locationController = TextEditingController(text: widget.existingAppointment?.location ?? '');
    _doctorController = TextEditingController(text: widget.existingAppointment?.doctorName ?? '');
    _notesController = TextEditingController(text: widget.existingAppointment?.notes ?? '');
    _phoneController = TextEditingController(text: widget.existingAppointment?.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.existingAppointment?.address ?? '');
    
    _selectedDate = widget.existingAppointment?.dateTime ?? DateTime.now().add(Duration(days: 1));
    _selectedTime = widget.existingAppointment != null 
        ? TimeOfDay.fromDateTime(widget.existingAppointment!.dateTime)
        : TimeOfDay(hour: 9, minute: 0);
    _selectedType = widget.existingAppointment?.type ?? 'routine';
    _selectedDuration = widget.existingAppointment?.estimatedDuration ?? Duration(hours: 1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  void _saveAppointment() {
    if (_titleController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in title and location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final appointment = Appointment(
      id: widget.existingAppointment?.id,
      title: _titleController.text.trim(),
      dateTime: appointmentDateTime,
      location: _locationController.text.trim(),
      doctorName: _doctorController.text.trim().isNotEmpty 
          ? _doctorController.text.trim() 
          : null,
      type: _selectedType,
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      phoneNumber: _phoneController.text.trim().isNotEmpty 
          ? _phoneController.text.trim() 
          : null,
      address: _addressController.text.trim().isNotEmpty 
          ? _addressController.text.trim() 
          : null,
      estimatedDuration: _selectedDuration,
      completed: widget.existingAppointment?.completed ?? false,
      status: widget.existingAppointment?.status ?? 'scheduled',
    );

    Navigator.of(context).pop(appointment);
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingAppointment == null ? 'Add Appointment' : 'Edit Appointment'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Text(
                'Appointment Details', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Appointment Title *',
                  hintText: 'e.g., Check-up with Dr. Smith',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Appointment Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'routine', child: Text('ROUTINE')),
                  DropdownMenuItem(value: 'urgent', child: Text('URGENT')),
                  DropdownMenuItem(value: 'follow-up', child: Text('FOLLOW-UP')),
                  DropdownMenuItem(value: 'lab', child: Text('LAB')),
                  DropdownMenuItem(value: 'specialist', child: Text('SPECIALIST')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              SizedBox(height: 16),

              // Date and Time
              Text(
                'Date & Time', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16),
                            SizedBox(width: 8),
                            Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 16),
                            SizedBox(width: 8),
                            Text('${_selectedTime.format(context)}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<Duration>(
                value: _selectedDuration,
                decoration: InputDecoration(
                  labelText: 'Estimated Duration',
                  border: OutlineInputBorder(),
                ),
                items: [
                  Duration(minutes: 30),
                  Duration(hours: 1),
                  Duration(hours: 1, minutes: 30),
                  Duration(hours: 2),
                  Duration(hours: 3),
                ].map((duration) => DropdownMenuItem(
                  value: duration,
                  child: Text(_formatDuration(duration)),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value!;
                  });
                },
              ),
              SizedBox(height: 16),

              // Location Information
              Text(
                'Location & Contact', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Clinic/Hospital Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _doctorController,
                decoration: InputDecoration(
                  labelText: 'Doctor/Specialist Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  hintText: 'e.g., Bring previous test results',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAppointment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: Text(widget.existingAppointment == null ? 'Add Appointment' : 'Save Changes'),
        ),
      ],
    );
  }
}

// Helper function to show the appointment form
Future<Appointment?> showAppointmentForm(
  BuildContext context, {
  Appointment? existingAppointment,
  VoidCallback? onSaved,
}) {
  return showDialog<Appointment>(
    context: context,
    builder: (BuildContext context) {
      return AppointmentForm(
        existingAppointment: existingAppointment,
        onSaved: onSaved,
      );
    },
  );
}