

class BrewStep {
  final String title;
  final String time;
  final String waterAmount;

  BrewStep({required this.title, required this.time, required this.waterAmount});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time': time,
      'waterAmount': waterAmount,
    };
  }

  factory BrewStep.fromMap(Map<String, dynamic> map) {
    return BrewStep(
      title: map['title'] ?? '',
      time: map['time'] ?? '',
      waterAmount: map['waterAmount'] ?? '',
    );
  }
}

class BrewRecipe {
  final String id;
  final String coffeeName;
  final String roastery; // Added based on "Coffee Name & Roastery" label
  final String origin;
  final String variety;
  final String process;
  final DateTime? roastDate;


  final String roastLevel; // Light, Medium, Medium-Dark, Dark
  final String brewingMethod;
  final String ratio; // e.g. "1:15"
  final String grinder;
  final String grindSize;
  final double waterTemp;
  final int brewTimeSeconds;
  final bool isIced; // Hot or Iced
  final String notes;
  final double rating; // 1 to 5 (representing the faces)
  final DateTime timestamp;
  final List<BrewStep> steps; // New field

  BrewRecipe({
    required this.id,
    required this.coffeeName,
    required this.roastery,
    required this.origin,
    required this.variety,
    required this.process,
    this.roastDate,
    required this.roastLevel,
    required this.brewingMethod,
    required this.ratio,
    required this.grinder,
    required this.grindSize,
    required this.waterTemp,
    required this.brewTimeSeconds,
    required this.isIced,
    required this.notes,
    required this.rating,
    required this.timestamp,
    this.steps = const [], // Default empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'coffeeName': coffeeName,
      'roastery': roastery,
      'origin': origin,
      'variety': variety,
      'process': process,
      'roastDate': roastDate,
      'roastLevel': roastLevel,
      'brewingMethod': brewingMethod,
      'ratio': ratio,
      'grinder': grinder,
      'grindSize': grindSize,
      'waterTemp': waterTemp,
      'brewTimeSeconds': brewTimeSeconds,
      'isIced': isIced,
      'notes': notes,
      'rating': rating,
      'timestamp': timestamp,
      'steps': steps.map((s) => s.toMap()).toList(),
    };
  }

  factory BrewRecipe.fromMap(String id, Map<String, dynamic> map) {
    return BrewRecipe(
      id: id,
      coffeeName: map['coffeeName'] ?? '',
      roastery: map['roastery'] ?? '',
      origin: map['origin'] ?? '',
      variety: map['variety'] ?? '',
      process: map['process'] ?? '',
      roastDate: map['roastDate'] as DateTime?,
      roastLevel: map['roastLevel'] ?? 'Medium',
      brewingMethod: map['brewingMethod'] ?? '',
      ratio: map['ratio'] ?? '',
      grinder: map['grinder'] ?? '',
      grindSize: map['grindSize'] ?? '',
      waterTemp: (map['waterTemp'] ?? 0).toDouble(),
      brewTimeSeconds: map['brewTimeSeconds'] ?? 0,
      isIced: map['isIced'] ?? false,
      notes: map['notes'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      timestamp: map['timestamp'] as DateTime? ?? DateTime.now(),
      steps: (map['steps'] as List<dynamic>?)
          ?.map((s) => BrewStep.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  factory BrewRecipe.empty() {
    return BrewRecipe(
      id: '',
      coffeeName: '',
      roastery: '',
      origin: '',
      variety: '',
      process: '',
      roastLevel: 'Medium',
      brewingMethod: '',
      ratio: '',
      grinder: '',
      grindSize: '',
      waterTemp: 93,
      brewTimeSeconds: 0,
      isIced: false,
      notes: '',
      rating: 3,
      timestamp: DateTime.now(),
      steps: [],
    );
  }
}
