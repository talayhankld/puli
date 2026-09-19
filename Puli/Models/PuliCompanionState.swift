import SwiftUI
import Observation

// MARK: - Puli Companion State
// Maskotun ne zaman, hangi mesajla çıkacağını yönetir. Rastgele döngü YOK —
// sadece anlamlı bir olay tetiklendiğinde (trigger) çıkar, ardı ardına spam
// yapmaması için minimum bekleme süresi (cooldown) uygular.
@Observable
final class PuliCompanionState {
    private(set) var isVisible: Bool = false
    private(set) var message: String = ""
    
    @ObservationIgnored private var lastShownAt: Date = .distantPast
    @ObservationIgnored private var hideTask: Task<Void, Never>?
    
    // İki gösterim arası minimum bekleme — art arda tetikleyen olaylar
    // (ör. hem görev tamamlandı hem seri arttı) üst üste binmesin diye.
    private let minimumInterval: TimeInterval = 25
    private let visibleDuration: TimeInterval = 4.0
    
    // force: cooldown'u yok sayıp yine de göster (örn. tek seferlik karşılama mesajı için)
    func trigger(_ message: String, force: Bool = false) {
        let now = Date()
        guard force || now.timeIntervalSince(lastShownAt) > minimumInterval else { return }
        
        lastShownAt = now
        self.message = message
        
        hideTask?.cancel()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
            isVisible = true
        }
        
        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(visibleDuration))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                isVisible = false
            }
        }
    }
    
    func dismiss() {
        hideTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            isVisible = false
        }
    }
}
