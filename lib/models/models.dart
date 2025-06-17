class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class Medication {
  final int id;
  final String name;
  final List<String> times;
  final int pillsLeft;
  final int totalPills;
  final String collectionDate;
  final int daysUntilCollection;
  final String instructions;
  final String dosage;
  final String color;
  final String shape;
  final bool temporary;

  Medication({
    required this.id,
    required this.name,
    required this.times,
    required this.pillsLeft,
    required this.totalPills,
    required this.collectionDate,
    required this.daysUntilCollection,
    required this.instructions,
    required this.dosage,
    required this.color,
    required this.shape,
    required this.temporary,
  });

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      times: List<String>.from(map['times']),
      pillsLeft: map['pillsLeft'],
      totalPills: map['totalPills'],
      collectionDate: map['collectionDate'],
      daysUntilCollection: map['daysUntilCollection'],
      instructions: map['instructions'],
      dosage: map['dosage'],
      color: map['color'],
      shape: map['shape'],
      temporary: map['temporary'],
    );
  }
}

class DailyTask {
  final int id;
  final String task;
  final bool completed;
  final int? medicationId;
  final String? time;
  final String category;

  DailyTask({
    required this.id,
    required this.task,
    required this.completed,
    this.medicationId,
    this.time,
    required this.category,
  });
}

class Clinic {
  final int id;
  final String name;
  final String distance;
  final List<String> services;
  final double rating;
  final bool open;

  Clinic({
    required this.id,
    required this.name,
    required this.distance,
    required this.services,
    required this.rating,
    required this.open,
  });
}

class MobileClinic {
  final int id;
  final String name;
  final String location;
  final String date;
  final String time;
  final List<String> services;

  MobileClinic({
    required this.id,
    required this.name,
    required this.location,
    required this.date,
    required this.time,
    required this.services,
  });
}

class User {
  final String name;
  final int adherenceStreak;
  final String location;
  final String nextAppointment;
  final String viralLoad;
  final String cd4Count;

  User({
    required this.name,
    required this.adherenceStreak,
    required this.location,
    required this.nextAppointment,
    required this.viralLoad,
    required this.cd4Count,
  });
}
