import 'package:smartcare/database/database_helper.dart';
import 'package:smartcare/models/models.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  DataManager._internal();

  factory DataManager() => _instance;

  // Motivational messages (static data)
  static final List<String> motivationalMessages = [
    "Your health matters. Every step counts toward your wellbeing. 💚",
    "Consistency in care leads to better outcomes. You're doing great! 🌟",
    "Remember: Undetectable = Untransmittable. Take care of yourself. ❤️",
    "Your healthcare team is here to support you every step of the way. 🤝",
    "Today is a new opportunity to prioritize your health and wellness. 🌱"
  ];

  // User operations
  Future<User?> getUser() async {
    return await _dbHelper.getUser();
  }

  Future<bool> updateUser(User user) async {
    int result = await _dbHelper.updateUser(user);
    return result > 0;
  }

  Future<bool> updateAdherenceStreak(int newStreak) async {
    User? currentUser = await getUser();
    if (currentUser != null) {
      User updatedUser = currentUser.copyWith(adherenceStreak: newStreak);
      return await updateUser(updatedUser);
    }
    return false;
  }

  // Enhanced medication operations
  Future<List<Medication>> getMedications() async {
    return await _dbHelper.getMedications();
  }

  Future<List<Medication>> getActiveMedications() async {
    return await _dbHelper.getActiveMedications();
  }

  Future<List<Medication>> getTemporaryMedications() async {
    return await _dbHelper.getTemporaryMedications();
  }

  Future<List<Medication>> getLowStockMedications({int daysThreshold = 7}) async {
    return await _dbHelper.getLowStockMedications(threshold: daysThreshold);
  }

  Future<List<Medication>> getCriticalStockMedications() async {
    final medications = await getMedications();
    return medications.where((med) => med.isCriticallyLow).toList();
  }

  Future<bool> addMedication(Medication medication) async {
    int result = await _dbHelper.insertMedication(medication);
    if (result > 0) {
      // Generate daily tasks for the new medication
      await _generateTasksForMedication(medication.copyWith(id: result));
      return true;
    }
    return false;
  }

  Future<bool> updateMedication(Medication medication) async {
    int result = await _dbHelper.updateMedication(medication);
    if (result > 0) {
      // Regenerate tasks for this medication
      await _regenerateTasksForMedication(medication);
      return true;
    }
    return false;
  }

  Future<bool> deleteMedication(int id) async {
    int result = await _dbHelper.deleteMedication(id);
    return result > 0;
  }

  // Medication taking and stock management
  Future<bool> takeMedication(int medicationId, String time, int pillsTaken, {String? notes}) async {
    bool success = await _dbHelper.takeMedication(medicationId, time, pillsTaken, notes: notes);
    
    if (success) {
      // Update adherence streak if needed
      await _updateAdherenceStreakOnMedicationTaken();
    }
    
    return success;
  }

  Future<bool> addMedicationStock(int medicationId, int pillsAdded, String reason) async {
    return await _dbHelper.addStock(medicationId, pillsAdded, reason);
  }

  Future<bool> adjustMedicationStock(int medicationId, int newStock, String reason) async {
    List<Medication> medications = await getMedications();
    Medication? medication = medications.firstWhere(
      (med) => med.id == medicationId,
      orElse: () => throw Exception('Medication not found'),
    );
    
    int difference = newStock - medication.currentStock;
    
    if (difference > 0) {
      return await addMedicationStock(medicationId, difference, reason);
    } else if (difference < 0) {
      // Handle reduction in stock
      return await _dbHelper.addStock(medicationId, difference, reason);
    }
    
    return true; // No change needed
  }

  // Smart medication management
  Future<List<Map<String, dynamic>>> getTodaysMedicationSchedule() async {
    final medications = await getActiveMedications();
    final schedule = <Map<String, dynamic>>[];
    
    for (final medication in medications) {
      for (final alarm in medication.alarms) {
        schedule.add({
          'medication': medication,
          'alarm': alarm,
          'time': alarm.time,
          'pills': alarm.pillsPerDose,
          'notes': alarm.notes,
          'taken': await _wasDoseTakenToday(medication.id!, alarm.time),
        });
      }
    }
    
    // Sort by time
    schedule.sort((a, b) => a['time'].compareTo(b['time']));
    return schedule;
  }

  Future<bool> _wasDoseTakenToday(int medicationId, String time) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final history = await _dbHelper.getMedicationHistory(medicationId, days: 1);
    final doses = history['doses'] as List<MedicationDose>;
    
    return doses.any((dose) => 
      dose.dateTaken.toIso8601String().split('T')[0] == today && 
      dose.time == time
    );
  }

  Future<Map<String, dynamic>> getMedicationInsights() async {
    final medications = await getMedications();
    final lowStock = await getLowStockMedications();
    final critical = await getCriticalStockMedications();
    final temporary = await getTemporaryMedications();
    
    int totalDailyPills = medications
        .where((med) => !med.isTemporary)
        .fold(0, (sum, med) => sum + med.dailyPillConsumption);
    
    return {
      'total_medications': medications.length,
      'active_medications': medications.where((med) => !med.isTemporary).length,
      'temporary_medications': temporary.length,
      'low_stock_count': lowStock.length,
      'critical_stock_count': critical.length,
      'total_daily_pills': totalDailyPills,
      'next_refill_needed': _getNextRefillNeeded(medications),
      'adherence_risks': _getAdherenceRisks(medications),
    };
  }

  String? _getNextRefillNeeded(List<Medication> medications) {
    final activeMeds = medications.where((med) => !med.isTemporary).toList();
    if (activeMeds.isEmpty) return null;
    
    activeMeds.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    final nextMed = activeMeds.first;
    
    if (nextMed.daysRemaining <= 0) {
      return '${nextMed.name} - Refill overdue!';
    } else if (nextMed.daysRemaining <= 7) {
      return '${nextMed.name} - ${nextMed.daysRemaining} days left';
    }
    
    return null;
  }

  List<String> _getAdherenceRisks(List<Medication> medications) {
    final risks = <String>[];
    
    for (final med in medications) {
      if (med.isCriticallyLow) {
        risks.add('${med.name}: Critical stock level');
      }
      
      if (med.interactions != null && med.interactions!.isNotEmpty) {
        risks.add('${med.name}: Has interaction warnings');
      }
      
      if (med.isTemporary && med.temporaryEndDate != null) {
        final daysLeft = med.temporaryEndDate!.difference(DateTime.now()).inDays;
        if (daysLeft <= 1) {
          risks.add('${med.name}: Temporary course ending soon');
        }
      }
    }
    
    return risks;
  }

  // Daily tasks operations with enhanced medication integration
  Future<List<DailyTask>> getDailyTasks([String? date]) async {
    return await _dbHelper.getDailyTasks(date);
  }

  Future<List<DailyTask>> getTodaysTasks() async {
    String today = DateTime.now().toIso8601String().split('T')[0];
    return await getDailyTasks(today);
  }

  Future<bool> addDailyTask(DailyTask task) async {
    int result = await _dbHelper.insertDailyTask(task);
    return result > 0;
  }

  Future<bool> updateDailyTask(DailyTask task) async {
    int result = await _dbHelper.updateDailyTask(task);
    return result > 0;
  }

  Future<bool> completeTask(int taskId) async {
    // Get the task details first
    final tasks = await getTodaysTasks();
    final task = tasks.firstWhere((t) => t.id == taskId, orElse: () => throw Exception('Task not found'));
    
    // If it's a medication task, handle medication taking
    if (task.category == 'medication' && task.medicationId != null && task.pillsToTake != null) {
      bool medicationTaken = await takeMedication(
        task.medicationId!, 
        task.time ?? '00:00', 
        task.pillsToTake!,
        notes: 'Taken via task completion'
      );
      
      if (!medicationTaken) {
        return false; // Failed to take medication (e.g., not enough stock)
      }
    }
    
    // Complete the task
    int result = await _dbHelper.completeDailyTask(taskId);
    
    if (result > 0 && task.category == 'medication') {
      await _updateAdherenceStreakOnTaskCompletion();
    }
    
    return result > 0;
  }

  Future<void> _updateAdherenceStreakOnTaskCompletion() async {
    List<DailyTask> todaysTasks = await getTodaysTasks();
    List<DailyTask> medicationTasks = todaysTasks.where((task) => task.category == 'medication').toList();
    
    bool allMedicationTasksCompleted = medicationTasks.every((task) => task.completed);
    
    if (allMedicationTasksCompleted && medicationTasks.isNotEmpty) {
      User? user = await getUser();
      if (user != null) {
        await updateAdherenceStreak(user.adherenceStreak + 1);
      }
    }
  }

  Future<void> _updateAdherenceStreakOnMedicationTaken() async {
    // Check if all today's medications have been taken
    final schedule = await getTodaysMedicationSchedule();
    final allTaken = schedule.every((item) => item['taken'] == true);
    
    if (allTaken && schedule.isNotEmpty) {
      User? user = await getUser();
      if (user != null) {
        await updateAdherenceStreak(user.adherenceStreak + 1);
      }
    }
  }

  Future<bool> generateDailyTasks() async {
    String today = DateTime.now().toIso8601String().split('T')[0];
    List<DailyTask> existingTasks = await getDailyTasks(today);
    
    if (existingTasks.isNotEmpty) {
      return false; // Tasks already exist for today
    }

    List<Medication> medications = await getActiveMedications();
    List<DailyTask> tasksToAdd = [];

    // Generate medication tasks with enhanced alarm system
    for (Medication medication in medications) {
      for (MedicationAlarm alarm in medication.alarms) {
        String taskDescription = 'Take ${alarm.pillsPerDose} ${medication.name}';
        if (alarm.notes != null) {
          taskDescription += ' (${alarm.notes})';
        }
        
        tasksToAdd.add(DailyTask(
          task: taskDescription,
          completed: false,
          medicationId: medication.id,
          time: alarm.time,
          category: 'medication',
          taskDate: today,
          pillsToTake: alarm.pillsPerDose,
        ));
      }
    }

    // Add default wellness tasks
    tasksToAdd.addAll([
      DailyTask(
        task: 'Log Daily Wellness Check',
        completed: false,
        category: 'wellness',
        taskDate: today,
      ),
      DailyTask(
        task: 'Hydration Check (8 glasses of water)',
        completed: false,
        category: 'wellness',
        taskDate: today,
      ),
    ]);

    // Insert all tasks
    bool allSuccess = true;
    for (DailyTask task in tasksToAdd) {
      bool success = await addDailyTask(task);
      if (!success) allSuccess = false;
    }

    return allSuccess;
  }

  Future<void> _generateTasksForMedication(Medication medication) async {
    String today = DateTime.now().toIso8601String().split('T')[0];
    
    for (MedicationAlarm alarm in medication.alarms) {
      String taskDescription = 'Take ${alarm.pillsPerDose} ${medication.name}';
      if (alarm.notes != null) {
        taskDescription += ' (${alarm.notes})';
      }
      
      await addDailyTask(DailyTask(
        task: taskDescription,
        completed: false,
        medicationId: medication.id,
        time: alarm.time,
        category: 'medication',
        taskDate: today,
        pillsToTake: alarm.pillsPerDose,
      ));
    }
  }

  Future<void> _regenerateTasksForMedication(Medication medication) async {
    // For now, just generate new tasks. In a full implementation,
    // we'd want to update existing tasks for this medication
    await _generateTasksForMedication(medication);
  }

  // Chat operations
  Future<List<ChatMessage>> getChatMessages() async {
    return await _dbHelper.getChatMessages();
  }

  Future<bool> addChatMessage(ChatMessage message) async {
    int result = await _dbHelper.insertChatMessage(message);
    return result > 0;
  }

  Future<bool> clearChatHistory() async {
    try {
      await _dbHelper.clearChatMessages();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Clinic operations
  Future<List<Clinic>> getClinics() async {
    return await _dbHelper.getClinics();
  }

  Future<bool> addClinic(Clinic clinic) async {
    int result = await _dbHelper.insertClinic(clinic);
    return result > 0;
  }

  // Mobile clinic operations
  Future<List<MobileClinic>> getMobileClinics() async {
    return await _dbHelper.getMobileClinics();
  }

  Future<bool> addMobileClinic(MobileClinic clinic) async {
    int result = await _dbHelper.insertMobileClinic(clinic);
    return result > 0;
  }

  // Appointment Management Methods
  Future<List<Appointment>> getAppointments() async {
    return await _dbHelper.getAppointments();
  }

  Future<bool> addAppointment(Appointment appointment) async {
    int result = await _dbHelper.insertAppointment(appointment);
    return result > 0;
  }

  Future<bool> updateAppointment(Appointment appointment) async {
    int result = await _dbHelper.updateAppointment(appointment);
    return result > 0;
  }

  Future<bool> deleteAppointment(int appointmentId) async {
    int result = await _dbHelper.deleteAppointment(appointmentId);
    return result > 0;
  }

  Future<Appointment?> getNextAppointment() async {
    final appointments = await getAppointments();
    final upcomingAppointments = appointments
        .where((apt) => !apt.completed && apt.dateTime.isAfter(DateTime.now()))
        .toList();
    
    if (upcomingAppointments.isEmpty) return null;
    
    upcomingAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcomingAppointments.first;
  }

  Future<List<Appointment>> getUpcomingAppointments({int days = 7}) async {
    final appointments = await getAppointments();
    final endDate = DateTime.now().add(Duration(days: days));
    
    return appointments
        .where((apt) => !apt.completed && 
                      apt.dateTime.isAfter(DateTime.now()) &&
                      apt.dateTime.isBefore(endDate))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<List<Appointment>> getAppointmentReminders() async {
    final appointments = await getAppointments();
    
    return appointments
        .where((apt) => apt.shouldRemind)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Enhanced analytics and insights
  Future<Map<String, dynamic>> getHealthInsights() async {
    User? user = await getUser();
    List<Medication> medications = await getMedications();
    List<DailyTask> todaysTasks = await getTodaysTasks();
    
    int totalTasks = todaysTasks.length;
    int completedTasks = todaysTasks.where((task) => task.completed).length;
    double completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    
    final medicationInsights = await getMedicationInsights();
    
    return {
      'adherence_streak': user?.adherenceStreak ?? 0,
      'tasks_completion_rate': completionRate,
      'completed_tasks_today': completedTasks,
      'total_tasks_today': totalTasks,
      ...medicationInsights,
    };
  }

  Future<Map<String, dynamic>> getMedicationAdherenceStats({int days = 30}) async {
    final medications = await getActiveMedications();
    final stats = <String, dynamic>{};
    
    for (final medication in medications) {
      final history = await _dbHelper.getMedicationHistory(medication.id!, days: days);
      final doses = history['doses'] as List<MedicationDose>;
      
      // Calculate expected vs actual doses
      final expectedDoses = medication.alarms.length * days;
      final actualDoses = doses.length;
      final adherenceRate = expectedDoses > 0 ? (actualDoses / expectedDoses) : 0.0;
      
      stats[medication.name] = {
        'adherence_rate': adherenceRate,
        'expected_doses': expectedDoses,
        'actual_doses': actualDoses,
        'missed_doses': expectedDoses - actualDoses,
        'current_stock': medication.currentStock,
        'days_remaining': medication.daysRemaining,
      };
    }
    
    return stats;
  }

  // Medication interaction checking
  Future<List<String>> checkMedicationInteractions(List<int> medicationIds) async {
    final medications = await getMedications();
    final selectedMeds = medications.where((med) => medicationIds.contains(med.id)).toList();
    final interactions = <String>[];
    
    for (int i = 0; i < selectedMeds.length; i++) {
      for (int j = i + 1; j < selectedMeds.length; j++) {
        if (selectedMeds[i].conflictsWith(selectedMeds[j])) {
          interactions.add('⚠️ ${selectedMeds[i].name} may interact with ${selectedMeds[j].name}');
        }
      }
    }
    
    return interactions;
  }

  // Utility operations
  Future<void> closeDatabase() async {
    await _dbHelper.closeDatabase();
  }

  Future<void> resetDatabase() async {
    await _dbHelper.deleteDatabase();
    // Database will be recreated with default data on next access
  }
}