import 'dart:convert';

class ChatMessage {
  final int? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      text: map['text'],
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class MedicationAlarm {
  final String time; // "08:00"
  final int pillsPerDose; // 2 pills in the morning
  final String? notes; // "Take with food"

  MedicationAlarm({
    required this.time,
    required this.pillsPerDose,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'pillsPerDose': pillsPerDose,
      'notes': notes,
    };
  }

  factory MedicationAlarm.fromMap(Map<String, dynamic> map) {
    return MedicationAlarm(
      time: map['time'],
      pillsPerDose: map['pillsPerDose'],
      notes: map['notes'],
    );
  }
}

class Medication {
  final int? id;
  final String name;
  final List<MedicationAlarm> alarms;
  final int currentStock; // Current pills remaining
  final int originalStock; // Pills when bottle was new/refilled
  final String? collectionDate;
  final int daysUntilCollection;
  final String instructions;
  final String dosage;
  final String color;
  final String shape;
  final bool isTemporary; // For cold/flu medications
  final String category; // 'daily', 'as_needed', 'temporary'
  final DateTime? temporaryEndDate;
  final String? pharmacyInfo;
  final DateTime lastRefillDate;
  final List<String>? interactions; // Drug interactions to warn about
  final String? foodRequirements; // "Take with food", "Empty stomach"

  Medication({
    this.id,
    required this.name,
    required this.alarms,
    required this.currentStock,
    required this.originalStock,
    this.collectionDate,
    required this.daysUntilCollection,
    required this.instructions,
    required this.dosage,
    required this.color,
    required this.shape,
    this.isTemporary = false,
    this.category = 'daily',
    this.temporaryEndDate,
    this.pharmacyInfo,
    required this.lastRefillDate,
    this.interactions,
    this.foodRequirements,
  });

  // Calculate daily pill consumption
  int get dailyPillConsumption {
    return alarms.fold(0, (sum, alarm) => sum + alarm.pillsPerDose);
  }

  // Calculate days remaining based on current stock and daily usage
  int get daysRemaining {
    if (dailyPillConsumption == 0) return 0;
    return (currentStock / dailyPillConsumption).floor();
  }

  // Check if medication needs refill soon
  bool get needsRefillSoon {
    return daysRemaining <= 7; // Warning when 7 days or less remaining
  }

  // Check if medication is critically low
  bool get isCriticallyLow {
    return daysRemaining <= 2; // Critical when 2 days or less
  }

  // Get warning level for stock
  String get stockWarningLevel {
    if (isCriticallyLow) return 'critical';
    if (needsRefillSoon) return 'warning';
    return 'normal';
  }

  // Get formatted stock warning message
  String get stockWarningMessage {
    if (isCriticallyLow) {
      return 'Critical: Only $daysRemaining days left - Call pharmacy today!';
    } else if (needsRefillSoon) {
      return 'Warning: $daysRemaining days remaining - Order refill soon';
    } else {
      return '$daysRemaining days supply remaining';
    }
  }

  // Check if this medication conflicts with another
  bool conflictsWith(Medication other) {
    if (interactions == null) return false;
    return interactions!.any((interaction) => 
      other.name.toLowerCase().contains(interaction.toLowerCase()));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'alarms': jsonEncode(alarms.map((alarm) => alarm.toMap()).toList()),
      'current_stock': currentStock,
      'original_stock': originalStock,
      'collection_date': collectionDate,
      'days_until_collection': daysUntilCollection,
      'instructions': instructions,
      'dosage': dosage,
      'color': color,
      'shape': shape,
      'is_temporary': isTemporary ? 1 : 0,
      'category': category,
      'temporary_end_date': temporaryEndDate?.toIso8601String(),
      'pharmacy_info': pharmacyInfo,
      'last_refill_date': lastRefillDate.toIso8601String(),
      'interactions': interactions != null ? jsonEncode(interactions!) : null,
      'food_requirements': foodRequirements,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    List<dynamic> alarmsJson = jsonDecode(map['alarms']);
    List<MedicationAlarm> alarms = alarmsJson
        .map((alarmMap) => MedicationAlarm.fromMap(alarmMap))
        .toList();

    return Medication(
      id: map['id'],
      name: map['name'],
      alarms: alarms,
      currentStock: map['current_stock'],
      originalStock: map['original_stock'],
      collectionDate: map['collection_date'],
      daysUntilCollection: map['days_until_collection'],
      instructions: map['instructions'],
      dosage: map['dosage'],
      color: map['color'],
      shape: map['shape'],
      isTemporary: map['is_temporary'] == 1,
      category: map['category'] ?? 'daily',
      temporaryEndDate: map['temporary_end_date'] != null 
          ? DateTime.parse(map['temporary_end_date']) 
          : null,
      pharmacyInfo: map['pharmacy_info'],
      lastRefillDate: DateTime.parse(map['last_refill_date']),
      interactions: map['interactions'] != null 
          ? List<String>.from(jsonDecode(map['interactions'])) 
          : null,
      foodRequirements: map['food_requirements'],
    );
  }

  Medication copyWith({
    int? id,
    String? name,
    List<MedicationAlarm>? alarms,
    int? currentStock,
    int? originalStock,
    String? collectionDate,
    int? daysUntilCollection,
    String? instructions,
    String? dosage,
    String? color,
    String? shape,
    bool? isTemporary,
    String? category,
    DateTime? temporaryEndDate,
    String? pharmacyInfo,
    DateTime? lastRefillDate,
    List<String>? interactions,
    String? foodRequirements,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      alarms: alarms ?? this.alarms,
      currentStock: currentStock ?? this.currentStock,
      originalStock: originalStock ?? this.originalStock,
      collectionDate: collectionDate ?? this.collectionDate,
      daysUntilCollection: daysUntilCollection ?? this.daysUntilCollection,
      instructions: instructions ?? this.instructions,
      dosage: dosage ?? this.dosage,
      color: color ?? this.color,
      shape: shape ?? this.shape,
      isTemporary: isTemporary ?? this.isTemporary,
      category: category ?? this.category,
      temporaryEndDate: temporaryEndDate ?? this.temporaryEndDate,
      pharmacyInfo: pharmacyInfo ?? this.pharmacyInfo,
      lastRefillDate: lastRefillDate ?? this.lastRefillDate,
      interactions: interactions ?? this.interactions,
      foodRequirements: foodRequirements ?? this.foodRequirements,
    );
  }

  // Legacy compatibility - get times as simple list
  List<String> get times {
    return alarms.map((alarm) => alarm.time).toList();
  }

  // Legacy compatibility - get total pills left (old name)
  int get pillsLeft => currentStock;

  // Legacy compatibility - get total pills (old name)  
  int get totalPills => originalStock;
}

// NEW: Appointment model
class Appointment {
  final int? id;
  final String title;
  final DateTime dateTime;
  final String location;
  final String? doctorName;
  final String type; // 'routine', 'urgent', 'follow-up', 'lab', 'specialist'
  final String? notes;
  final String? phoneNumber;
  final bool completed;
  final DateTime? reminderDate;
  final String status; // 'scheduled', 'completed', 'cancelled', 'rescheduled'
  final String? address;
  final Duration? estimatedDuration;

  Appointment({
    this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    this.doctorName,
    this.type = 'routine',
    this.notes,
    this.phoneNumber,
    this.completed = false,
    this.reminderDate,
    this.status = 'scheduled',
    this.address,
    this.estimatedDuration,
  });

  // Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }

  // Check if appointment is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return dateTime.year == tomorrow.year &&
           dateTime.month == tomorrow.month &&
           dateTime.day == tomorrow.day;
  }

  // Check if appointment is upcoming (within next 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final inAWeek = now.add(Duration(days: 7));
    return dateTime.isAfter(now) && dateTime.isBefore(inAWeek);
  }

  // Get days until appointment
  int get daysUntil {
    final now = DateTime.now();
    final difference = dateTime.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  // Check if reminder should be shown
  bool get shouldRemind {
    final daysUntil = this.daysUntil;
    return daysUntil <= 3 && daysUntil >= 0 && !completed;
  }

  // Get reminder message
  String get reminderMessage {
    final days = daysUntil;
    if (days == 0) return 'Today: $title at ${_formatTime(dateTime)}';
    if (days == 1) return 'Tomorrow: $title at ${_formatTime(dateTime)}';
    return 'In $days days: $title';
  }

  // Format time for display
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Get formatted date and time
  String get formattedDateTime {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final time = _formatTime(dateTime);
    return '$month $day at $time';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date_time': dateTime.toIso8601String(),
      'location': location,
      'doctor_name': doctorName,
      'type': type,
      'notes': notes,
      'phone_number': phoneNumber,
      'completed': completed ? 1 : 0,
      'reminder_date': reminderDate?.toIso8601String(),
      'status': status,
      'address': address,
      'estimated_duration_minutes': estimatedDuration?.inMinutes,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      title: map['title'],
      dateTime: DateTime.parse(map['date_time']),
      location: map['location'],
      doctorName: map['doctor_name'],
      type: map['type'] ?? 'routine',
      notes: map['notes'],
      phoneNumber: map['phone_number'],
      completed: map['completed'] == 1,
      reminderDate: map['reminder_date'] != null ? DateTime.parse(map['reminder_date']) : null,
      status: map['status'] ?? 'scheduled',
      address: map['address'],
      estimatedDuration: map['estimated_duration_minutes'] != null 
          ? Duration(minutes: map['estimated_duration_minutes']) 
          : null,
    );
  }

  Appointment copyWith({
    int? id,
    String? title,
    DateTime? dateTime,
    String? location,
    String? doctorName,
    String? type,
    String? notes,
    String? phoneNumber,
    bool? completed,
    DateTime? reminderDate,
    String? status,
    String? address,
    Duration? estimatedDuration,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      doctorName: doctorName ?? this.doctorName,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      completed: completed ?? this.completed,
      reminderDate: reminderDate ?? this.reminderDate,
      status: status ?? this.status,
      address: address ?? this.address,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }
}

class MedicationDose {
  final int? id;
  final int medicationId;
  final String time; // "08:00"
  final int pillsTaken;
  final int pillsScheduled;
  final DateTime dateTaken;
  final bool wasOnTime;
  final String? notes; // "Took with breakfast", "Forgot and took late"

  MedicationDose({
    this.id,
    required this.medicationId,
    required this.time,
    required this.pillsTaken,
    required this.pillsScheduled,
    required this.dateTaken,
    this.wasOnTime = true,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'time': time,
      'pills_taken': pillsTaken,
      'pills_scheduled': pillsScheduled,
      'date_taken': dateTaken.toIso8601String().split('T')[0], // Date only
      'was_on_time': wasOnTime ? 1 : 0,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory MedicationDose.fromMap(Map<String, dynamic> map) {
    return MedicationDose(
      id: map['id'],
      medicationId: map['medication_id'],
      time: map['time'],
      pillsTaken: map['pills_taken'],
      pillsScheduled: map['pills_scheduled'],
      dateTaken: DateTime.parse(map['date_taken']),
      wasOnTime: map['was_on_time'] == 1,
      notes: map['notes'],
    );
  }
}

class DailyTask {
  final int? id;
  final String task;
  final bool completed;
  final int? medicationId;
  final String? time;
  final String category;
  final String? taskDate;
  final int? pillsToTake; // How many pills for medication tasks

  DailyTask({
    this.id,
    required this.task,
    required this.completed,
    this.medicationId,
    this.time,
    required this.category,
    this.taskDate,
    this.pillsToTake,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'completed': completed ? 1 : 0,
      'medication_id': medicationId,
      'time': time,
      'category': category,
      'task_date': taskDate ?? DateTime.now().toIso8601String().split('T')[0],
      'pills_to_take': pillsToTake,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'],
      task: map['task'],
      completed: map['completed'] == 1,
      medicationId: map['medication_id'],
      time: map['time'],
      category: map['category'],
      taskDate: map['task_date'],
      pillsToTake: map['pills_to_take'],
    );
  }

  DailyTask copyWith({
    int? id,
    String? task,
    bool? completed,
    int? medicationId,
    String? time,
    String? category,
    String? taskDate,
    int? pillsToTake,
  }) {
    return DailyTask(
      id: id ?? this.id,
      task: task ?? this.task,
      completed: completed ?? this.completed,
      medicationId: medicationId ?? this.medicationId,
      time: time ?? this.time,
      category: category ?? this.category,
      taskDate: taskDate ?? this.taskDate,
      pillsToTake: pillsToTake ?? this.pillsToTake,
    );
  }
}

class Clinic {
  final int? id;
  final String name;
  final String distance;
  final List<String> services;
  final double rating;
  final bool open;
  final String? phone;
  final String? address;

  Clinic({
    this.id,
    required this.name,
    required this.distance,
    required this.services,
    required this.rating,
    required this.open,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'distance': distance,
      'services': jsonEncode(services),
      'rating': rating,
      'is_open': open ? 1 : 0,
      'phone': phone,
      'address': address,
    };
  }

  factory Clinic.fromMap(Map<String, dynamic> map) {
    return Clinic(
      id: map['id'],
      name: map['name'],
      distance: map['distance'],
      services: List<String>.from(jsonDecode(map['services'])),
      rating: map['rating'].toDouble(),
      open: map['is_open'] == 1,
      phone: map['phone'],
      address: map['address'],
    );
  }
}

class MobileClinic {
  final int? id;
  final String name;
  final String location;
  final String date;
  final String time;
  final List<String> services;

  MobileClinic({
    this.id,
    required this.name,
    required this.location,
    required this.date,
    required this.time,
    required this.services,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'date': date,
      'time': time,
      'services': jsonEncode(services),
    };
  }

  factory MobileClinic.fromMap(Map<String, dynamic> map) {
    return MobileClinic(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      date: map['date'],
      time: map['time'],
      services: List<String>.from(jsonDecode(map['services'])),
    );
  }
}

// UPDATED: User model without hardcoded nextAppointment
class User {
  final int? id;
  final String name;
  final int adherenceStreak;
  final String location;
  final String viralLoad;
  final String cd4Count;

  User({
    this.id,
    required this.name,
    required this.adherenceStreak,
    required this.location,
    required this.viralLoad,
    required this.cd4Count,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'adherence_streak': adherenceStreak,
      'location': location,
      'viral_load': viralLoad,
      'cd4_count': cd4Count,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      adherenceStreak: map['adherence_streak'],
      location: map['location'],
      viralLoad: map['viral_load'],
      cd4Count: map['cd4_count'],
    );
  }

  User copyWith({
    int? id,
    String? name,
    int? adherenceStreak,
    String? location,
    String? viralLoad,
    String? cd4Count,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      adherenceStreak: adherenceStreak ?? this.adherenceStreak,
      location: location ?? this.location,
      viralLoad: viralLoad ?? this.viralLoad,
      cd4Count: cd4Count ?? this.cd4Count,
    );
  }
}