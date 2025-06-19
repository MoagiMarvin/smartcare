// This file is now mostly replaced by the database
// Only keeping motivational messages as they are static content

class AppData {
  static final List<String> motivationalMessages = [
    "Your health matters. Every step counts toward your wellbeing. 💚",
    "Consistency in care leads to better outcomes. You're doing great! 🌟",
    "Remember: Undetectable = Untransmittable. Take care of yourself. ❤️",
    "Your healthcare team is here to support you every step of the way. 🤝",
    "Today is a new opportunity to prioritize your health and wellness. 🌱"
  ];

  // All other data is now stored in and retrieved from the local SQLite database
  // See DatabaseHelper and DataManager for data operations
}