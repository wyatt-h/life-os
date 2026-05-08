import SwiftUI

// MARK: - Data Models

struct MealItem: Identifiable {
    let id = UUID()
    let name: String
    let timing: String
    let imageName: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let ingredients: [String]
    let steps: [String]
    let prepNote: String?
    let isShake: Bool
}

// MARK: - Meal Data

struct MealData {
    static let shakes: [MealItem] = [
        MealItem(
            name: "Morning Pre-Workout Shake",
            timing: "6:00–6:30 AM · Pre-Workout",
            imageName: "morning_shake",
            calories: 350,
            protein: 45,
            carbs: 35,
            fat: 5,
            ingredients: [
                "2 scoops Nutrilite Plant Protein",
                "1 ripe banana",
                "1 cup TJ's Oat Beverage Unsweetened",
                "5g creatine"
            ],
            steps: [
                "Pour 1 cup oat milk into blender.",
                "Add 1 banana (peel removed).",
                "Add 2 scoops Nutrilite Plant Protein powder.",
                "Add 5g creatine.",
                "Blend on high for 30 seconds until smooth.",
                "Drink 20–30 minutes before your workout."
            ],
            prepNote: "Raises blood amino acids and prevents catabolic fasting state. Drink before workout.",
            isShake: true
        ),
        MealItem(
            name: "Intra-Workout XS Muscle Multiplier",
            timing: "During Workout",
            imageName: "intra_workout_shake",
            calories: 50,
            protein: 4,
            carbs: 8,
            fat: 0,
            ingredients: [
                "1 serving XS Muscle Multiplier (Berry Blast or Watermelon)",
                "16 oz cold water"
            ],
            steps: [
                "Fill shaker bottle with 16 oz cold water.",
                "Add 1 serving XS Muscle Multiplier powder.",
                "Shake well for 10 seconds.",
                "Sip throughout your entire workout session."
            ],
            prepNote: "Maintains amino acid availability throughout your training session.",
            isShake: true
        ),
        MealItem(
            name: "Evening Protein Shake",
            timing: "Evening · Optional",
            imageName: "evening_shake",
            calories: 250,
            protein: 25,
            carbs: 20,
            fat: 8,
            ingredients: [
                "1 scoop Nutrilite Plant Protein",
                "1 tbsp TJ's Creamy Salted Peanut Butter",
                "1 cup TJ's Oat Beverage Unsweetened"
            ],
            steps: [
                "Pour 1 cup oat milk into blender or shaker.",
                "Add 1 scoop Nutrilite Plant Protein.",
                "Add 1 tbsp peanut butter.",
                "Blend or shake until smooth.",
                "Drink 1–2 hours before bed."
            ],
            prepNote: "Optional. Supports overnight muscle recovery. Drink 1–2 hours before bed.",
            isShake: true
        )
    ]

    static let weekAMeals: [MealItem] = [
        MealItem(
            name: "Quick Oats & Egg Scramble",
            timing: "Breakfast · 15 mins",
            imageName: "week_a_breakfast",
            calories: 650,
            protein: 45,
            carbs: 65,
            fat: 22,
            ingredients: [
                "3 whole eggs",
                "1 cup liquid egg whites",
                "1 tsp olive oil",
                "1.5 cups instant oatmeal",
                "1 tbsp almond butter",
                "1/2 cup blueberries"
            ],
            steps: [
                "Microwave oatmeal with water for 2 minutes.",
                "Heat 1 tsp olive oil in a pan over medium heat.",
                "Whisk together 3 eggs and 1 cup egg whites.",
                "Pour egg mixture into pan and scramble for 3 minutes.",
                "Top oatmeal with almond butter and blueberries.",
                "Serve eggs alongside oatmeal and enjoy."
            ],
            prepNote: "Eat within 30–60 minutes after your workout for maximum muscle repair.",
            isShake: false
        ),
        MealItem(
            name: "Air-Fried Teriyaki Chicken & Sweet Potato",
            timing: "Lunch · Prepped Sunday",
            imageName: "week_a_lunch",
            calories: 700,
            protein: 55,
            carbs: 95,
            fat: 10,
            ingredients: [
                "6 oz chicken breast (cubed)",
                "3 tbsp TJ's Soyaki sauce",
                "1.5 cups diced sweet potatoes",
                "1 cup broccoli florets",
                "1 tbsp extra virgin olive oil",
                "Salt, garlic powder, black pepper"
            ],
            steps: [
                "SUNDAY PREP — Wash and dice 3 lbs sweet potatoes into 1-inch cubes.",
                "Toss sweet potatoes with 1 tbsp EVOO, 1/2 tsp salt, 1/2 tsp garlic powder, and black pepper.",
                "Air fry sweet potatoes at 400°F for 20–25 minutes in batches, shaking every 10 min.",
                "Cut 2.5 lbs chicken breast into bite-sized cubes. Toss with salt, garlic powder, and 3 tbsp Soyaki sauce.",
                "Air fry chicken at 380°F for 10–12 minutes, shaking halfway. Internal temp must reach 165°F.",
                "Microwave 3 bags TJ's Frozen Broccoli Florets per package instructions.",
                "Divide into 5 containers: ~1.5 cups sweet potatoes, ~6 oz chicken, ~1 cup broccoli.",
                "AT OFFICE: Microwave for 2 minutes and enjoy."
            ],
            prepNote: "Prep all 5 lunches on Sunday. Stays fresh in the fridge for up to 5 days.",
            isShake: false
        ),
        MealItem(
            name: "15-Minute Salmon & Rice Bowl",
            timing: "Dinner · 15 mins",
            imageName: "week_a_dinner",
            calories: 850,
            protein: 45,
            carbs: 100,
            fat: 30,
            ingredients: [
                "6 oz salmon fillet (TJ's Wild Alaskan Sockeye)",
                "2 cups Jasmine rice (microwave pouch)",
                "1/2 ripe avocado",
                "1 tbsp soy sauce / 生抽"
            ],
            steps: [
                "Preheat air fryer to 400°F.",
                "Pat salmon fillet dry with paper towel. Season lightly with salt and pepper.",
                "Air-fry salmon at 400°F for 12 minutes (no need to flip).",
                "While salmon cooks, microwave Jasmine rice pouch for ~90 seconds.",
                "Slice 1/2 avocado.",
                "Assemble bowl: rice as base, salmon on top, avocado slices on the side.",
                "Drizzle 1 tbsp soy sauce over everything and serve."
            ],
            prepNote: nil,
            isShake: false
        )
    ]

    static let weekBMeals: [MealItem] = [
        MealItem(
            name: "Avocado Toast & Protein",
            timing: "Breakfast · 15 mins",
            imageName: "week_b_breakfast",
            calories: 700,
            protein: 35,
            carbs: 60,
            fat: 35,
            ingredients: [
                "3 slices TJ's Whole Wheat Sandwich Bread",
                "1/2 ripe avocado",
                "4 whole eggs",
                "Salt and black pepper",
                "1 tsp olive oil"
            ],
            steps: [
                "Toast 3 slices of whole wheat bread until golden.",
                "Halve the avocado and scoop out 1/2 into a bowl.",
                "Mash avocado with a fork until smooth. Season with salt and pepper.",
                "Spread mashed avocado generously on all 3 slices of toast.",
                "Heat 1 tsp olive oil in a pan over medium heat.",
                "Fry or scramble 4 eggs to your preference.",
                "Serve eggs alongside avocado toast."
            ],
            prepNote: "Eat within 30–60 minutes after your workout for maximum muscle repair.",
            isShake: false
        ),
        MealItem(
            name: "Ground Turkey & Pasta Skillet",
            timing: "Lunch · Prepped Sunday",
            imageName: "week_b_lunch",
            calories: 750,
            protein: 50,
            carbs: 90,
            fat: 18,
            ingredients: [
                "6 oz Jennie-O 93% lean ground turkey",
                "2 cups TJ's Organic Whole Wheat Penne",
                "1/2 cup TJ's Tomato Basil Marinara",
                "1 cup green beans (frozen)",
                "1 tsp garlic powder",
                "1/2 tsp onion powder",
                "Salt and black pepper"
            ],
            steps: [
                "SUNDAY PREP — Bring a large pot of salted water to a boil.",
                "Cook 1 lb TJ's Organic Whole Wheat Penne per package directions (10–12 mins). Drain.",
                "In a large pan over medium-high heat, cook 2.5 lbs ground turkey, breaking apart as it cooks.",
                "Season turkey with 1 tsp garlic powder, 1/2 tsp onion powder, 1/2 tsp salt, and black pepper.",
                "Cook turkey until no pink remains (~10 minutes).",
                "Add cooked pasta to turkey pan. Pour in 2.5 cups TJ's Tomato Basil Marinara.",
                "Stir to combine and heat through for 3–4 minutes.",
                "Steam green beans in microwave per package instructions.",
                "Divide into 5 containers with pasta/turkey and green beans on the side.",
                "AT OFFICE: Microwave for 2 minutes and enjoy."
            ],
            prepNote: "Prep all 5 lunches on Sunday. Stays fresh in the fridge for up to 5 days.",
            isShake: false
        ),
        MealItem(
            name: "Quick Beef & Rice Stir-Fry",
            timing: "Dinner · 15 mins",
            imageName: "week_b_dinner",
            calories: 800,
            protein: 45,
            carbs: 95,
            fat: 25,
            ingredients: [
                "6 oz Sprouts 90/10 ground beef",
                "2 cups Jasmine rice (microwave pouch)",
                "1 cup TJ's Stir Fry Vegetables (frozen)",
                "1 tbsp Kadoya sesame oil",
                "1 tbsp soy sauce / 生抽"
            ],
            steps: [
                "Heat a pan over medium-high heat (no oil needed for 90/10 beef).",
                "Add ground beef and brown for 7 minutes, breaking apart into crumbles.",
                "Add frozen stir fry vegetables directly to the pan (no need to thaw).",
                "Stir and cook for 5 minutes until vegetables are heated through.",
                "Microwave Jasmine rice pouch for ~90 seconds.",
                "Serve beef and veggie mix over rice in a bowl.",
                "Drizzle 1 tbsp sesame oil and 1 tbsp soy sauce over the top."
            ],
            prepNote: nil,
            isShake: false
        )
    ]
}

// MARK: - Macro Badge

struct MacroBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Meal Card

struct MealCard: View {
    let meal: MealItem
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Hero Image
            ZStack(alignment: .bottomLeading) {
                if UIImage(named: meal.imageName) != nil {
                    Image(meal.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: meal.isShake ? [.blue.opacity(0.4), .purple.opacity(0.4)] : [.orange.opacity(0.3), .green.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 180)
                        .overlay {
                            Image(systemName: meal.isShake ? "drop.fill" : "fork.knife")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.5))
                        }
                }

                // Gradient overlay + labels
                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    if meal.isShake {
                        Label("Shake", systemImage: "drop.fill")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.blue.opacity(0.85), in: Capsule())
                    }
                    Text(meal.name)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    Text(meal.timing)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(14)
            }
            .frame(height: 180)
            .clipped()

            // Macros Row
            HStack(spacing: 6) {
                MacroBadge(label: "kcal", value: "\(meal.calories)", color: .orange)
                MacroBadge(label: "protein", value: "\(meal.protein)g", color: .blue)
                MacroBadge(label: "carbs", value: "\(meal.carbs)g", color: .green)
                MacroBadge(label: "fat", value: "\(meal.fat)g", color: .yellow)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Expand / Collapse Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(isExpanded ? "Hide Details" : "View Ingredients & Steps")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline.bold())
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {

                    // Prep Note
                    if let note = meal.prepNote {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                                .padding(.top, 2)
                            Text(note)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }

                    // Ingredients
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Ingredients", systemImage: "cart.fill")
                            .font(.subheadline.bold())
                        ForEach(meal.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(.blue.opacity(0.8))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                Text(ingredient)
                                    .font(.subheadline)
                            }
                        }
                    }

                    Divider()

                    // Steps
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Instructions", systemImage: "list.number")
                            .font(.subheadline.bold())
                        ForEach(Array(meal.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 22, height: 22)
                                    .background(
                                        step.hasPrefix("SUNDAY") || step.hasPrefix("AT OFFICE")
                                        ? Color.orange : Color.blue,
                                        in: Circle()
                                    )
                                Text(step)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Section Header

struct MealSectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.headline)
            Text(title)
                .font(.headline.bold())
        }
        .padding(.top, 6)
    }
}

// MARK: - Daily Macro Summary

struct DailyMacroSummary: View {
    let week: String

    var calories: Int { week == "A" ? 3500 : 3550 }
    var protein: Int { week == "A" ? 219 : 204 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Macro Target")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                macroColumn(value: "\(calories)", label: "kcal", color: .orange)
                Divider().frame(height: 36)
                macroColumn(value: "\(protein)g", label: "protein", color: .blue)
                Divider().frame(height: 36)
                macroColumn(value: "375g", label: "carbs", color: .green)
                Divider().frame(height: 36)
                macroColumn(value: "90g", label: "fats", color: .yellow)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    func macroColumn(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Main View

struct MealPlanView: View {
    @State private var selectedWeek: String = "B" // This week is Week B
    @State private var showingWeekInfo = false

    var currentMeals: [MealItem] {
        selectedWeek == "A" ? MealData.weekAMeals : MealData.weekBMeals
    }

    var weekLabel: String {
        selectedWeek == "A" ? "Week A · Chicken & Salmon" : "Week B · Turkey & Beef"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Week Picker
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Select Week")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button {
                                showingWeekInfo.toggle()
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Picker("Week", selection: $selectedWeek) {
                            Text("Week A · Chicken & Salmon").tag("A")
                            Text("Week B · Turkey & Beef").tag("B")
                        }
                        .pickerStyle(.segmented)

                        HStack(spacing: 6) {
                            if selectedWeek == "B" {
                                Label("This week", systemImage: "calendar.badge.checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            } else {
                                Label("Next week (Salmon & Chicken week)", systemImage: "calendar.badge.clock")
                                    .font(.caption.bold())
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    // Macro Summary
                    DailyMacroSummary(week: selectedWeek)

                    // Shakes Section
                    MealSectionHeader(title: "Daily Shakes", icon: "drop.fill", color: .blue)

                    ForEach(MealData.shakes) { shake in
                        MealCard(meal: shake)
                    }

                    // Meals Section
                    MealSectionHeader(title: weekLabel, icon: "fork.knife", color: .orange)

                    ForEach(currentMeals) { meal in
                        MealCard(meal: meal)
                    }

                    // Budget Note
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "cart.badge.questionmark")
                            .foregroundColor(.green)
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly Grocery Budget")
                                .font(.subheadline.bold())
                            Text(selectedWeek == "A"
                                 ? "~$85–$100/week · Trader Joe's, Sprouts & Ralph's"
                                 : "~$80–$95/week · Trader Joe's, Sprouts & Ralph's")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Meal Plan")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingWeekInfo) {
                WeekInfoSheet()
            }
        }
    }
}

// MARK: - Week Info Sheet

struct WeekInfoSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("2-Week Rotating Plan")
                        .font(.title2.bold())

                    Text("You follow Week A for 7 days, then Week B for 7 days, and repeat. This provides variety without requiring you to rethink your grocery list every week.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("System Constraints", systemImage: "gearshape.fill")
                            .font(.headline)
                        Group {
                            Text("• Budget: ~$100–$115/week ($400–$500/month)")
                            Text("• Time: 15 min breakfast, 15–30 min dinner, 2–2.5 hrs Sunday meal prep")
                            Text("• Dietary: Dairy-free, Invisalign-friendly, no spicy food")
                            Text("• Goal: 3,100–3,200 kcal | 165–195g Protein | 350–400g Carbs | 80–100g Fats")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Morning Nutrition Timing", systemImage: "clock.fill")
                            .font(.headline)
                        Group {
                            Text("6:00–6:30 AM → Drink morning protein shake (pre-workout)")
                            Text("6:30–7:00 AM → Work out (30 mins)")
                            Text("During workout → Sip XS Muscle Multiplier")
                            Text("7:00–8:00 AM → Eat breakfast (post-workout anabolic window)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("When to Adjust", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)
                        Text("Adjust monthly. On the first Sunday of every month, check your weekly average morning weight. If gaining 0.5–1.0 lbs/week, change nothing. If weight stalls for two weeks, add ~200 calories.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationTitle("About Your Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    MealPlanView()
}
