import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/data_manager.dart';

class EnhancedMedicationForm extends StatefulWidget {
  final Medication? existingMedication;
  final Function(Medication) onSave;

  const EnhancedMedicationForm({
    super.key,
    this.existingMedication,
    required this.onSave,
  });

  @override
  _EnhancedMedicationFormState createState() => _EnhancedMedicationFormState();
}

class _EnhancedMedicationFormState extends State<EnhancedMedicationForm> {
  final _formKey = GlobalKey<FormState>();
  final DataManager _dataManager = DataManager();
  
  // Controllers
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _dosageController = TextEditingController();
  final _colorController = TextEditingController();
  final _shapeController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _originalStockController = TextEditingController();
  final _pharmacyController = TextEditingController();
  final _foodRequirementsController = TextEditingController();
  
  // State variables
  List<MedicationAlarm> _alarms = [];
  String _selectedCategory = 'daily';
  bool _isTemporary = false;
  DateTime? _temporaryEndDate;
  DateTime _lastRefillDate = DateTime.now();
  List<String> _interactions = [];
  bool _isLoading = false;

  // Available options
  final List<String> _categories = ['daily', 'as_needed', 'temporary'];
  final List<String> _colors = ['White', 'Yellow', 'Orange', 'Pink', 'Blue', 'Green', 'Red', 'Brown'];
  final List<String> _shapes = ['Round', 'Oval', 'Square', 'Capsule', 'Triangle'];
  final List<String> _commonInteractions = [
    'Alcohol', 'Warfarin', 'Aspirin', 'Antacids', 'Grapefruit juice',
    'Iron supplements', 'Calcium', 'Magnesium', 'Ibuprofen', 'Paracetamol'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingMedication != null) {
      _populateExistingData();
    } else {
      // Add default alarm for new medications
      _alarms.add(MedicationAlarm(time: '08:00', pillsPerDose: 1));
    }
  }

  void _populateExistingData() {
    final med = widget.existingMedication!;
    _nameController.text = med.name;
    _instructionsController.text = med.instructions;
    _dosageController.text = med.dosage;
    _colorController.text = med.color;
    _shapeController.text = med.shape;
    _currentStockController.text = med.currentStock.toString();
    _originalStockController.text = med.originalStock.toString();
    _pharmacyController.text = med.pharmacyInfo ?? '';
    _foodRequirementsController.text = med.foodRequirements ?? '';
    
    _alarms = List.from(med.alarms);
    _selectedCategory = med.category;
    _isTemporary = med.isTemporary;
    _temporaryEndDate = med.temporaryEndDate;
    _lastRefillDate = med.lastRefillDate;
    _interactions = List.from(med.interactions ?? []);
  }

  void _addAlarm() {
    setState(() {
      _alarms.add(MedicationAlarm(time: '08:00', pillsPerDose: 1));
    });
  }

  void _removeAlarm(int index) {
    if (_alarms.length > 1) {
      setState(() {
        _alarms.removeAt(index);
      });
    }
  }

  void _updateAlarm(int index, MedicationAlarm alarm) {
    setState(() {
      _alarms[index] = alarm;
    });
  }

  Future<void> _selectTime(int alarmIndex) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_alarms[alarmIndex].time.split(':')[0]),
        minute: int.parse(_alarms[alarmIndex].time.split(':')[1]),
      ),
    );

    if (time != null) {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      _updateAlarm(alarmIndex, MedicationAlarm(
        time: timeString,
        pillsPerDose: _alarms[alarmIndex].pillsPerDose,
        notes: _alarms[alarmIndex].notes,
      ));
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _temporaryEndDate ?? DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _temporaryEndDate = date;
      });
    }
  }

  Future<void> _selectRefillDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _lastRefillDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _lastRefillDate = date;
      });
    }
  }

  void _toggleInteraction(String interaction) {
    setState(() {
      if (_interactions.contains(interaction)) {
        _interactions.remove(interaction);
      } else {
        _interactions.add(interaction);
      }
    });
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_alarms.isEmpty) {
      _showError('Please add at least one alarm time.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final medication = Medication(
        id: widget.existingMedication?.id,
        name: _nameController.text.trim(),
        alarms: _alarms,
        currentStock: int.parse(_currentStockController.text),
        originalStock: int.parse(_originalStockController.text),
        collectionDate: '', // Will be calculated based on stock
        daysUntilCollection: 0, // Will be calculated
        instructions: _instructionsController.text.trim(),
        dosage: _dosageController.text.trim(),
        color: _colorController.text.trim(),
        shape: _shapeController.text.trim(),
        isTemporary: _isTemporary,
        category: _selectedCategory,
        temporaryEndDate: _temporaryEndDate,
        pharmacyInfo: _pharmacyController.text.trim().isNotEmpty ? _pharmacyController.text.trim() : null,
        lastRefillDate: _lastRefillDate,
        interactions: _interactions.isNotEmpty ? _interactions : null,
        foodRequirements: _foodRequirementsController.text.trim().isNotEmpty ? _foodRequirementsController.text.trim() : null,
      );

      widget.onSave(medication);
      Navigator.of(context).pop();
    } catch (e) {
      _showError('Error saving medication: $e');
    }

    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildAlarmCard(int index) {
    final alarm = _alarms[index];
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Alarm ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                if (_alarms.length > 1)
                  IconButton(
                    onPressed: () => _removeAlarm(index),
                    icon: Icon(Icons.delete, color: Colors.red),
                    iconSize: 20,
                  ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _selectTime(index),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time),
                          SizedBox(width: 8),
                          Text(alarm.time, style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: alarm.pillsPerDose.toString(),
                    decoration: InputDecoration(
                      labelText: 'Pills',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final pills = int.tryParse(value) ?? 1;
                      _updateAlarm(index, MedicationAlarm(
                        time: alarm.time,
                        pillsPerDose: pills,
                        notes: alarm.notes,
                      ));
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextFormField(
              initialValue: alarm.notes ?? '',
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Take with food, Before bed',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _updateAlarm(index, MedicationAlarm(
                  time: alarm.time,
                  pillsPerDose: alarm.pillsPerDose,
                  notes: value.isNotEmpty ? value : null,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingMedication == null ? 'Add Medication' : 'Edit Medication'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Medication Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _instructionsController,
                        decoration: InputDecoration(
                          labelText: 'Instructions *',
                          hintText: 'e.g., Take with food, avoid alcohol',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories.map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.replaceAll('_', ' ').toUpperCase()),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                  _isTemporary = value == 'temporary';
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: CheckboxListTile(
                              title: Text('Temporary'),
                              value: _isTemporary,
                              onChanged: (value) {
                                setState(() {
                                  _isTemporary = value!;
                                  if (_isTemporary) {
                                    _selectedCategory = 'temporary';
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_isTemporary) ...[
                        SizedBox(height: 16),
                        InkWell(
                          onTap: _selectEndDate,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today),
                                SizedBox(width: 8),
                                Text(_temporaryEndDate != null
                                    ? 'End Date: ${_temporaryEndDate!.day}/${_temporaryEndDate!.month}/${_temporaryEndDate!.year}'
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
              SizedBox(height: 16),

              // Dosage & Appearance
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dosage & Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _dosageController,
                        decoration: InputDecoration(
                          labelText: 'Dosage Description',
                          hintText: 'e.g., 1 tablet twice daily',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _colors.contains(_colorController.text) ? _colorController.text : null,
                              decoration: InputDecoration(
                                labelText: 'Color',
                                border: OutlineInputBorder(),
                              ),
                              items: _colors.map((color) => DropdownMenuItem(
                                value: color,
                                child: Text(color),
                              )).toList(),
                              onChanged: (value) => _colorController.text = value ?? '',
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _shapes.contains(_shapeController.text) ? _shapeController.text : null,
                              decoration: InputDecoration(
                                labelText: 'Shape',
                                border: OutlineInputBorder(),
                              ),
                              items: _shapes.map((shape) => DropdownMenuItem(
                                value: shape,
                                child: Text(shape),
                              )).toList(),
                              onChanged: (value) => _shapeController.text = value ?? '',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _foodRequirementsController,
                        decoration: InputDecoration(
                          labelText: 'Food Requirements',
                          hintText: 'e.g., Take with food, Empty stomach',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Alarm Schedule
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Alarm Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Spacer(),
                          ElevatedButton.icon(
                            onPressed: _addAlarm,
                            icon: Icon(Icons.add, size: 16),
                            label: Text('Add Alarm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ..._alarms.asMap().entries.map((entry) => _buildAlarmCard(entry.key)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Stock Management
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stock Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _currentStockController,
                              decoration: InputDecoration(
                                labelText: 'Current Stock *',
                                border: OutlineInputBorder(),
                                suffixText: 'pills',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final num = int.tryParse(value ?? '');
                                return num == null || num < 0 ? 'Enter valid number' : null;
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _originalStockController,
                              decoration: InputDecoration(
                                labelText: 'Full Bottle Size *',
                                border: OutlineInputBorder(),
                                suffixText: 'pills',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final num = int.tryParse(value ?? '');
                                return num == null || num <= 0 ? 'Enter valid number' : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      InkWell(
                        onTap: _selectRefillDate,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today),
                              SizedBox(width: 8),
                              Text('Last Refill: ${_lastRefillDate.day}/${_lastRefillDate.month}/${_lastRefillDate.year}'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _pharmacyController,
                        decoration: InputDecoration(
                          labelText: 'Pharmacy/Clinic',
                          hintText: 'Where you get this medication',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Drug Interactions
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Drug Interactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Select substances that may interact with this medication:', 
                           style: TextStyle(color: Colors.grey[600])),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _commonInteractions.map((interaction) {
                          final isSelected = _interactions.contains(interaction);
                          return FilterChip(
                            label: Text(interaction),
                            selected: isSelected,
                            onSelected: (_) => _toggleInteraction(interaction),
                            selectedColor: Colors.red[100],
                            checkmarkColor: Colors.red[600],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.existingMedication == null ? 'Add Medication' : 'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _dosageController.dispose();
    _colorController.dispose();
    _shapeController.dispose();
    _currentStockController.dispose();
    _originalStockController.dispose();
    _pharmacyController.dispose();
    _foodRequirementsController.dispose();
    super.dispose();
  }
}