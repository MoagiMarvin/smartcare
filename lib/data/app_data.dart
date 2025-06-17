import '../models/models.dart';

class AppData {
  static final List<String> motivationalMessages = [
    "Your health matters. Every step counts toward your wellbeing. 💚",
    "Consistency in care leads to better outcomes. You're doing great! 🌟",
    "Remember: Undetectable = Untransmittable. Take care of yourself. ❤️",
    "Your healthcare team is here to support you every step of the way. 🤝",
    "Today is a new opportunity to prioritize your health and wellness. 🌱"
  ];

  static final User user = User(
    name: 'Alex',
    adherenceStreak: 12,
    location: 'Johannesburg, Gauteng',
    nextAppointment: 'June 19, 2025',
    viralLoad: 'Undetectable',
    cd4Count: '650',
  );

  static final List<Medication> medications = [
    Medication(
      id: 1,
      name: 'Efavirenz/Emtricitabine/Tenofovir (Atroiza)',
      times: ['20:00'],
      pillsLeft: 12,
      totalPills: 30,
      collectionDate: 'June 25, 2025',
      daysUntilCollection: 9,
      instructions: 'Take 1 tablet once daily at bedtime',
      dosage: '1 tablet',
      color: 'Orange',
      shape: 'Oval',
      temporary: false,
    ),
    Medication(
      id: 2,
      name: 'Multivitamin',
      times: ['08:00'],
      pillsLeft: 8,
      totalPills: 30,
      collectionDate: 'June 20, 2025',
      daysUntilCollection: 4,
      instructions: 'Take 1 tablet with breakfast',
      dosage: '1 tablet',
      color: 'Yellow',
      shape: 'Round',
      temporary: false,
    ),
  ];

  static final List<DailyTask> dailyTasks = [
    DailyTask(
      id: 1,
      task: 'Take Atroiza (Evening dose)',
      completed: false,
      medicationId: 1,
      time: '20:00',
      category: 'medication',
    ),
    DailyTask(
      id: 2,
      task: 'Take Multivitamin (Morning dose)',
      completed: true,
      medicationId: 2,
      time: '08:00',
      category: 'medication',
    ),
    DailyTask(
      id: 3,
      task: 'Log Daily Wellness Check',
      completed: true,
      category: 'wellness',
    ),
    DailyTask(
      id: 4,
      task: 'Attend Support Group',
      completed: false,
      category: 'social',
    ),
  ];

  static final List<Clinic> nearbyClinics = [
    Clinic(
      id: 1,
      name: 'Charlotte Maxeke Johannesburg Academic Hospital',
      distance: '2.3 km',
      services: ['HIV Care', 'Social Worker', 'Pharmacy'],
      rating: 4.2,
      open: true,
    ),
    Clinic(
      id: 2,
      name: 'Helen Joseph Hospital',
      distance: '5.7 km',
      services: ['HIV Care', 'Counseling', 'Social Worker'],
      rating: 4.0,
      open: true,
    ),
    Clinic(
      id: 3,
      name: 'Rahima Moosa Mother & Child Hospital',
      distance: '8.1 km',
      services: ['HIV Care', 'Pharmacy'],
      rating: 3.8,
      open: false,
    ),
  ];

  static final List<MobileClinic> mobileClinics = [
    MobileClinic(
      id: 1,
      name: 'Community Outreach Mobile Unit',
      location: 'Soweto - Freedom Square',
      date: 'June 17, 2025',
      time: '09:00-15:00',
      services: ['HIV Testing', 'ARV Pickup', 'Counseling'],
    ),
    MobileClinic(
      id: 2,
      name: 'Healthcare on Wheels',
      location: 'Alexandra - 8th Avenue',
      date: 'June 18, 2025',
      time: '08:00-14:00',
      services: ['HIV Care', 'Social Worker', 'Pharmacy'],
    ),
  ];
}