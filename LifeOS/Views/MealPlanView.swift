import SwiftUI

// MARK: - Models
struct Recipe: Identifiable {
    let id: String
    let name: String
    let type: String       // "Meal" or "Shake"
    let week: String       // "Week A", "Week B", "Both"
    let mealSlot: String
    let ingredients: String
    let instructions: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let prepTime: Int
}

// MARK: - ViewModel
@MainActor
class MealPlanViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading: Bool = false
    @Published var selectedWeek: String = "Week A"
    @Published var selectedRecipe: Recipe? = nil
    
    var meals: [Recipe] { recipes.filter { $0.type == "Meal" && ($0.week == selectedWeek || $0.week == "Both") } }
    var shakes: [Recipe] { recipes.filter { $0.type == "Shake" } }
    
    var totalCalories: Int { (meals + shakes).reduce(0) { $0 + $1.calories } }
    var totalProtein: Int { (meals + shakes).reduce(0) { $0 + $1.protein } }
    
    let proteinTarget = 180
    
    func loadRecipes() async {
        isLoading = true
        do {
            let results = try await NotionService.shared.queryDatabase(
                databaseId: NotionService.DatabaseIDs.recipesAndShakes
            )
            
            recipes = results.compactMap { page -> Recipe? in
                guard let props = page["properties"] as? [String: Any],
                      let id = page["id"] as? String else { return nil }
                
                func text(_ key: String) -> String {
                    if let prop = props[key] as? [String: Any] {
                        if let richText = prop["rich_text"] as? [[String: Any]],
                           let first = richText.first,
                           let textObj = first["text"] as? [String: Any],
                           let content = textObj["content"] as? String {
                            return content
                        }
                        if let titleArr = prop["title"] as? [[String: Any]],
                           let first = titleArr.first,
                           let textObj = first["text"] as? [String: Any],
                           let content = textObj["content"] as? String {
                            return content
                        }
                        if let select = prop["select"] as? [String: Any],
                           let name = select["name"] as? String {
                            return name
                        }
                    }
                    return ""
                }
                
                func number(_ key: String) -> Int {
                    if let prop = props[key] as? [String: Any],
                       let num = prop["number"] as? Double {
                        return Int(num)
                    }
                    return 0
                }
                
                return Recipe(
                    id: id,
                    name: text("Name"),
                    type: text("Type"),
                    week: text("Week"),
                    mealSlot: text("Meal Slot"),
                    ingredients: text("Ingredients"),
                    instructions: text("Instructions"),
                    calories: number("Calories"),
                    protein: number("Protein (g)"),
                    carbs: number("Carbs (g)"),
                    fat: number("Fat (g)"),
                    prepTime: number("Prep Time (min)")
                )
            }
        } catch {
            // Use fallback data if Notion fails
            recipes = fallbackRecipes()
        }
        isLoading = false
    }
    
    private func fallbackRecipes() -> [Recipe] {
        return [
            Recipe(id: "1", name: "Morning Pre-Workout Shake", type: "Shake", week: "Both", mealSlot: "Pre-Workout Shake",
                   ingredients: "2 scoops Nutrilite Plant Protein, 1 banana, 1 cup TJ's Oat Beverage Unsweetened, 5g creatine",
                   instructions: "1. Add oat milk to blender.\n2. Peel and add banana.\n3. Add 2 scoops Nutrilite Plant Protein.\n4. Add 5g creatine.\n5. Blend until smooth (~30 seconds).\n6. Drink 20-30 minutes before workout.",
                   calories: 350, protein: 45, carbs: 40, fat: 5, prepTime: 3),
            Recipe(id: "2", name: "Quick Oats & Egg Scramble", type: "Meal", week: "Week A", mealSlot: "Breakfast",
                   ingredients: "3 whole eggs, 1 cup liquid egg whites, 1 tsp olive oil, 1.5 cups instant oatmeal, 1 tbsp almond butter, 1/2 cup blueberries",
                   instructions: "1. Microwave oats with water for 2 minutes.\n2. Heat olive oil in pan over medium heat.\n3. Scramble eggs and egg whites together in pan for 3 minutes.\n4. Top oats with almond butter and blueberries.\n5. Serve eggs alongside oats.",
                   calories: 650, protein: 45, carbs: 65, fat: 22, prepTime: 15),
            Recipe(id: "3", name: "Air-Fried Teriyaki Chicken & Sweet Potato", type: "Meal", week: "Week A", mealSlot: "Lunch",
                   ingredients: "6 oz chicken breast (cubed), 3 tbsp Soyaki sauce, 1.5 cups diced sweet potatoes, 1 cup broccoli florets",
                   instructions: "Sunday Prep:\n1. Dice sweet potatoes into 1-inch cubes, toss with EVOO, salt, garlic powder.\n2. Air fry at 400°F for 20-25 min.\n3. Cube chicken breast, toss with Soyaki sauce.\n4. Air fry at 380°F for 10-12 min until 165°F internal.\n5. Microwave broccoli per package.\n6. Divide into 5 containers.\n\nAt office: Microwave for 2 minutes.",
                   calories: 700, protein: 55, carbs: 95, fat: 10, prepTime: 2),
            Recipe(id: "4", name: "15-Minute Salmon & Rice Bowl", type: "Meal", week: "Week A", mealSlot: "Dinner",
                   ingredients: "6 oz salmon fillet, 2 cups Jasmine rice (microwave pouch), 1/2 avocado, 1 tbsp soy sauce",
                   instructions: "1. Air-fry salmon fillet at 400°F for 12 minutes.\n2. Microwave Jasmine rice pouch per instructions (~90 seconds).\n3. Slice avocado.\n4. Assemble bowl: rice base, salmon on top, avocado slices, drizzle soy sauce.",
                   calories: 850, protein: 45, carbs: 100, fat: 30, prepTime: 15),
            Recipe(id: "5", name: "Avocado Toast & Protein", type: "Meal", week: "Week B", mealSlot: "Breakfast",
                   ingredients: "3 slices TJ's Whole Wheat Sandwich Bread, 1/2 avocado, 4 whole eggs",
                   instructions: "1. Toast 3 slices of whole wheat bread.\n2. Mash 1/2 avocado with a fork, season with salt and pepper.\n3. Spread mashed avocado on toast.\n4. Fry or scramble 4 eggs in a pan with a little olive oil.\n5. Serve eggs alongside avocado toast.",
                   calories: 700, protein: 35, carbs: 60, fat: 35, prepTime: 10),
            Recipe(id: "6", name: "Ground Turkey & Pasta Skillet", type: "Meal", week: "Week B", mealSlot: "Lunch",
                   ingredients: "6 oz Jennie-O 93% lean ground turkey, 2 cups TJ's Organic Whole Wheat Penne, 1/2 cup TJ's Tomato Basil Marinara, 1 cup green beans",
                   instructions: "Sunday Prep:\n1. Boil pasta per package (10-12 min), drain.\n2. Brown 2.5 lbs ground turkey in large pan, season with garlic powder, onion powder, salt, pepper.\n3. Add pasta and 2.5 cups marinara, stir and heat 3-4 min.\n4. Steam green beans in microwave.\n5. Divide into 5 containers.\n\nAt office: Microwave for 2 minutes.",
                   calories: 750, protein: 50, carbs: 90, fat: 18, prepTime: 2),
            Recipe(id: "7", name: "Quick Beef & Rice Stir-Fry", type: "Meal", week: "Week B", mealSlot: "Dinner",
                   ingredients: "6 oz Sprouts 90/10 ground beef, 2 cups Jasmine rice (microwave pouch), 1 cup TJ's Stir Fry Vegetables (frozen), 1 tbsp Kadoya sesame oil, 1 tbsp soy sauce",
                   instructions: "1. Brown ground beef in pan over medium-high heat for 7 minutes, breaking apart as it cooks.\n2. Add frozen stir fry vegetables directly to pan, cook 5 minutes stirring occasionally.\n3. Microwave Jasmine rice pouch (~90 seconds).\n4. Serve beef and veggie mix over rice.\n5. Drizzle sesame oil and soy sauce over top.",
                   calories: 800, protein: 45, carbs: 95, fat: 25, prepTime: 15),
            Recipe(id: "8", name: "Intra-Workout XS Muscle Multiplier", type: "Shake", week: "Both", mealSlot: "Intra-Workout",
                   ingredients: "1 serving XS Muscle Multiplier (Berry Blast or Watermelon), 16 oz water",
                   instructions: "1. Fill shaker bottle with 16 oz cold water.\n2. Add 1 serving XS Muscle Multiplier powder.\n3. Shake well.\n4. Sip throughout your entire workout session.",
                   calories: 50, protein: 4, carbs: 5, fat: 0, prepTime: 1),
            Recipe(id: "9", name: "Evening Protein Shake (Optional)", type: "Shake", week: "Both", mealSlot: "Evening Shake",
                   ingredients: "1 scoop Nutrilite Plant Protein, 1 tbsp TJ's Creamy Salted Peanut Butter, 1 cup TJ's Oat Beverage Unsweetened",
                   instructions: "1. Add oat milk to blender or shaker.\n2. Add 1 scoop Nutrilite Plant Protein.\n3. Add 1 tbsp peanut butter.\n4. Blend or shake until smooth.\n5. Drink in the evening, ideally 1-2 hours before bed.",
                   calories: 250, protein: 25, carbs: 20, fat: 10, prepTime: 3)
        ]
    }
}

// MARK: - Recipe Detail Sheet
struct RecipeDetailSheet: View {
    let recipe: Recipe
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                LinearGradient(colors: [.green.opacity(0.25), .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Macros Row
                        HStack(spacing: 12) {
                            MacroChip(label: "Calories", value: "\(recipe.calories)", color: .orange)
                            MacroChip(label: "Protein", value: "\(recipe.protein)g", color: .green)
                            MacroChip(label: "Carbs", value: "\(recipe.carbs)g", color: .blue)
                            MacroChip(label: "Fat", value: "\(recipe.fat)g", color: .yellow)
                        }
                        .padding(.horizontal)
                        
                        // Prep Time
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.white.opacity(0.6))
                            Text("Prep: \(recipe.prepTime) min")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal)
                        
                        // Ingredients
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ingredients")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(recipe.ingredients)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(4)
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 20)
                        .padding(.horizontal)
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Instructions")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(recipe.instructions)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(6)
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 20)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct MacroChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .bold()
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 14)
    }
}

// MARK: - Recipe Row
struct RecipeRow: View {
    let recipe: Recipe
    var onTap: () -> Void
    
    var slotColor: Color {
        switch recipe.mealSlot {
        case "Breakfast": return .orange
        case "Lunch": return .green
        case "Dinner": return .blue
        case "Pre-Workout Shake": return .yellow
        case "Intra-Workout": return .red
        case "Evening Shake": return .purple
        default: return .white
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(slotColor)
                    .frame(width: 4, height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.mealSlot)
                        .font(.caption)
                        .foregroundColor(slotColor)
                        .textCase(.uppercase)
                    Text(recipe.name)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(recipe.calories) kcal")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(recipe.protein)g Pro")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.green)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .liquidGlass(cornerRadius: 18)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Main View
struct MealPlanView: View {
    @StateObject private var viewModel = MealPlanViewModel()
    @State private var selectedRecipe: Recipe? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.5, blue: 0.2).opacity(0.4), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: Week Selector
                        HStack(spacing: 0) {
                            ForEach(["Week A", "Week B"], id: \.self) { week in
                                Button(action: { viewModel.selectedWeek = week }) {
                                    Text(week)
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(viewModel.selectedWeek == week ? .black : .white.opacity(0.7))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            viewModel.selectedWeek == week
                                                ? Color.green
                                                : Color.clear
                                        )
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(4)
                        .liquidGlass(cornerRadius: 16)
                        .padding(.horizontal)
                        
                        // MARK: Macro Summary
                        HStack(spacing: 12) {
                            MacroChip(label: "Calories", value: "\(viewModel.totalCalories)", color: .orange)
                            MacroChip(label: "Protein", value: "\(viewModel.totalProtein)g", color: .green)
                            VStack(spacing: 2) {
                                Text("Target")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(viewModel.proteinTarget)g")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(viewModel.totalProtein >= viewModel.proteinTarget ? .green : .orange)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .liquidGlass(cornerRadius: 14)
                        }
                        .padding(.horizontal)
                        
                        // MARK: Shakes Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Shakes")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.shakes) { recipe in
                                RecipeRow(recipe: recipe) {
                                    selectedRecipe = recipe
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // MARK: Meals Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Meals — \(viewModel.selectedWeek)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.meals) { recipe in
                                RecipeRow(recipe: recipe) {
                                    selectedRecipe = recipe
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Meal Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Button(action: { Task { await viewModel.loadRecipes() } }) {
                            Image(systemName: "arrow.clockwise").foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailSheet(recipe: recipe)
            }
            .task {
                await viewModel.loadRecipes()
            }
        }
    }
}

#Preview {
    MealPlanView()
}
