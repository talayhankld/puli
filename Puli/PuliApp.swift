import SwiftUI

@main
struct PuliApp: App {
    @State private var store = AppStore()
    @State private var authManager = AuthManager()
    @State private var shieldService = RealShieldService()
    
    // Kullanıcının testi bitirip bitirmediğini saklar
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    // Karanlık mod ayarı (Tüm uygulamayı yönetir)
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    NavigationStack {
                        DashboardView()
                            .environment(store)
                            .environment(authManager)
                            .environment(shieldService)
                    }
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .environment(store)
                }
            }
            .tint(Color.puliPrimary)
            .background(Color.puliBackground)
            .preferredColorScheme(isDarkModeEnabled ? .dark : .light) // KÖK TEMA BAĞLANTISI
            .onAppear {
                // TEST İÇİN HER AÇILIŞTA ONBOARDING AKIŞINI GETİRİR:
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                
                Task {
                    _ = try? await shieldService.requestAuthorization()
                }
            }
        }
    }
}
