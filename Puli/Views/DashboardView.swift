import SwiftUI
import FamilyControls

struct DashboardView: View {
    @Environment(AppStore.self) private var store
    @Environment(RealShieldService.self) private var shieldService
    
    @State private var selectedTask: PuliTask?
    @State private var isStorePresented = false
    @State private var isPickerPresented = false
    @State private var showAchievements = false
    
    // 👇 YENİ: Maskotun olay-bazlı görünürlüğünü yöneten state. Alt view'lara
    // (TopBarView) environment ile aktarılıyor.
    @State private var companion = PuliCompanionState()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.puliBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        TopBarView(isPickerPresented: $isPickerPresented, showAchievements: $showAchievements)
                        
                        timeWalletPill
                        
                        statusCard
                        
                        quickTasksSection
                    }
                    .padding(.vertical)
                }
                
                // Başarım Açıldığında Üstten Süzülen Toast / Banner Pop-up Katmanı
                if let achievement = store.newlyUnlockedAchievement {
                    VStack {
                        achievementPopup(for: achievement)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: store.newlyUnlockedAchievement != nil)
                            .padding(.top, 16)
                            .id(achievement.id)
                            .onAppear {
                                let shownAchievementID = achievement.id
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                    guard store.newlyUnlockedAchievement?.id == shownAchievementID else { return }
                                    withAnimation {
                                        store.clearAchievementPopup()
                                    }
                                }
                            }
                        
                        Spacer()
                    }
                    .zIndex(100)
                }
                
                // Skill Tree Milestone Açılış Popup'ı
                if let milestone = store.newlyReachedMilestone {
                    VStack {
                        Spacer()
                        skillMilestonePopup(for: milestone)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: store.newlyReachedMilestone != nil)
                            .padding(.bottom, 30)
                            .id(milestone.id)
                            .onAppear {
                                let shownID = milestone.id
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                    guard store.newlyReachedMilestone?.id == shownID else { return }
                                    withAnimation {
                                        store.clearMilestonePopup()
                                    }
                                }
                            }
                    }
                    .zIndex(110)
                }
            }
            .environment(companion) // 👈 YENİ: TopBarView'a companion state'ini aktar
            .sheet(item: $selectedTask) { task in
                FocusSessionView(task: task) {
                    store.completeTask(task)
                }
                .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
                    .environment(store)
            }
            // 👇 YENİ: Olay-bazlı tetikleyiciler. Her biri anlamlı bir durum
            // değişikliğinde, spesifik bir mesajla maskotu çağırıyor.
            .task {
                try? await Task.sleep(for: .seconds(1.2))
                companion.trigger("Merhaba! Ben Puli, birlikte odaklanalım 👋", force: true)
            }
            .onChange(of: store.completedTasksCount) { oldValue, newValue in
                guard newValue > oldValue else { return }
                companion.trigger("Harika iş! Bir görevi daha bitirdin 🎉")
            }
            .onChange(of: store.isConsumingScreenTime) { oldValue, newValue in
                guard !oldValue && newValue else { return }
                let minutes = store.activeUnlockRemainingSeconds / 60
                companion.trigger("İyi eğlenceler! ~\(minutes) dk ekran sürene bakıyorum ⏳")
            }
            .onChange(of: store.puliCoins) { oldValue, newValue in
                guard oldValue >= 50 && newValue < 50 else { return }
                companion.trigger("Puanların azaldı, hızlı bir görev yapalım mı? 🌿")
            }
            .onChange(of: store.streakCount) { oldValue, newValue in
                guard newValue > oldValue && newValue >= 3 else { return }
                companion.trigger("\(newValue) günlük serin harika, devam! 🔥")
            }
        }
    }
    
    // MARK: - Subviews
    
    private func achievementPopup(for achievement: PuliAchievement) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.puliAccentYellow)
                    .frame(width: 48, height: 48)
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("🎉 Yeni Başarım Açıldı!")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.puliPrimary)
                
                Text(achievement.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.puliCharcoal)
                
                Text(achievement.description)
                    .font(.caption2)
                    .foregroundColor(.puliCharcoal.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.puliSurface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.puliAccentYellow.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: Color.puliCharcoal.opacity(0.1), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 20)
        .onTapGesture {
            withAnimation {
                store.clearAchievementPopup()
            }
        }
    }
    
    private func skillMilestonePopup(for milestone: SkillMilestoneUnlock) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(milestone.category.skillColor)
                    .frame(width: 48, height: 48)
                
                Image(systemName: milestone.category.skillIcon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("⭐ Yeni Seviye!")
                    .font(.caption.weight(.bold))
                    .foregroundColor(milestone.category.skillColor)
                
                Text("\(milestone.category.rawValue) — Sv. \(milestone.level)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.puliCharcoal)
                
                Text("\"\(milestone.title)\" unvanını açtın")
                    .font(.caption2)
                    .foregroundColor(.puliCharcoal.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.puliSurface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(milestone.category.skillColor.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: Color.puliCharcoal.opacity(0.1), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 20)
        .onTapGesture {
            withAnimation {
                store.clearMilestonePopup()
            }
        }
    }
    
    private var timeWalletPill: some View {
        Button(action: {
            isStorePresented = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.puliPrimary)
                
                Text("\(store.puliCoins) Puan")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.puliCharcoal)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.puliCharcoal.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.puliSurface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.puliBeige.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: .puliCharcoal.opacity(0.03), radius: 4, y: 2)
        }
        .sheet(isPresented: $isStorePresented) {
            StoreView()
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: 20) {
            if store.isConsumingScreenTime {
                activeSessionContent
            } else {
                shieldActiveContent
            }
        }
        .puliCardStyle()
        .padding(.horizontal, 20)
    }
    
    private var activeSessionContent: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.puliBeige.opacity(0.5), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: progressTrim)
                    .stroke(Color.puliPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: store.activeUnlockRemainingSeconds)
                
                VStack {
                    Text(timeString(from: store.activeUnlockRemainingSeconds))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.puliCharcoal)
                        .monospacedDigit()
                    
                    Text("Kaldı")
                        .font(.caption)
                        .foregroundColor(.puliCharcoal.opacity(0.6))
                }
            }
            .frame(height: 160)
            .padding(.vertical, 8)
            
            Text("Ekran süren başladı. İyi eğlenceler!")
                .font(.subheadline)
                .foregroundColor(.puliCharcoal.opacity(0.7))
            
            Button(action: {
                store.endScreenTimeSession()
            }) {
                VStack(spacing: 4) {
                    Text("Kalkanı Geri Aç")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("(Kalan süre silinir)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.puliInkFixed)
                .cornerRadius(16)
            }
        }
    }
    
    private var shieldActiveContent: some View {
        VStack(spacing: 16) {
            PuliMascotView(mood: .calm)
                .scaleEffect(0.8)
                .frame(height: 80)
            
            VStack(spacing: 8) {
                Text("Uygulamalar dinleniyor.")
                    .font(.headline)
                    .foregroundColor(.puliCharcoal)
                
                Text("Kilidi açmak için görev tamamlayıp puan kazan veya mağazadan süre al.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.puliCharcoal.opacity(0.7))
                    .padding(.horizontal, 8)
            }
            
            Button(action: {
                isStorePresented = true
            }) {
                Text("Mağazaya Git")
                    .font(.headline)
                    .foregroundColor(.puliInkFixed)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.puliAccentYellow)
                    .cornerRadius(16)
            }
            .padding(.top, 8)
        }
    }
    
    private var quickTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Görev Seç")
                .font(.headline)
                .foregroundColor(.puliCharcoal)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(store.recommendedTasks) { task in
                        Button(action: {
                            selectedTask = task
                        }) {
                            taskCard(for: task)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
    }
    
    private func taskCard(for task: PuliTask) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: task.iconName)
                .font(.system(size: 24))
                .foregroundColor(.puliPrimary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.puliCharcoal)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("+\(task.coinReward) Puan")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.puliPrimary)
            }
        }
        .padding(16)
        .frame(width: 140, height: 140, alignment: .topLeading)
        .background(Color.puliSurface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.puliBeige.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: .puliCharcoal.opacity(0.02), radius: 8, y: 4)
    }
    
    // MARK: - Helpers
    
    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private var progressTrim: CGFloat {
        let total = max(store.activeSessionTotalSeconds, 1)
        let fraction = CGFloat(store.activeUnlockRemainingSeconds) / CGFloat(total)
        return min(max(fraction, 0.01), 1.0)
    }
}

// MARK: - Top Bar Subview (düzeltilmiş: artık aşağı sarkıyor, safe area/notch ile çakışmıyor)
struct TopBarView: View {
    @Environment(AppStore.self) private var store
    @Environment(RealShieldService.self) private var shieldService
    @Environment(PuliCompanionState.self) private var companion
    @Binding var isPickerPresented: Bool
    @Binding var showAchievements: Bool
    
    @State private var isSettingsPresented = false
    
    private var mascotAsset: String {
        if store.isConsumingScreenTime {
            return "mascot_walking"
        } else if store.puliCoins < 50 {
            return "mascot_reading"
        } else {
            return "mascot_standing"
        }
    }
    
    var body: some View {
        @Bindable var shieldService = shieldService
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image("PuliWordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 42)
                
                Spacer()
                
                // 👇 DÜZELTİLDİ: overlay artık iconRow'a bağlı, .bottom hizalı.
                // Balon yukarı (notch'a doğru) değil, AŞAĞI doğru sarkıyor —
                // her zaman ekranın güvenli/dolu alanında kalıyor.
                iconRow
                    .overlay(alignment: .bottom) {
                        if companion.isVisible {
                            companionPeek
                                .offset(y: 46) // butonların hemen altına sarkıyor
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.puliCharcoal.opacity(0.6))
                    .textCase(.uppercase)
                
                Text("Merhaba, Talayhan 👋")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.puliCharcoal)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var iconRow: some View {
        HStack(spacing: 10) {
            Button(action: {
                showAchievements = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.puliAccentYellow)
                        .font(.subheadline)
                    
                    Text("\(store.streakCount)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.puliCharcoal)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.puliSurface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.puliBeige.opacity(0.6), lineWidth: 1)
                )
            }
            
            Button(action: {
                isSettingsPresented = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.puliCharcoal.opacity(0.5))
                    .padding(8)
                    .background(Color.puliSurface)
                    .clipShape(Circle())
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
                    .environment(store)
                    .environment(shieldService)
            }
        }
    }
    
    // Balon + kırpılmış maskot başı, butonların hemen ALTINDA sarkıyor (yukarı değil)
    private var companionPeek: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Baş, butonların alt kenarından "sarkan" bir görünüm için üstten kırpılı
            Image(mascotAsset)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .frame(height: 18, alignment: .top)
                .clipShape(
                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 10, bottomTrailingRadius: 10, topTrailingRadius: 0)
                )
                .shadow(color: Color.puliCharcoal.opacity(0.12), radius: 4, x: 0, y: 2)
            
            speechBubble
        }
        .fixedSize()
        .onTapGesture {
            companion.dismiss()
        }
    }
    
    private var speechBubble: some View {
        Text(companion.message)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.puliCharcoal)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 160, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.puliSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.puliPrimary.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: Color.puliCharcoal.opacity(0.1), radius: 6, x: 0, y: 3)
            )
    }
}
// MARK: - Preview
#Preview {
    let store = AppStore()
    store.completeTask(PuliTask.allTasks[4])
    
    return DashboardView()
        .environment(store)
        .environment(RealShieldService())
}
