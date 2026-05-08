import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            MorningRoutineView()
                .tabItem {
                    Label("Morning", systemImage: "sunrise.fill")
                }
            
            MealPlanView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
            
            SleepTrackerView()
                .tabItem {
                    Label("Sleep", systemImage: "moon.stars.fill")
                }
            
            HealthTrackerView()
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}
