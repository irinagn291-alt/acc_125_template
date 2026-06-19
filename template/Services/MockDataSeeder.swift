import Foundation
import SwiftData

enum MockDataSeeder {
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        #if targetEnvironment(simulator)
        let existing = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        guard existing.isEmpty else { return }
        seed(context)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        #endif
    }

    @MainActor
    private static func seed(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date()
        func day(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: now) ?? now }
        func at(_ hour: Int, _ date: Date) -> Date { cal.date(byAdding: .hour, value: hour, to: cal.startOfDay(for: date)) ?? date }

        // MARK: Profile
        let profile = UserProfile(
            name: "Alex Carter", age: 28, heightCm: 178, currentWeightKg: 76.5, targetWeightKg: 73,
            activityLevel: "high", trainingLevel: .intermediate,
            mainGoals: ["Build muscle", "Stay consistent", "Read more"],
            dailyCaloriesGoal: 2400, proteinGoalGrams: 160, fatGoalGrams: 80, carbsGoalGrams: 260, waterGoalMl: 3000
        )
        context.insert(profile)

        // MARK: Workouts
        let upper = Workout(title: "Upper Body Strength", workoutDescription: "Push & pull focus", type: .strength, difficulty: .intermediate, goal: "Hypertrophy", estimatedDurationMinutes: 60, tags: ["push", "pull"], exercises: [
            WorkoutExercise(name: "Bench Press", muscleGroup: .chest, equipment: "Barbell", sets: 4, reps: 8, weightKg: 60, restSeconds: 120, rpe: 8, orderIndex: 0),
            WorkoutExercise(name: "Pull Up", muscleGroup: .back, equipment: "Bodyweight", sets: 4, reps: 8, restSeconds: 120, rpe: 8, orderIndex: 1),
            WorkoutExercise(name: "Overhead Press", muscleGroup: .shoulders, equipment: "Barbell", sets: 3, reps: 10, weightKg: 40, restSeconds: 90, rpe: 7, orderIndex: 2),
            WorkoutExercise(name: "Barbell Row", muscleGroup: .back, equipment: "Barbell", sets: 3, reps: 10, weightKg: 50, restSeconds: 90, rpe: 7, orderIndex: 3)
        ])
        let legs = Workout(title: "Leg Day", workoutDescription: "Quad & posterior chain", type: .strength, difficulty: .advanced, goal: "Strength", estimatedDurationMinutes: 70, tags: ["legs"], exercises: [
            WorkoutExercise(name: "Back Squat", muscleGroup: .legs, equipment: "Barbell", sets: 5, reps: 5, weightKg: 90, restSeconds: 150, rpe: 8, orderIndex: 0),
            WorkoutExercise(name: "Romanian Deadlift", muscleGroup: .legs, equipment: "Barbell", sets: 4, reps: 8, weightKg: 70, restSeconds: 120, rpe: 8, orderIndex: 1),
            WorkoutExercise(name: "Leg Press", muscleGroup: .legs, equipment: "Machine", sets: 3, reps: 12, weightKg: 120, restSeconds: 90, rpe: 7, orderIndex: 2),
            WorkoutExercise(name: "Calf Raise", muscleGroup: .legs, equipment: "Machine", sets: 4, reps: 15, weightKg: 40, restSeconds: 60, orderIndex: 3)
        ])
        let hiit = Workout(title: "Full Body HIIT", workoutDescription: "Conditioning circuit", type: .functional, difficulty: .intermediate, goal: "Fat loss", estimatedDurationMinutes: 30, tags: ["cardio", "hiit"], exercises: [
            WorkoutExercise(name: "Burpees", muscleGroup: .fullBody, sets: 4, reps: 15, restSeconds: 45, orderIndex: 0),
            WorkoutExercise(name: "Kettlebell Swing", muscleGroup: .glutes, equipment: "Kettlebell", sets: 4, reps: 20, weightKg: 24, restSeconds: 45, orderIndex: 1),
            WorkoutExercise(name: "Mountain Climbers", muscleGroup: .core, sets: 4, durationSeconds: 40, restSeconds: 30, orderIndex: 2)
        ])
        let mobility = Workout(title: "Mobility Flow", workoutDescription: "Recovery & stretching", type: .mobility, difficulty: .beginner, goal: "Recovery", estimatedDurationMinutes: 25, tags: ["mobility"], exercises: [
            WorkoutExercise(name: "Hip Opener", muscleGroup: .mobility, sets: 2, durationSeconds: 60, restSeconds: 20, orderIndex: 0),
            WorkoutExercise(name: "Thoracic Rotation", muscleGroup: .mobility, sets: 2, reps: 10, restSeconds: 20, orderIndex: 1)
        ])
        [upper, legs, hiit, mobility].forEach { context.insert($0) }
        upper.lastPerformedAt = day(2)
        legs.lastPerformedAt = day(3)
        hiit.lastPerformedAt = day(7)

        // MARK: Workout sessions
        func session(_ workout: Workout, daysAgo n: Int, durationMin: Int, volume: Double, rpe: Int, status: SessionStatus = .completed) -> WorkoutSession {
            let s = WorkoutSession(workoutId: workout.id, workoutTitle: workout.title, startedAt: at(9, day(n)))
            s.status = status
            s.durationSeconds = durationMin * 60
            s.endedAt = cal.date(byAdding: .minute, value: durationMin, to: s.startedAt)
            s.perceivedDifficulty = rpe
            s.mood = ["Strong", "Focused", "Tired but done", "Energized"].randomElement()
            s.totalVolume = volume
            var sets: [PerformedSet] = []
            for ex in workout.sortedExercises {
                for setIdx in 0..<ex.sets {
                    sets.append(PerformedSet(exerciseName: ex.name, muscleGroup: ex.muscleGroup, setIndex: setIdx, reps: ex.reps, weightKg: ex.weightKg, durationSeconds: ex.durationSeconds, rpe: ex.rpe, isCompleted: true, completedAt: s.startedAt))
                }
            }
            s.performedSets = sets
            s.completedExercisesCount = workout.exercises.count
            s.completedSetsCount = sets.count
            return s
        }

        let sessions = [
            session(upper, daysAgo: 19, durationMin: 58, volume: 5400, rpe: 8),
            session(legs, daysAgo: 17, durationMin: 65, volume: 8200, rpe: 9),
            session(hiit, daysAgo: 15, durationMin: 28, volume: 2100, rpe: 7),
            session(upper, daysAgo: 12, durationMin: 60, volume: 5600, rpe: 8),
            session(legs, daysAgo: 10, durationMin: 68, volume: 8600, rpe: 9),
            session(hiit, daysAgo: 7, durationMin: 30, volume: 2300, rpe: 7),
            session(upper, daysAgo: 5, durationMin: 61, volume: 5800, rpe: 8),
            session(legs, daysAgo: 3, durationMin: 70, volume: 8900, rpe: 9),
            session(upper, daysAgo: 0, durationMin: 55, volume: 5500, rpe: 7)
        ]
        sessions.forEach { context.insert($0) }

        let plannedToday = WorkoutSession(workoutId: legs.id, workoutTitle: "Leg Day", startedAt: at(18, now))
        plannedToday.status = .planned
        context.insert(plannedToday)

        // MARK: Program
        let program = TrainingProgram(
            title: "12-Week Strength Builder",
            programDescription: "Progressive overload across an upper/lower split.",
            goal: "Build strength & muscle", difficulty: .intermediate,
            startDate: day(14), endDate: cal.date(byAdding: .day, value: 70, to: now),
            weeksCount: 4, daysPerWeek: 3, status: .active,
            weeks: (1...4).map { w in
                ProgramWeek(weekIndex: w, title: "Week \(w)", notes: w == 1 ? "Base volume" : nil, days: [
                    ProgramDay(dayIndex: 1, weekday: 2, title: "Upper Body", plannedWorkoutId: upper.id, isCompleted: w == 1),
                    ProgramDay(dayIndex: 2, weekday: 4, title: "Leg Day", plannedWorkoutId: legs.id, isCompleted: w == 1),
                    ProgramDay(dayIndex: 3, weekday: 6, title: "Conditioning", plannedWorkoutId: hiit.id, isCompleted: false)
                ])
            }
        )
        context.insert(program)

        // MARK: Food products
        func product(_ name: String, _ brand: String?, _ kcal: Double, _ p: Double, _ f: Double, _ c: Double, fav: Bool = false) -> FoodProduct {
            FoodProduct(source: .manual, name: name, brand: brand, caloriesPer100g: kcal, proteinPer100g: p, fatPer100g: f, carbsPer100g: c, nutriScore: nil, isFavorite: fav)
        }
        let chicken = product("Chicken Breast", "Generic", 165, 31, 3.6, 0, fav: true)
        let oats = product("Rolled Oats", "Quaker", 379, 13, 6.5, 67, fav: true)
        let banana = product("Banana", nil, 89, 1.1, 0.3, 23)
        let yogurt = product("Greek Yogurt", "Fage", 97, 9, 5, 4, fav: true)
        let almonds = product("Almonds", nil, 579, 21, 50, 22)
        let rice = product("Brown Rice", nil, 112, 2.6, 0.9, 24)
        let salmon = product("Salmon Fillet", nil, 208, 20, 13, 0, fav: true)
        [chicken, oats, banana, yogurt, almonds, rice, salmon].forEach { context.insert($0) }

        // MARK: Meals
        func item(_ p: FoodProduct, _ grams: Double) -> MealItem {
            let r = grams / 100
            return MealItem(foodProductId: p.id, productName: p.name, amountGrams: grams, calories: p.caloriesPer100g * r, protein: p.proteinPer100g * r, fat: p.fatPer100g * r, carbs: p.carbsPer100g * r)
        }
        func meal(_ date: Date, _ type: MealType, _ title: String, _ items: [MealItem]) -> Meal {
            Meal(date: date, type: type, title: title, items: items)
        }
        [
            meal(now, .breakfast, "Oats & Banana", [item(oats, 80), item(banana, 120), item(yogurt, 150)]),
            meal(now, .lunch, "Chicken & Rice", [item(chicken, 180), item(rice, 200)]),
            meal(now, .snack, "Almonds", [item(almonds, 30)]),
            meal(now, .dinner, "Salmon & Veg", [item(salmon, 160), item(rice, 150)])
        ].forEach { context.insert($0) }

        for n in 1...10 {
            let d = day(n)
            [
                meal(d, .breakfast, "Breakfast", [item(oats, 70), item(yogurt, 150), item(banana, 100)]),
                meal(d, .lunch, "Lunch", [item(chicken, 150), item(rice, 180)]),
                meal(d, .dinner, "Dinner", [item(salmon, 150), item(almonds, 20)])
            ].forEach { context.insert($0) }
        }

        // MARK: Hydration
        for ml in [250, 500, 250, 500, 350] { context.insert(HydrationLog(date: now, amountMl: ml)) }
        for n in 1...7 { context.insert(HydrationLog(date: day(n), amountMl: 2000 + (n % 3) * 300)) }

        // MARK: Books & reading
        let b1 = Book(title: "Atomic Habits", authors: ["James Clear"], firstPublishYear: 2018, subjects: ["Self-help", "Habits"], readingStatus: .reading, rating: 5, progressPercent: 0.62, notes: "Great practical frameworks.")
        let b2 = Book(title: "Bigger Leaner Stronger", authors: ["Michael Matthews"], firstPublishYear: 2012, subjects: ["Fitness", "Strength"], readingStatus: .reading, rating: 4, progressPercent: 0.3)
        let b3 = Book(title: "Why We Sleep", authors: ["Matthew Walker"], firstPublishYear: 2017, subjects: ["Health", "Sleep"], readingStatus: .completed, rating: 5, progressPercent: 1.0)
        let b4 = Book(title: "The Sports Gene", authors: ["David Epstein"], firstPublishYear: 2013, subjects: ["Sports science"], readingStatus: .completed, rating: 4, progressPercent: 1.0)
        let b5 = Book(title: "Endure", authors: ["Alex Hutchinson"], firstPublishYear: 2018, subjects: ["Endurance"], readingStatus: .wantToRead)
        let b6 = Book(title: "Spark", authors: ["John J. Ratey"], firstPublishYear: 2008, subjects: ["Exercise", "Brain"], readingStatus: .paused, progressPercent: 0.15)
        [b1, b2, b3, b4, b5, b6].forEach { context.insert($0) }
        for n in 0...5 {
            context.insert(ReadingSession(bookId: b1.id, bookTitle: b1.title, date: day(n), durationMinutes: 20 + n * 3, pagesRead: 15 + n))
        }

        // MARK: Calendar events
        func event(_ title: String, _ type: CalendarEventType, _ date: Date, _ status: CalendarEventStatus = .planned, _ notes: String? = nil) -> CalendarEvent {
            CalendarEvent(title: title, eventType: type, startDate: date, status: status, notes: notes)
        }
        [
            event("Upper Body Strength", .workout, at(9, now), .planned),
            event("Meal Prep", .mealPlan, at(12, now), .planned),
            event("Read 30 min", .reading, at(21, now), .completed),
            event("Rest & Recovery", .rest, day(-1), .planned),
            event("Leg Day", .workout, day(-2), .planned),
            event("Body Measurement", .measurement, day(-4), .planned, "Weekly check-in"),
            event("Deload reminder", .note, day(-6), .planned),
            event("Local 10K Race", .competition, day(-12), .planned, "Goal: sub-50 min"),
            event("Upper Body Strength", .workout, day(3), .completed),
            event("Leg Day", .workout, day(5), .completed)
        ].forEach { context.insert($0) }

        // MARK: Body measurements
        let weights: [Double] = [79.8, 79.1, 78.5, 78.0, 77.6, 77.1, 76.8, 76.5]
        let bodyFat: [Double] = [19.5, 19.1, 18.7, 18.2, 17.9, 17.5, 17.2, 16.9]
        let muscle: [Double] = [34.0, 34.2, 34.4, 34.7, 34.9, 35.1, 35.3, 35.5]
        for i in 0..<8 {
            let d = cal.date(byAdding: .day, value: -(7 * (7 - i)), to: now) ?? now
            context.insert(BodyMeasurement(
                date: d, weightKg: weights[i], bodyFatPercent: bodyFat[i], muscleMassKg: muscle[i],
                waistCm: 86 - Double(i) * 0.6, chestCm: 104 + Double(i) * 0.2, hipsCm: 98 - Double(i) * 0.2,
                armCm: 36 + Double(i) * 0.1, thighCm: 58 + Double(i) * 0.1, neckCm: 39,
                note: i == 7 ? "Feeling strong and lean." : nil
            ))
        }

        // MARK: Goals
        [
            UserGoal(title: "Reach 73 kg", type: .bodyWeight, targetValue: 73, currentValue: 76.5, unit: "kg", deadline: cal.date(byAdding: .day, value: 60, to: now)),
            UserGoal(title: "4 workouts / week", type: .workoutsCount, targetValue: 4, currentValue: 3, unit: "sessions", deadline: cal.date(byAdding: .day, value: 3, to: now)),
            UserGoal(title: "Drink 3L water daily", type: .water, targetValue: 3000, currentValue: 1850, unit: "ml"),
            UserGoal(title: "160g protein daily", type: .protein, targetValue: 160, currentValue: 120, unit: "g"),
            UserGoal(title: "Read 12 books this year", type: .reading, targetValue: 12, currentValue: 5, unit: "books", deadline: cal.date(byAdding: .day, value: 200, to: now)),
            UserGoal(title: "Finish Why We Sleep", type: .reading, targetValue: 1, currentValue: 1, unit: "books", isCompleted: true),
            UserGoal(title: "Squat 100 kg", type: .custom, targetValue: 100, currentValue: 100, unit: "kg", isCompleted: true)
        ].forEach { context.insert($0) }

        try? context.save()
    }
}
