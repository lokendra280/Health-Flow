class HealthCalc {
  static double bmi(double kg, double cm) => kg / ((cm / 100) * (cm / 100));

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  static int dailyStepGoal(double bmi) {
    if (bmi < 18.5) return 8000;
    if (bmi < 25.0) return 10000;
    if (bmi < 30.0) return 12000;
    return 15000;
  }

  static double stepsToKm(int steps) => steps * 0.00075;
  static double stepsToCalories(int steps, double kg) => steps * 0.04 * (kg / 70);
  static int kmToSteps(double km) => (km / 0.00075).round();

  static double dailyWalkingKm(double bmi) => stepsToKm(dailyStepGoal(bmi));

  static int bmrCalories(double kg, double cm, int age, bool isMale) {
    final bmr = isMale
        ? 88.36 + (13.4 * kg) + (4.8 * cm) - (5.7 * age)
        : 447.6 + (9.2 * kg) + (3.1 * cm) - (4.3 * age);
    return bmr.round();
  }

  static String sleepQuality(double hours) {
    if (hours >= 7 && hours <= 9) return 'Great';
    if (hours >= 6) return 'Fair';
    return 'Poor';
  }
}
