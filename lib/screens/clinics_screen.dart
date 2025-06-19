import 'package:flutter/material.dart';
import '../services/data_manager.dart';
import '../models/models.dart';

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  _ClinicsScreenState createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  final DataManager _dataManager = DataManager();
  final TextEditingController _searchController = TextEditingController();
  
  List<Clinic> _clinics = [];
  List<MobileClinic> _mobileClinics = [];
  List<Clinic> _filteredClinics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final clinics = await _dataManager.getClinics();
      final mobileClinics = await _dataManager.getMobileClinics();
      
      setState(() {
        _clinics = clinics;
        _mobileClinics = mobileClinics;
        _filteredClinics = clinics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load clinics: $e');
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

  void _filterClinics(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClinics = _clinics;
      } else {
        _filteredClinics = _clinics.where((clinic) {
          return clinic.name.toLowerCase().contains(query.toLowerCase()) ||
                 clinic.distance.toLowerCase().contains(query.toLowerCase()) ||
                 clinic.services.any((service) => service.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  Future<void> _addNewClinic() async {
    final nameController = TextEditingController();
    final distanceController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final ratingController = TextEditingController(text: '4.0');
    
    List<String> selectedServices = [];
    bool isOpen = true;

    final availableServices = [
      'HIV Care', 'Social Worker', 'Pharmacy', 'Counseling', 
      'Emergency Services', 'Laboratory', 'Radiology', 'Dentistry'
    ];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add New Clinic'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Clinic Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: distanceController,
                            decoration: InputDecoration(
                              labelText: 'Distance',
                              border: OutlineInputBorder(),
                              suffixText: 'km',
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: ratingController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Rating',
                              border: OutlineInputBorder(),
                              suffixText: '/5',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Currently Open:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Switch(
                          value: isOpen,
                          onChanged: (value) {
                            setDialogState(() {
                              isOpen = value;
                            });
                          },
                          activeColor: Color(0xFF10B981),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: availableServices.map((service) {
                        bool isSelected = selectedServices.contains(service);
                        return FilterChip(
                          label: Text(service),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedServices.add(service);
                              } else {
                                selectedServices.remove(service);
                              }
                            });
                          },
                          selectedColor: Color(0xFFECFDF5),
                          checkmarkColor: Color(0xFF10B981),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && selectedServices.isNotEmpty) {
                      Navigator.of(context).pop({
                        'name': nameController.text,
                        'distance': distanceController.text.isNotEmpty ? '${distanceController.text} km' : 'Unknown',
                        'services': selectedServices,
                        'rating': double.tryParse(ratingController.text) ?? 4.0,
                        'open': isOpen,
                        'phone': phoneController.text,
                        'address': addressController.text,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      try {
        final clinic = Clinic(
          name: result['name'],
          distance: result['distance'],
          services: result['services'],
          rating: result['rating'],
          open: result['open'],
          phone: result['phone'].isNotEmpty ? result['phone'] : null,
          address: result['address'].isNotEmpty ? result['address'] : null,
        );

        bool success = await _dataManager.addClinic(clinic);
        
        if (success) {
          _showSuccessSnackBar('Clinic added successfully');
          await _loadData(); // Refresh data
        } else {
          _showErrorSnackBar('Failed to add clinic');
        }
      } catch (e) {
        _showErrorSnackBar('Error adding clinic: $e');
      }
    }
  }

  Future<void> _setMobileClinicReminder(MobileClinic clinic) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reminder Set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reminder set for:'),
              SizedBox(height: 8),
              Text(clinic.name, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('📍 ${clinic.location}'),
              Text('📅 ${clinic.date} at ${clinic.time}'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will be notified 1 hour before the mobile clinic arrives.',
                        style: TextStyle(color: Color(0xFF047857)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: Text('OK'),
            ),
          ],
        );
      },
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
            Text('Loading healthcare facilities...', style: TextStyle(color: Colors.grey[600])),
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
            // Search
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
                  Text('Find Healthcare Facilities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name, distance, or services...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                            ),
                          ),
                          onChanged: _filterClinics,
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _addNewClinic,
                        icon: Icon(Icons.add),
                        label: Text('Add Clinic'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Nearby Clinics
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
                      Icon(Icons.location_on, color: Colors.red, size: 24),
                      SizedBox(width: 8),
                      Text('Healthcare Facilities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Text('${_filteredClinics.length} found', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (_filteredClinics.isEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_off, color: Colors.grey[400], size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('No clinics found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                Text('Try adjusting your search terms or add a new clinic', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._filteredClinics.map((clinic) => Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  clinic.name,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: clinic.open ? Color(0xFF10B981) : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    clinic.open ? 'Open' : 'Closed',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text('📍 ${clinic.distance} away', style: TextStyle(color: Colors.grey[600])),
                              SizedBox(width: 16),
                              Text('⭐ ${clinic.rating}/5', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                          if (clinic.address != null) ...[
                            SizedBox(height: 4),
                            Text('📍 ${clinic.address}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: clinic.services.map((service) => Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(service, style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                            )).toList(),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              if (clinic.phone != null)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showSuccessSnackBar('Calling ${clinic.phone}...');
                                    },
                                    icon: Icon(Icons.phone, size: 16),
                                    label: Text('Call'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      minimumSize: Size(80, 36),
                                    ),
                                  ),
                                ),
                              if (clinic.phone != null) SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showSuccessSnackBar('Opening directions to ${clinic.name}...');
                                  },
                                  icon: Icon(Icons.directions, size: 16),
                                  label: Text('Directions'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF0D9488),
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(80, 36),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Mobile Clinics
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
                      Icon(Icons.local_shipping, color: Color(0xFF10B981), size: 24),
                      SizedBox(width: 8),
                      Text('Mobile Healthcare Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (_mobileClinics.isEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, color: Colors.grey[400], size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('No mobile clinics scheduled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                Text('Check back later for updates', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._mobileClinics.map((clinic) => Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFECFDF5),
                        border: Border.all(color: Color(0xFF10B981)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clinic.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('📍 ${clinic.location}', style: TextStyle(color: Colors.grey[600])),
                          Text('📅 ${clinic.date} • ⏰ ${clinic.time}', style: TextStyle(color: Colors.grey[600])),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: clinic.services.map((service) => Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFFA7F3D0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(service, style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                            )).toList(),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _setMobileClinicReminder(clinic),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Set Reminder'),
                          ),
                        ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}