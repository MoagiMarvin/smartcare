import 'package:flutter/material.dart';
import '../services/data_manager.dart';
import '../models/models.dart';
import '../widgets/appointment_form.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DataManager _dataManager = DataManager();
  
  User? _user;
  List<Medication> _medications = [];
  List<Medication> _temporaryMedications = [];
  List<Appointment> _appointments = [];
  Map<String, dynamic> _medicationInsights = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await _dataManager.getUser();
      final medications = await _dataManager.getMedications();
      final tempMedications = await _dataManager.getTemporaryMedications();
      final appointments = await _dataManager.getAppointments();
      final insights = await _dataManager.getMedicationInsights();
      
      setState(() {
        _user = user;
        _medications = medications.where((med) => !med.isTemporary).toList();
        _temporaryMedications = tempMedications;
        _appointments = appointments;
        _medicationInsights = insights;
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Color(0xFF10B981)),
    );
  }

  Future<void> _addMedication() async {
    final result = await _showMedicationForm();
    if (result != null) {
      try {
        bool success = await _dataManager.addMedication(result);
        if (success) {
          _showSuccessSnackBar('Medication added successfully');
          await _loadData();
        } else {
          _showErrorSnackBar('Failed to add medication');
        }
      } catch (e) {
        _showErrorSnackBar('Error adding medication: $e');
      }
    }
  }

  Future<void> _editMedication(Medication medication) async {
    final result = await _showMedicationForm(existingMedication: medication);
    if (result != null) {
      try {
        bool success = await _dataManager.updateMedication(result);
        if (success) {
          _showSuccessSnackBar('Medication updated successfully');
          await _loadData();
        } else {
          _showErrorSnackBar('Failed to update medication');
        }
      } catch (e) {
        _showErrorSnackBar('Error updating medication: $e');
      }
    }
  }

  Future<void> _addAppointment() async {
    final result = await showAppointmentForm(context);
    if (result != null) {
      try {
        bool success = await _dataManager.addAppointment(result);
        if (success) {
          _showSuccessSnackBar('Appointment added successfully');
          await _loadData();
        } else {
          _showErrorSnackBar('Failed to add appointment');
        }
      } catch (e) {
        _showErrorSnackBar('Error adding appointment: $e');
      }
    }
  }

  Future<void> _editAppointment(Appointment appointment) async {
    final result = await showAppointmentForm(context, existingAppointment: appointment);
    if (result != null) {
      try {
        bool success = await _dataManager.updateAppointment(result);
        if (success) {
          _showSuccessSnackBar('Appointment updated successfully');
          await _loadData();
        } else {
          _showErrorSnackBar('Failed to update appointment');
        }
      } catch (e) {
        _showErrorSnackBar('Error updating appointment: $e');
      }
    }
  }

  Future<void> _deleteAppointment(Appointment appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete:'),
            SizedBox(height: 8),
            Text(appointment.title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(appointment.formattedDateTime, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      try {
        bool success = await _dataManager.deleteAppointment(appointment.id!);
        if (success) {
          _showSuccessSnackBar('Appointment deleted successfully');
          await _loadData();
        } else {
          _showErrorSnackBar('Failed to delete appointment');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting appointment: $e');
      }
    }
  }

  Future<void> _markAppointmentCompleted(Appointment appointment) async {
    try {
      final updated = appointment.copyWith(completed: true, status: 'completed');
      bool success = await _dataManager.updateAppointment(updated);
      if (success) {
        _showSuccessSnackBar('Appointment marked as completed');
        await _loadData();
      } else {
        _showErrorSnackBar('Failed to update appointment');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating appointment: $e');
    }
  }

  Future<Medication?> _showMedicationForm({Medication? existingMedication}) async {
    final nameController = TextEditingController(text: existingMedication?.name ?? '');
    final instructionsController = TextEditingController(text: existingMedication?.instructions ?? '');
    final dosageController = TextEditingController(text: existingMedication?.dosage ?? '1 tablet daily');
    final colorController = TextEditingController(text: existingMedication?.color ?? 'White');
    final shapeController = TextEditingController(text: existingMedication?.shape ?? 'Round');
    final currentStockController = TextEditingController(text: existingMedication?.currentStock.toString() ?? '30');
    final originalStockController = TextEditingController(text: existingMedication?.originalStock.toString() ?? '30');
    final pharmacyController = TextEditingController(text: existingMedication?.pharmacyInfo ?? '');
    final foodRequirementsController = TextEditingController(text: existingMedication?.foodRequirements ?? '');
    
    List<MedicationAlarm> alarms = existingMedication?.alarms.isNotEmpty == true 
        ? List.from(existingMedication!.alarms)
        : [MedicationAlarm(time: '08:00', pillsPerDose: 1)];
    
    String selectedCategory = existingMedication?.category ?? 'daily';
    bool isTemporary = existingMedication?.isTemporary ?? false;
    DateTime? temporaryEndDate = existingMedication?.temporaryEndDate;
    List<String> interactions = List.from(existingMedication?.interactions ?? []);

    return await showDialog<Medication>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingMedication == null ? 'Add Medication' : 'Edit Medication'),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      Text('Basic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Medication Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: instructionsController,
                        decoration: InputDecoration(
                          labelText: 'Instructions',
                          hintText: 'e.g., Take with food',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(height: 16),

                      // Alarms Section
                      Row(
                        children: [
                          Text('Alarm Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Spacer(),
                          IconButton(
                            onPressed: () {
                              setDialogState(() {
                                alarms.add(MedicationAlarm(time: '08:00', pillsPerDose: 1));
                              });
                            },
                            icon: Icon(Icons.add, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ...alarms.asMap().entries.map((entry) {
                        int index = entry.key;
                        MedicationAlarm alarm = entry.value;
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Alarm ${index + 1}'),
                                    Spacer(),
                                    if (alarms.length > 1)
                                      IconButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            alarms.removeAt(index);
                                          });
                                        },
                                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: InkWell(
                                        onTap: () async {
                                          final TimeOfDay? time = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay(
                                              hour: int.parse(alarm.time.split(':')[0]),
                                              minute: int.parse(alarm.time.split(':')[1]),
                                            ),
                                          );
                                          if (time != null) {
                                            final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                            setDialogState(() {
                                              alarms[index] = MedicationAlarm(
                                                time: timeString,
                                                pillsPerDose: alarm.pillsPerDose,
                                                notes: alarm.notes,
                                              );
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.access_time, size: 16),
                                              SizedBox(width: 4),
                                              Text(alarm.time),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(
                                          labelText: 'Pills',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        controller: TextEditingController(text: alarm.pillsPerDose.toString())
                                          ..selection = TextSelection.fromPosition(
                                            TextPosition(offset: alarm.pillsPerDose.toString().length),
                                          ),
                                        onChanged: (value) {
                                          final pills = int.tryParse(value) ?? 1;
                                          setDialogState(() {
                                            alarms[index] = MedicationAlarm(
                                              time: alarm.time,
                                              pillsPerDose: pills,
                                              notes: alarm.notes,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Notes (optional)',
                                    hintText: 'e.g., Take with food',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  controller: TextEditingController(text: alarm.notes ?? '')
                                    ..selection = TextSelection.fromPosition(
                                      TextPosition(offset: (alarm.notes ?? '').length),
                                    ),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      alarms[index] = MedicationAlarm(
                                        time: alarm.time,
                                        pillsPerDose: alarm.pillsPerDose,
                                        notes: value.isNotEmpty ? value : null,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 16),

                      // Stock Information
                      Text('Stock Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: currentStockController,
                              decoration: InputDecoration(
                                labelText: 'Current Stock',
                                border: OutlineInputBorder(),
                                suffixText: 'pills',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: originalStockController,
                              decoration: InputDecoration(
                                labelText: 'Bottle Size',
                                border: OutlineInputBorder(),
                                suffixText: 'pills',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: colorController,
                              decoration: InputDecoration(
                                labelText: 'Color',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: shapeController,
                              decoration: InputDecoration(
                                labelText: 'Shape',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: pharmacyController,
                        decoration: InputDecoration(
                          labelText: 'Pharmacy/Clinic',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: foodRequirementsController,
                        decoration: InputDecoration(
                          labelText: 'Food Requirements',
                          hintText: 'e.g., Take with food',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Category and Temporary
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: ['daily', 'as_needed', 'temporary'].map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.replaceAll('_', ' ').toUpperCase()),
                              )).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedCategory = value!;
                                  isTemporary = value == 'temporary';
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: CheckboxListTile(
                              title: Text('Temporary'),
                              value: isTemporary,
                              onChanged: (value) {
                                setDialogState(() {
                                  isTemporary = value!;
                                  if (isTemporary) {
                                    selectedCategory = 'temporary';
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      if (isTemporary) ...[
                        SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: temporaryEndDate ?? DateTime.now().add(Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                temporaryEndDate = date;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today),
                                SizedBox(width: 8),
                                Text(temporaryEndDate != null
                                    ? 'End Date: ${temporaryEndDate!.day}/${temporaryEndDate!.month}/${temporaryEndDate!.year}'
                                    : 'Select End Date'),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                  onPressed: () {
                    if (nameController.text.isNotEmpty && alarms.isNotEmpty) {
                      final medication = Medication(
                        id: existingMedication?.id,
                        name: nameController.text.trim(),
                        alarms: alarms,
                        currentStock: int.tryParse(currentStockController.text) ?? 30,
                        originalStock: int.tryParse(originalStockController.text) ?? 30,
                        collectionDate: '',
                        daysUntilCollection: 0,
                        instructions: instructionsController.text.trim().isNotEmpty 
                            ? instructionsController.text.trim() 
                            : 'Take as prescribed',
                        dosage: dosageController.text.trim(),
                        color: colorController.text.trim(),
                        shape: shapeController.text.trim(),
                        isTemporary: isTemporary,
                        category: selectedCategory,
                        temporaryEndDate: temporaryEndDate,
                        pharmacyInfo: pharmacyController.text.trim().isNotEmpty 
                            ? pharmacyController.text.trim() 
                            : null,
                        lastRefillDate: DateTime.now(),
                        interactions: interactions.isNotEmpty ? interactions : null,
                        foodRequirements: foodRequirementsController.text.trim().isNotEmpty 
                            ? foodRequirementsController.text.trim() 
                            : null,
                      );
                      Navigator.of(context).pop(medication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill in medication name and at least one alarm')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(existingMedication == null ? 'Add Medication' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateMedicationStock(Medication medication) async {
    final TextEditingController stockController = TextEditingController(
      text: medication.currentStock.toString(),
    );
    String selectedReason = 'Manual adjustment';
    final reasons = [
      'Manual adjustment',
      'New bottle/refill',
      'Found extra pills',
      'Dropped pills',
      'Shared with family',
      'Expired pills removed',
    ];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Update Stock'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update pills for:'),
                  SizedBox(height: 8),
                  Text(medication.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'New stock count',
                      border: OutlineInputBorder(),
                      suffixText: 'pills',
                      helperText: 'Current: ${medication.currentStock} pills',
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: InputDecoration(
                      labelText: 'Reason for change',
                      border: OutlineInputBorder(),
                    ),
                    items: reasons.map((reason) => DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedReason = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stock Impact:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Current: ${medication.currentStock} pills (${medication.daysRemaining} days)'),
                        if (stockController.text.isNotEmpty) ...[
                          Builder(
                            builder: (context) {
                              final newStock = int.tryParse(stockController.text) ?? medication.currentStock;
                              final newDaysRemaining = medication.dailyPillConsumption > 0 
                                  ? (newStock / medication.dailyPillConsumption).floor()
                                  : 0;
                              final change = newStock - medication.currentStock;
                              return Text(
                                'New: $newStock pills ($newDaysRemaining days) ${change >= 0 ? '+' : ''}$change',
                                style: TextStyle(
                                  color: change >= 0 ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newStock = int.tryParse(stockController.text);
                    if (newStock != null && newStock >= 0) {
                      Navigator.of(context).pop({
                        'newStock': newStock,
                        'reason': selectedReason,
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid number')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      try {
        bool success = await _dataManager.adjustMedicationStock(
          medication.id!,
          result['newStock'],
          result['reason'],
        );
        
        if (success) {
          _showSuccessSnackBar('Stock updated successfully');
          await _loadData();
        } else {
          _showErrorSnackBar('Failed to update stock');
        }
      } catch (e) {
        _showErrorSnackBar('Error updating stock: $e');
      }
    }
  }

  Future<void> _deleteMedication(Medication medication) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete:'),
            SizedBox(height: 8),
            Text(medication.name, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will also remove all related alarms and history.',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      try {
        bool success = await _dataManager.deleteMedication(medication.id!);
        if (success) {
          _showSuccessSnackBar('Medication deleted successfully');
          await _loadData();
        } else {
          _showErrorSnackBar('Failed to delete medication');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting medication: $e');
      }
    }
  }

  Widget _buildMedicationCard(Medication medication) {
    final isLowStock = medication.needsRefillSoon;
    final isCritical = medication.isCriticallyLow;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCritical ? Colors.red : (isLowStock ? Colors.orange : Colors.grey[300]!),
          width: isCritical ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isCritical ? Colors.red[50] : (isLowStock ? Colors.orange[50] : Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with medication name and menu
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            medication.name,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                        if (medication.isTemporary)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'TEMPORARY',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(medication.instructions, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    if (medication.pharmacyInfo != null)
                      Text('📍 ${medication.pharmacyInfo}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'stock',
                    child: ListTile(
                      leading: Icon(Icons.inventory),
                      title: Text('Update Stock'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editMedication(medication);
                      break;
                    case 'stock':
                      _updateMedicationStock(medication);
                      break;
                    case 'delete':
                      _deleteMedication(medication);
                      break;
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 12),

          // Alarm schedule
          Text('Schedule:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: medication.alarms.map((alarm) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${alarm.time} (${alarm.pillsPerDose} pills)',
                    style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  if (alarm.notes != null) ...[
                    SizedBox(width: 4),
                    Tooltip(
                      message: alarm.notes!,
                      child: Icon(Icons.info_outline, color: Color(0xFF047857), size: 12),
                    ),
                  ],
                ],
              ),
            )).toList(),
          ),
          SizedBox(height: 16),

          // Stock information
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Pills Remaining', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          if (isCritical || isLowStock) ...[
                            SizedBox(width: 4),
                            Icon(
                              Icons.warning,
                              color: isCritical ? Colors.red : Colors.orange,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${medication.currentStock}/${medication.originalStock}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCritical ? Colors.red[600] : (isLowStock ? Colors.orange[600] : Colors.grey[800]),
                        ),
                      ),
                      Text(
                        '${medication.dailyPillConsumption} per day',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Days Remaining', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      SizedBox(height: 4),
                      Text(
                        '${medication.daysRemaining} days',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCritical ? Colors.red[600] : (isLowStock ? Colors.orange[600] : Colors.grey[800]),
                        ),
                      ),
                      Text(
                        medication.stockWarningLevel == 'normal' ? 'Good supply' : medication.stockWarningMessage.split(' - ')[0],
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Warning message for low stock
          if (isCritical || isLowStock) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCritical ? Colors.red[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isCritical ? Icons.error : Icons.warning,
                    color: isCritical ? Colors.red[700] : Colors.orange[700],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      medication.stockWarningMessage,
                      style: TextStyle(
                        color: isCritical ? Colors.red[700] : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Drug interactions warning
          if (medication.interactions != null && medication.interactions!.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.purple[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Interactions: ${medication.interactions!.join(', ')}',
                      style: TextStyle(color: Colors.purple[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Quick actions
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateMedicationStock(medication),
                  icon: Icon(Icons.inventory, size: 16),
                  label: Text('Update Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, 36),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Quick refill action
                    _dataManager.addMedicationStock(
                      medication.id!,
                      medication.originalStock,
                      'New bottle/refill',
                    ).then((success) {
                      if (success) {
                        _showSuccessSnackBar('Refill added successfully');
                        _loadData();
                      }
                    });
                  },
                  icon: Icon(Icons.add_circle, size: 16),
                  label: Text('Quick Refill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, 36),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isToday = appointment.isToday;
    final isTomorrow = appointment.isTomorrow;
    final isOverdue = appointment.dateTime.isBefore(DateTime.now()) && !appointment.completed;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isOverdue ? Colors.red : (isToday ? Colors.orange : (isTomorrow ? Colors.blue : Colors.grey[300]!)),
          width: (isOverdue || isToday) ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: appointment.completed 
            ? Color(0xFFECFDF5) 
            : (isOverdue ? Colors.red[50] : (isToday ? Colors.orange[50] : (isTomorrow ? Colors.blue[50] : Colors.white))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            appointment.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600, 
                              fontSize: 16,
                              decoration: appointment.completed ? TextDecoration.lineThrough : null,
                              color: appointment.completed ? Color(0xFF047857) : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTypeColor(appointment.type),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            appointment.type.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      appointment.formattedDateTime,
                      style: TextStyle(
                        color: isOverdue ? Colors.red[700] : Colors.grey[600], 
                        fontSize: 14,
                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text('📍 ${appointment.location}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    if (appointment.doctorName != null)
                      Text('👨‍⚕️ ${appointment.doctorName}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  if (!appointment.completed)
                    PopupMenuItem(
                      value: 'complete',
                      child: ListTile(
                        leading: Icon(Icons.check_circle, color: Color(0xFF10B981)),
                        title: Text('Mark Complete'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'complete':
                      _markAppointmentCompleted(appointment);
                      break;
                    case 'edit':
                      _editAppointment(appointment);
                      break;
                    case 'delete':
                      _deleteAppointment(appointment);
                      break;
                  }
                },
              ),
            ],
          ),

          // Status indicators
          if (isToday || isTomorrow || isOverdue || appointment.completed) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appointment.completed 
                    ? Color(0xFFD1FAE5)
                    : (isOverdue ? Colors.red[100] : (isToday ? Colors.orange[100] : Colors.blue[100])),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    appointment.completed 
                        ? Icons.check_circle 
                        : (isOverdue ? Icons.error : Icons.schedule),
                    color: appointment.completed 
                        ? Color(0xFF047857)
                        : (isOverdue ? Colors.red[700] : (isToday ? Colors.orange[700] : Colors.blue[700])),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.completed 
                          ? 'Appointment completed ✓'
                          : (isOverdue ? 'Overdue - Please reschedule' : appointment.reminderMessage),
                      style: TextStyle(
                        color: appointment.completed 
                            ? Color(0xFF047857)
                            : (isOverdue ? Colors.red[700] : (isToday ? Colors.orange[700] : Colors.blue[700])),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Additional details
          if (appointment.notes != null || appointment.phoneNumber != null || appointment.address != null) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (appointment.phoneNumber != null) ...[
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(appointment.phoneNumber!, style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    SizedBox(height: 4),
                  ],
                  if (appointment.address != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(child: Text(appointment.address!, style: TextStyle(fontSize: 14))),
                      ],
                    ),
                    SizedBox(height: 4),
                  ],
                  if (appointment.notes != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(child: Text(appointment.notes!, style: TextStyle(fontSize: 14))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Quick actions
          if (!appointment.completed) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAppointmentCompleted(appointment),
                    icon: Icon(Icons.check_circle, size: 16),
                    label: Text('Mark Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 36),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editAppointment(appointment),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Reschedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 36),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'urgent':
        return Colors.red;
      case 'follow-up':
        return Colors.orange;
      case 'lab':
        return Colors.purple;
      case 'specialist':
        return Colors.indigo;
      default:
        return Color(0xFF10B981);
    }
  }

  Widget _buildInsightsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Overview',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_medicationInsights['active_medications'] ?? 0}', 
                         style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Active Medications', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_appointments.where((apt) => apt.isUpcoming && !apt.completed).length}', 
                         style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Upcoming Appointments', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_medicationInsights['low_stock_count'] ?? 0}', 
                         style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Need Refill', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
            ],
          ),
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
            Text('Loading profile...', style: TextStyle(color: Colors.grey[600])),
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
            Text('Unable to load profile', style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Separate upcoming and completed appointments
    final upcomingAppointments = _appointments.where((apt) => !apt.completed && apt.dateTime.isAfter(DateTime.now())).toList();
    final pastAppointments = _appointments.where((apt) => apt.completed || apt.dateTime.isBefore(DateTime.now())).toList();
    
    // Sort appointments
    upcomingAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    pastAppointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Color(0xFF10B981),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
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
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0D9488)]),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _user!.name[0],
                            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_user!.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('Healthcare Management', style: TextStyle(color: Colors.grey[600])),
                            Text(_user!.location, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                          ],
                        ),
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

            // Health Overview
            _buildInsightsCard(),
            SizedBox(height: 24),

            // My Appointments Section
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _addAppointment,
                        icon: Icon(Icons.add),
                        label: Text('Add Appointment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (_appointments.isEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[400], size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('No appointments scheduled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                Text('Add your medical appointments to stay on track', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Upcoming appointments
                    if (upcomingAppointments.isNotEmpty) ...[
                      Text('Upcoming Appointments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      SizedBox(height: 12),
                      ...upcomingAppointments.map((appointment) => _buildAppointmentCard(appointment)),
                    ],
                    
                    // Past appointments
                    if (pastAppointments.isNotEmpty) ...[
                      if (upcomingAppointments.isNotEmpty) SizedBox(height: 16),
                      Text('Past Appointments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      SizedBox(height: 12),
                      ...pastAppointments.take(3).map((appointment) => _buildAppointmentCard(appointment)),
                      if (pastAppointments.length > 3) ...[
                        SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // Show all past appointments
                            },
                            child: Text('View all past appointments (${pastAppointments.length - 3} more)'),
                          ),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),

            // My Medications
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Medications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _addMedication,
                        icon: Icon(Icons.add),
                        label: Text('Add Medication'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (_medications.isEmpty && _temporaryMedications.isEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.medication, color: Colors.grey[400], size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('No medications added yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                Text('Add your medications to start tracking your health journey', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Regular medications
                    if (_medications.isNotEmpty) ...[
                      Text('Daily Medications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      SizedBox(height: 12),
                      ..._medications.map((med) => _buildMedicationCard(med)),
                    ],
                    
                    // Temporary medications
                    if (_temporaryMedications.isNotEmpty) ...[
                      if (_medications.isNotEmpty) SizedBox(height: 16),
                      Text('Temporary Medications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      SizedBox(height: 12),
                      ..._temporaryMedications.map((med) => _buildMedicationCard(med)),
                    ],
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),

            // Settings
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
                  Text('Settings & Preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  ...['Notification Settings', 'Privacy & Data Security', 'Emergency Contacts', 'Data Backup & Sync', 'Export Health Data']
                      .map((setting) => InkWell(
                        onTap: () {
                          // Implementation for each setting
                          _showSuccessSnackBar('Opening $setting...');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(setting, style: TextStyle(fontSize: 16)),
                              Icon(Icons.chevron_right, color: Colors.grey[400]),
                            ],
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