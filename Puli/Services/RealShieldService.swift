import Foundation
import FamilyControls
import ManagedSettings
import Observation

// MARK: - Shield Managing Protocol
// Bu kısım silindiği için hata alıyordun, şimdi tekrar ekledik.
protocol ShieldManaging {
    func enableShield() async throws
    func disableShield() async throws
    func requestAuthorization() async throws -> Bool
}

// MARK: - Real Shield Service Implementation
@MainActor
@Observable
class RealShieldService: ShieldManaging {
    @ObservationIgnored let managedSettingsStore = ManagedSettingsStore()
    var appSelection = FamilyActivitySelection()
    var hasScreenTimePermission = false
    
    func requestAuthorization() async throws -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            self.hasScreenTimePermission = true
            print("✅ Yetki başarıyla alındı.")
            return true
        } catch {
            print("❌ Yetki alınamadı veya reddedildi: \(error.localizedDescription)")
            self.hasScreenTimePermission = false
            return false
        }
    }
    
    func enableShield() async throws {
        managedSettingsStore.shield.applications = appSelection.applicationTokens
        managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(appSelection.categoryTokens)
        print("🛡️ RealShieldService: Kalkan AKTİF.")
    }
    
    func disableShield() async throws {
        managedSettingsStore.shield.applications = nil
        managedSettingsStore.shield.applicationCategories = nil
        print("🔓 RealShieldService: Kalkan PASİF.")
    }
}
