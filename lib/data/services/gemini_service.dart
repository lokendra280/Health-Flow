import 'dart:convert';
import 'package:habitflow/data/services/plan_calculator.dart';
import 'package:http/http.dart' as http;
import '../models/journey_goal.dart';
import '../models/personal_profile.dart';
import '../models/ai_plan.dart';
import '../models/tracking_models.dart';

/// Wraps the Gemini API's `generateContent` endpoint and asks it to return
/// strict JSON matching [AiPlan]'s shape. Swap [apiKey] for a value pulled
/// from --dart-define or a secrets manager before shipping — never commit it.
class GeminiService {
  final String apiKey;
  final String model;

  GeminiService({required this.apiKey, this.model = 'gemini-1.5-flash'});

  Uri get _endpoint => Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

  Future<AiPlan> generatePlan({
    required JourneyGoal goal,
    required PersonalProfile profile,
  }) async {
    final weightKg =
        PlanCalculator.kgFrom(goal.currentWeight ?? 0, goal.weightUnit);
    final heightCm =
        PlanCalculator.cmFrom(profile.height ?? 0, profile.heightUnit);
    final bmrValue = PlanCalculator.bmr(
        weightKg: weightKg,
        heightCm: heightCm,
        age: profile.age ?? 0,
        gender: profile.gender ?? '');
    final tdeeValue = PlanCalculator.tdee(
        bmr: bmrValue, activityLevel: profile.activityLevel ?? '');
    final calorieTargetValue =
        PlanCalculator.calorieTarget(tdee: tdeeValue, goalType: goal.type);
    final waterTargetValue = PlanCalculator.waterTargetMl(
        weightKg: weightKg, activityLevel: profile.activityLevel ?? '');
    final stepTargetValue = PlanCalculator.stepTarget(
        activityLevel: profile.activityLevel ?? '', goalType: goal.type);

    final direction = _goalDirection(goal.type);

    final prompt = _buildPrompt(
      goal,
      profile,
      direction: direction,
      calorieTarget: calorieTargetValue,
      waterTarget: waterTargetValue,
      stepTarget: stepTargetValue,
    );

    final response = await http.post(
      _endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.4,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw GeminiServiceException(
          'Gemini request failed (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (text == null) {
      throw GeminiServiceException(
          'Gemini response had no text content: ${response.body}');
    }

    final Map<String, dynamic> planJson;
    try {
      planJson = jsonDecode(text) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw GeminiServiceException(
          'Gemini returned non-JSON output: $e\n$text');
    }

    planJson['calorieTarget'] = calorieTargetValue;
    planJson['waterTarget'] = waterTargetValue;
    planJson['stepTarget'] = stepTargetValue;

    return AiPlan.fromJson(planJson);
  }

  String _goalDirection(String goalType) {
    final t = goalType.toLowerCase();
    if (t.contains('lose') || t.contains('loss')) return 'lose_weight';
    if (t.contains('gain') || t.contains('bulk') || t.contains('muscle')) {
      return 'gain_weight';
    }
    return 'maintain';
  }

  String _buildPrompt(
    JourneyGoal goal,
    PersonalProfile profile, {
    required String direction,
    required int calorieTarget,
    required int waterTarget,
    required int stepTarget,
  }) {
    final directionGuidance = switch (direction) {
      'lose_weight' =>
        'This user wants to LOSE weight. Favor cardio and full-body '
            'movements that burn calories (brisk walking, cycling, jogging, '
            'jump rope, circuit-style bodyweight sets) with 1-2 light '
            'strength sessions to preserve muscle. Keep rest periods short.',
      'gain_weight' =>
        'This user wants to GAIN weight/muscle. Favor progressive strength '
            'training (squats, deadlift pattern, push/pull/bench, rows) with '
            'longer rest periods and heavier compound moves. Keep cardio '
            'minimal — just enough for general health, not calorie burn.',
      _ => 'This user wants to MAINTAIN their current weight. Give a balanced '
          'mix of strength and cardio for general fitness.',
    };

    return '''
You are a fitness and nutrition planning assistant. This is general wellness
guidance, not medical advice. Keep everything simple and directly actionable.

calorieTarget: $calorieTarget kcal/day
waterTarget: $waterTarget ml/day
stepTarget: $stepTarget steps/day

$directionGuidance

User goal: ${goal.type}
User profile: ${profile.age}, ${profile.gender}, ${profile.height} ${profile.heightUnit}, ${profile.activityLevel}

Build a full 7-day exercise schedule (Monday through Sunday) matching the
guidance above and the user's fitness level. Include 2-4 rest days spread
across the week.

On non-rest days, provide a "focus" label and list 3-5 specific exercises
with concrete sets/reps or duration. Ensure the exercises are safe and
appropriate for the user's profile.

For recommendedHabits, include exactly these four, in this order:
1. "Log your meals — aim for $calorieTarget kcal/day"
2. "Walk $stepTarget steps/day"
3. "Drink $waterTarget ml of water/day"
4. One short habit about consistency or sleep.

Respond with ONLY a JSON object matching exactly this shape (no markdown
fences, no commentary). weeklySchedule MUST have exactly 7 entries, one
per day, in order Monday through Sunday. Ensure every entry has an 
"exercises" array, even if it is empty for rest days:
{
  "calorieTarget": $calorieTarget,
  "waterTarget": $waterTarget,
  "stepTarget": $stepTarget,
  "goalDirection": "$direction",
  "weeklySchedule": [
    {
      "day": "Monday",
      "isRestDay": false,
      "focus": "Upper body strength",
      "exercises": [
        {"name": "Push-ups", "sets": "3 sets x 12 reps", "category": "strength"},
        {"name": "Brisk walk", "sets": "20 min", "category": "cardio"}
      ]
    },
    {
      "day": "Tuesday", 
      "isRestDay": true, 
      "focus": null, 
      "exercises": []
    }
  ],
  "sleepTarget": "7-9_hours",
  "mealTracking": true,
  "recommendedHabits": [
    "Log your meals — aim for $calorieTarget kcal/day",
    "Walk $stepTarget steps/day",
    "Drink $waterTarget ml of water/day",
    "Get 8 hours of sleep"
  ],
  "milestones": ["First week complete", "Down 1kg", "Improved energy"]
}
''';
  }

  /// Generates a motivational nudge when a user goes over a healthy limit.
  Future<String> generateNudgeMessage(String type, double value) async {
    final prompt = '''
Generate a single, warm, and highly motivational sentence for a user who has $type value of $value.
- If type is "calories" and > 3000: Encourage them to use that extra energy for a great workout tomorrow, rather than making them feel bad.
- If type is "water" and > 4000: Congratulate them on being a hydration pro but remind them they are well-covered for today.
- If type is "workout" and > 2: Celebrate their amazing dedication and suggest a well-earned rest or light stretch.
Keep it under 20 words. No "depressing" or "guilt-tripping" language. Be a happy coach.
''';
    return _plainTextRequest(prompt);
  }

  Future<String> reviewDay({
    double? weight,
    required List<FoodEntry> food,
    required int water,
    required int steps,
    required List<WorkoutEntry> workouts,
    SleepEntry? sleep,
    required List<Habit> habits,
    DailyCheckIn? checkIn,
  }) async {
    final prompt = '''
Summarize this day of health tracking data in 3-4 encouraging sentences.
weight: $weight, water: ${water}ml, steps: $steps,
food: ${food.map((f) => '${f.name} (${f.calories}kcal)').join(', ')},
workouts: ${workouts.map((w) => '${w.type} ${w.minutes}min').join(', ')},
sleep: ${sleep?.hours}h, habits: ${habits.where((h) => h.completedToday).length}/${habits.length}
If they exceeded 3000 kcal or 4000ml water, acknowledge it with a positive twist (e.g. "You're full of energy!" or "Hydration champion!").
''';
    return _plainTextRequest(prompt);
  }

  Future<String> summarizeWeek(Map<String, dynamic> metrics) {
    final prompt = '''
Summarize this week of tracking data in 3-4 sentences. Note one strength and one area to improve.
Metrics: $metrics
If any day had >3000 kcal, suggest eating nutrient-dense whole foods tomorrow to feel light and energized.
Keep the tone happy and supportive.
''';
    return _plainTextRequest(prompt);
  }

  Future<String> summarizeMonth(Map<String, dynamic> metrics) => _plainTextRequest(
      'Summarize this month of weight-loss tracking data in 4-5 sentences with strengths, weaknesses and recommendations: $metrics');

  /// Phase 6: AI coach chat turn.
  Future<String> chat({
    required List<ChatMessage> history,
    required String contextSummary,
  }) async {
    final convo = history.map((m) => '${m.role}: ${m.content}').join('\n');
    final prompt =
        'You are a supportive weight-loss coach. Context: $contextSummary\n\nConversation so far:\n$convo\n\nRespond as the assistant, briefly and warmly. Not medical advice.';
    return _plainTextRequest(prompt);
  }

  /// Phase 4b: AI food scanner — sends a photo, gets back candidate food
  /// entries. Always route results through a confirmation UI before saving.
  Future<List<FoodEntry>> detectFood(List<int> imageBytes,
      {String mimeType = 'image/jpeg'}) async {
    final prompt = '''
Identify the food(s) in this photo and estimate nutrition. Respond with ONLY
a JSON array (no markdown fences, no commentary), one object per distinct
food item visible:
[{"mealType":"snack","name":"<food name>","calories":<number>,"protein":<number>,"carbs":<number>,"fat":<number>}]
Use your best visual estimate for portion size. If nothing edible is visible, return [].
''';
    final response = await http.post(
      _endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Encode(imageBytes)
                }
              },
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.2
        },
      }),
    );

    if (response.statusCode != 200) {
      throw GeminiServiceException(
          'Gemini request failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (text == null) {
      throw GeminiServiceException(
          'Gemini response had no text content: ${response.body}');
    }

    final List<dynamic> list;
    try {
      list = jsonDecode(text) as List<dynamic>;
    } on FormatException catch (e) {
      throw GeminiServiceException(
          'Gemini returned non-JSON output: $e\n$text');
    }
    return list
        .map((e) => FoodEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<String> _plainTextRequest(String prompt) async {
    try {
      final response = await http.post(
        _endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {'temperature': 0.7},
        }),
      );
      if (response.statusCode != 200) {
        return "You're doing great! Keep up the consistency.";
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      return text?.trim() ?? "Keep going, you're on the right track!";
    } catch (_) {
      return "Awesome progress today! Let's keep this momentum going.";
    }
  }
}

class GeminiServiceException implements Exception {
  final String message;
  GeminiServiceException(this.message);
  @override
  String toString() => 'GeminiServiceException: $message';
}
