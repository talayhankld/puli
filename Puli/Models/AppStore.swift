import SwiftUI
import Observation

// MARK: - Task Models
enum PuliTaskCategory: String, Codable, CaseIterable {
    case study = "Odak"
    case movement = "Hareket"
    case quick = "Hızlı"
    case chore = "Düzen"
}

struct PuliTask: Identifiable {
    let id = UUID()
    let title: String
    let durationMinutes: Int
    let coinReward: Int
    let category: PuliTaskCategory
    let iconName: String
    let tags: [String]
    let mascotAssetName: String
}

extension PuliTask {
    static let allTasks: [PuliTask] = [
        PuliTask(title: "Odanı Toparla", durationMinutes: 15, coinReward: 50, category: .chore, iconName: "bed.double.fill", tags: ["Ev İşleri", "Düzen"], mascotAssetName: "mascot_cleaning"),
        PuliTask(title: "Büyük Bardak Su İç", durationMinutes: 2, coinReward: 10, category: .quick, iconName: "drop.fill", tags: ["Sağlık", "Hızlı"], mascotAssetName: "mascot_drinking"),
        PuliTask(title: "Yoga / Esneme", durationMinutes: 20, coinReward: 70, category: .movement, iconName: "figure.mind.and.body", tags: ["Yoga", "Sağlık"], mascotAssetName: "mascot_yoga"),
        PuliTask(title: "Matematik / Analitik", durationMinutes: 45, coinReward: 150, category: .study, iconName: "function", tags: ["Ders", "Akademik"], mascotAssetName: "mascot_studying"),
        PuliTask(title: "Yazılım / Kodlama", durationMinutes: 60, coinReward: 200, category: .study, iconName: "laptopcomputer", tags: ["Yazılım", "Odak"], mascotAssetName: "mascot_computer"),
        PuliTask(title: "Açık Hava Koşusu", durationMinutes: 30, coinReward: 120, category: .movement, iconName: "figure.run", tags: ["Kardiyo", "Spor"], mascotAssetName: "mascot_fitness"),
        PuliTask(title: "Basketbol Antrenmanı", durationMinutes: 45, coinReward: 140, category: .movement, iconName: "basketball.fill", tags: ["Spor", "Kardiyo"], mascotAssetName: "mascot_balling"),
        PuliTask(title: "Kaykay / Paten", durationMinutes: 30, coinReward: 100, category: .movement, iconName: "figure.roll", tags: ["Spor", "Açık Hava"], mascotAssetName: "mascot_skating")
    ]
    
    static let mockTasks: [PuliTask] = Array(allTasks.prefix(4))
}

// MARK: - Achievement Model
struct PuliAchievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    var isUnlocked: Bool
    let requirementCount: Int
}

// MARK: - Görev Tamamlama Kaydı (İstatistik ekranı için)
struct TaskCompletionRecord: Identifiable {
    let id = UUID()
    let date: Date
    let taskTitle: String
    let category: PuliTaskCategory
    let coinsEarned: Int
}

// MARK: - Skill Tree Milestone Açılış Bildirimi
// Bir kategori yeni bir milestone seviyesine ulaştığında (2, 4, 6, 8) tetiklenir.
struct SkillMilestoneUnlock: Identifiable {
    let id = UUID()
    let category: PuliTaskCategory
    let level: Int
    let title: String
}

// MARK: - App Store
@Observable
final class AppStore {
    var puliCoins: Int = 0
    
    var isShieldActive: Bool = true
    var activeUnlockRemainingSeconds: Int = 0
    var activeSessionTotalSeconds: Int = 0
    var isConsumingScreenTime: Bool = false
    
    var userInterests: Set<String> = []
    
    var streakCount: Int = 0
    var longestStreak: Int = 0
    var completedTasksCount: Int = 0
    var newlyUnlockedAchievement: PuliAchievement? = nil
    
    private(set) var completionHistory: [TaskCompletionRecord] = []
    
    // 👇 YENİ: Kategori başına biriken XP. Skill tree seviyeleri buradan hesaplanıyor.
    var categoryXP: [PuliTaskCategory: Int] = Dictionary(
        uniqueKeysWithValues: PuliTaskCategory.allCases.map { ($0, 0) }
    )
    
    // 👇 YENİ: Bir kategori yeni milestone'a ulaştığında UI'da popup göstermek için.
    var newlyReachedMilestone: SkillMilestoneUnlock? = nil
    
    // Skill tree ayarları: maksimum seviye ve seviye eşik fonksiyonu
    private let maxSkillLevel = 8
    
    private func xpThreshold(for level: Int) -> Int {
        guard level > 0 else { return 0 }
        // Üçgensel artış: her seviye bir öncekinden biraz daha zor.
        // Sv1: 100, Sv2: 300, Sv3: 600, Sv4: 1000, Sv5: 1500, Sv6: 2100, Sv7: 2800, Sv8: 3600
        return 100 * level * (level + 1) / 2
    }
    
    // Bir kategorinin şu anki seviyesini hesaplar
    func skillLevel(for category: PuliTaskCategory) -> Int {
        let xp = categoryXP[category] ?? 0
        var level = 0
        while level < maxSkillLevel && xp >= xpThreshold(for: level + 1) {
            level += 1
        }
        return level
    }
    
    // Bir kategorinin ilerleme çubuğu için gereken veriyi hesaplar
    func skillProgress(for category: PuliTaskCategory) -> (current: Int, currentLevelXP: Int, nextLevelXP: Int, fraction: Double) {
        let xp = categoryXP[category] ?? 0
        let level = skillLevel(for: category)
        
        if level >= maxSkillLevel {
            let cap = xpThreshold(for: level)
            return (xp, cap, cap, 1.0)
        }
        
        let lowerBound = xpThreshold(for: level)
        let upperBound = xpThreshold(for: level + 1)
        let fraction = upperBound > lowerBound
            ? Double(xp - lowerBound) / Double(upperBound - lowerBound)
            : 0
        
        return (xp, lowerBound, upperBound, min(max(fraction, 0), 1))
    }
    
    // Kategoriye XP ekler, seviye atlandıysa ve bu bir milestone seviyesiyse popup tetikler
    private func awardSkillXP(_ amount: Int, to category: PuliTaskCategory) {
        let previousLevel = skillLevel(for: category)
        categoryXP[category, default: 0] += amount
        let newLevel = skillLevel(for: category)
        
        if newLevel > previousLevel, let milestoneTitle = category.milestoneTitles[newLevel] {
            newlyReachedMilestone = SkillMilestoneUnlock(category: category, level: newLevel, title: milestoneTitle)
        }
    }
    
    func clearMilestonePopup() {
        newlyReachedMilestone = nil
    }
    
    @ObservationIgnored private var lastActiveDate: Date?
    @ObservationIgnored private var sessionEndDate: Date?
    
    var achievements: [PuliAchievement] = [
        PuliAchievement(title: "İlk Adım", description: "İlk görevini başarıyla tamamla.", iconName: "star.fill", isUnlocked: false, requirementCount: 1),
        PuliAchievement(title: "Odak Ustası", description: "Toplam 5 görev tamamla.", iconName: "flame.fill", isUnlocked: false, requirementCount: 5),
        PuliAchievement(title: "Zaman Bükücü", description: "Mağazadan ilk defa ekran süresi al.", iconName: "clock.fill", isUnlocked: false, requirementCount: 1),
        PuliAchievement(title: "Kararlı Kuş", description: "5 gün üst üste seriyi koru.", iconName: "shield.fill", isUnlocked: false, requirementCount: 5)
    ]
    
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    
    deinit {
        timerTask?.cancel()
    }
    
    var recommendedTasks: [PuliTask] {
        if userInterests.isEmpty {
            return Array(PuliTask.allTasks.prefix(4))
        }
        return PuliTask.allTasks.filter { task in
            !Set(task.tags).isDisjoint(with: userInterests)
        }
    }
    
    func saveInterests(_ interests: Set<String>) {
        self.userInterests = interests
    }
    
    // Görev tamamlandığında: coin, geçmiş kaydı, streak, başarımlar VE artık skill XP'si
    func completeTask(_ task: PuliTask) {
        puliCoins += task.coinReward
        completedTasksCount += 1
        
        let record = TaskCompletionRecord(
            date: Date(),
            taskTitle: task.title,
            category: task.category,
            coinsEarned: task.coinReward
        )
        completionHistory.append(record)
        
        awardSkillXP(task.coinReward, to: task.category) // 👈 YENİ
        
        updateStreak()
        checkAchievements()
    }
    
    // Geriye dönük uyumluluk için — geçmişe kayıt düşmez, skill XP verilmez
    // (hangi görev/kategori olduğu bilinmiyor). Yeni entegrasyonlarda completeTask(_:) kullan.
    func addCoins(_ amount: Int) {
        puliCoins += amount
        completedTasksCount += 1
        updateStreak()
        checkAchievements()
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lastDate = lastActiveDate else {
            streakCount = 1
            lastActiveDate = today
            longestStreak = max(longestStreak, streakCount)
            return
        }
        
        let lastDay = calendar.startOfDay(for: lastDate)
        let dayDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        
        switch dayDifference {
        case 0:
            break
        case 1:
            streakCount += 1
            lastActiveDate = today
        default:
            streakCount = 1
            lastActiveDate = today
        }
        
        longestStreak = max(longestStreak, streakCount)
    }

    private func checkAchievements() {
        for i in 0..<achievements.count {
            if !achievements[i].isUnlocked {
                var shouldUnlock = false
                
                if achievements[i].title == "İlk Adım" && completedTasksCount >= achievements[i].requirementCount {
                    shouldUnlock = true
                }
                else if achievements[i].title == "Odak Ustası" && completedTasksCount >= achievements[i].requirementCount {
                    shouldUnlock = true
                }
                else if achievements[i].title == "Kararlı Kuş" && streakCount >= achievements[i].requirementCount {
                    shouldUnlock = true
                }
                
                if shouldUnlock {
                    achievements[i].isUnlocked = true
                    newlyUnlockedAchievement = achievements[i]
                    break
                }
            }
        }
    }
    
    func clearAchievementPopup() {
        newlyUnlockedAchievement = nil
    }
    
    func purchaseScreenTime(minutes: Int, cost: Int) -> Bool {
        if puliCoins >= cost {
            puliCoins -= cost
            startScreenTimeSession(minutes: minutes)
            
            if let index = achievements.firstIndex(where: { $0.title == "Zaman Bükücü" }), !achievements[index].isUnlocked {
                achievements[index].isUnlocked = true
                newlyUnlockedAchievement = achievements[index]
            }
            
            return true
        }
        return false
    }
    
    func startScreenTimeSession(minutes: Int) {
        let requestedSeconds = minutes * 60
        activeSessionTotalSeconds = requestedSeconds
        activeUnlockRemainingSeconds = requestedSeconds
        isShieldActive = false
        isConsumingScreenTime = true
        startCountdown()
    }
    
    func endScreenTimeSession() {
        stopTimer()
        isShieldActive = true
        isConsumingScreenTime = false
        activeUnlockRemainingSeconds = 0
        activeSessionTotalSeconds = 0
        sessionEndDate = nil
    }
    
    @MainActor
    private func startCountdown() {
        stopTimer()
        
        let endDate = Date().addingTimeInterval(TimeInterval(activeUnlockRemainingSeconds))
        sessionEndDate = endDate
        
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let endDate = sessionEndDate else { break }
                
                let secondsLeft = max(0, Int(endDate.timeIntervalSinceNow.rounded()))
                activeUnlockRemainingSeconds = secondsLeft
                
                if secondsLeft <= 0 {
                    endScreenTimeSession()
                    break
                }
            }
        }
    }
    
    @MainActor
    func refreshActiveSessionIfNeeded() {
        guard isConsumingScreenTime, let endDate = sessionEndDate else { return }
        
        let secondsLeft = max(0, Int(endDate.timeIntervalSinceNow.rounded()))
        activeUnlockRemainingSeconds = secondsLeft
        
        if secondsLeft <= 0 {
            endScreenTimeSession()
        }
    }
    
    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}
