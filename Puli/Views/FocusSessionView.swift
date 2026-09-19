import SwiftUI

struct FocusSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    let task: PuliTask
    let onComplete: () -> Void   // 👈 DEĞİŞTİ: (Int) -> Void yerine parametresiz. Coin miktarını
                                   // DashboardView zaten task üzerinden biliyor, tekrar taşımaya gerek yok.
    
    // State Variables
    @State private var remainingSeconds: Int
    @State private var isRunning: Bool = false
    @State private var isCompleted: Bool = false
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var showExitConfirmation: Bool = false
    
    @State private var sessionEndDate: Date? = nil
    @State private var pausedRemainingSeconds: Int
    
    private let totalSeconds: Int
    
    init(task: PuliTask, onComplete: @escaping () -> Void) {
        self.task = task
        self.onComplete = onComplete
        
        let seconds = max(task.durationMinutes * 60, 1)
        _remainingSeconds = State(initialValue: seconds)
        _pausedRemainingSeconds = State(initialValue: seconds)
        totalSeconds = seconds
    }
    
    var body: some View {
        ZStack {
            Color.puliBackground.ignoresSafeArea()
            
            if isCompleted {
                completionOverlay
            } else {
                sessionContent
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            stopTimer()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .interactiveDismissDisabled(!isCompleted)
        .alert("Seansı Bırakmak İstiyor musun?", isPresented: $showExitConfirmation) {
            Button("Devam Et", role: .cancel) { }
            Button("Evet, Vazgeç", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Şu ana kadarki ilerlemen kaydedilmeyecek ve puan kazanamayacaksın.")
        }
    }
    
    // MARK: - Main Content
    
    private var sessionContent: some View {
        VStack(spacing: 40) {
            
            VStack(spacing: 8) {
                Text(task.category.rawValue.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundColor(.puliPrimary)
                    .tracking(2)
                
                Text(task.title)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.puliCharcoal)
            }
            .padding(.top, 40)
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.puliBeige.opacity(0.5), lineWidth: 16)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.puliPrimary, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: remainingSeconds)
                
                VStack(spacing: 16) {
                    Image(task.mascotAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .shadow(color: Color.puliPrimary.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    Text(timeString(from: remainingSeconds))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.puliCharcoal)
                        .monospacedDigit()
                }
            }
            .frame(width: 280, height: 280)
            
            Spacer()
            
            VStack(spacing: 24) {
                Button(action: {
                    if isRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(isRunning ? "Duraklat" : "Başla")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isRunning ? Color.puliAccentYellow : Color.puliPrimary)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                
                Button(action: {
                    if isRunning {
                        pauseTimer()
                    }
                    showExitConfirmation = true
                }) {
                    Text("Vazgeç")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.puliCharcoal.opacity(0.5))
                }
                
                #if DEBUG
                Button(action: {
                    triggerCompletion()
                }) {
                    Text("⏩ Fast Forward (Debug)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.puliAccentYellow)
                        .padding(.top, 20)
                }
                #endif
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Completion State
    
    private var completionOverlay: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(task.mascotAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
                .shadow(color: Color.puliPrimary.opacity(0.2), radius: 12, x: 0, y: 6)
            
            VStack(spacing: 16) {
                Text("Harika İş Çıkardın!")
                    .font(.title.weight(.bold))
                    .foregroundColor(.puliCharcoal)
                
                Text("+\(task.coinReward) Puli Puanı kazandın.")
                    .font(.title3)
                    .foregroundColor(.puliPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {
                onComplete()   // 👈 DEĞİŞTİ: parametresiz çağrı
                dismiss()
            }) {
                Text("Cüzdana Ekle & Ana Sayfaya Dön")
                    .font(.headline)
                    .foregroundColor(.puliInkFixed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.puliAccentYellow)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Logic & Helpers
    
    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(remainingSeconds) / CGFloat(totalSeconds)
    }
    
    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func startTimer() {
        isRunning = true
        
        let endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        sessionEndDate = endDate
        
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let endDate = sessionEndDate else { break }
                
                let secondsLeft = max(0, Int(endDate.timeIntervalSinceNow.rounded()))
                remainingSeconds = secondsLeft
                
                if secondsLeft <= 0 {
                    triggerCompletion()
                    break
                }
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        sessionEndDate = nil
        stopTimer()
    }
    
    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        guard isRunning, let endDate = sessionEndDate else { return }
        
        switch phase {
        case .active:
            let secondsLeft = max(0, Int(endDate.timeIntervalSinceNow.rounded()))
            remainingSeconds = secondsLeft
            if secondsLeft <= 0 && !isCompleted {
                triggerCompletion()
            }
        default:
            break
        }
    }
    
    @MainActor
    private func triggerCompletion() {
        stopTimer()
        remainingSeconds = 0
        isRunning = false
        sessionEndDate = nil
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isCompleted = true
        }
    }
}

// MARK: - Preview
#Preview {
    FocusSessionView(task: PuliTask.allTasks[4]) {
        print("Görev tamamlandı")
    }
}
