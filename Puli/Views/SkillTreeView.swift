import SwiftUI

// MARK: - Kategori Görsel Kimliği (Skill Tree için ikon, renk, milestone unvanları)
extension PuliTaskCategory {
    var skillIcon: String {
        switch self {
        case .study: return "brain.head.profile"
        case .movement: return "figure.run"
        case .quick: return "bolt.fill"
        case .chore: return "house.fill"
        }
    }
    
    var skillColor: Color {
        switch self {
        case .study: return .puliPrimary
        case .movement: return .puliAccentYellow
        case .quick: return Color(hex: "6FA8DC")
        case .chore: return Color(hex: "B08968")
        }
    }
    
    // Seviye 2, 4, 6, 8'de açılan kategoriye özel unvanlar
    var milestoneTitles: [Int: String] {
        switch self {
        case .study: return [2: "Öğrenci", 4: "Araştırmacı", 6: "Uzman", 8: "Bilge"]
        case .movement: return [2: "Acemi Sporcu", 4: "Formda", 6: "Atlet", 8: "Şampiyon"]
        case .quick: return [2: "Pratik Eller", 4: "Çevik", 6: "Usta El", 8: "Yıldırım Hızı"]
        case .chore: return [2: "Derli Toplu", 4: "Titiz", 6: "Düzen Ustası", 8: "Kusursuz"]
        }
    }
}

// MARK: - Skill Tree Ana İçerik
struct SkillTreeContentView: View {
    @Environment(AppStore.self) private var store
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Her görev, kategorisine göre XP kazandırır. Seviye atladıkça yeni unvanlar açılır.")
                .font(.caption)
                .foregroundColor(.puliCharcoal.opacity(0.6))
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                ForEach(PuliTaskCategory.allCases, id: \.self) { category in
                    skillCategoryCard(for: category)
                }
            }
        }
    }
    
    private func skillCategoryCard(for category: PuliTaskCategory) -> some View {
        let level = store.skillLevel(for: category)
        let progress = store.skillProgress(for: category)
        let currentTitle = highestUnlockedTitle(for: category, level: level)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.skillColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: category.skillIcon)
                        .font(.system(size: 18))
                        .foregroundColor(category.skillColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.puliCharcoal)
                    
                    if let currentTitle {
                        Text(currentTitle)
                            .font(.caption)
                            .foregroundColor(category.skillColor)
                    } else {
                        Text("Henüz unvan yok")
                            .font(.caption)
                            .foregroundColor(.puliCharcoal.opacity(0.4))
                    }
                }
                
                Spacer()
                
                Text("Sv. \(level)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(category.skillColor)
                    .clipShape(Capsule())
            }
            
            skillLadder(for: category, currentLevel: level)
            
            if level < 8 {
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.puliBeige.opacity(0.5))
                                .frame(height: 8)
                            Capsule()
                                .fill(category.skillColor)
                                .frame(width: geo.size.width * progress.fraction, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(progress.current - progress.currentLevelXP)/\(progress.nextLevelXP - progress.currentLevelXP) XP")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.puliCharcoal.opacity(0.5))
                }
            } else {
                Text("Maksimum seviyeye ulaştın! 🎉")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(category.skillColor)
            }
        }
        .padding(16)
        .background(Color.puliSurface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.puliBeige.opacity(0.6), lineWidth: 1)
        )
    }
    
    private func highestUnlockedTitle(for category: PuliTaskCategory, level: Int) -> String? {
        category.milestoneTitles
            .filter { $0.key <= level }
            .sorted { $0.key > $1.key }
            .first?.value
    }
    
    // 1'den 8'e uzanan yatay düğüm zinciri. Milestone seviyeler (2,4,6,8) büyük
    // yıldızlı düğümler + unvan etiketiyle, ara seviyeler küçük noktalarla gösteriliyor.
    private func skillLadder(for category: PuliTaskCategory, currentLevel: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(1...8, id: \.self) { level in
                    let isMilestone = category.milestoneTitles[level] != nil
                    let isReached = level <= currentLevel
                    
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(isReached ? category.skillColor : Color.puliBeige.opacity(0.5))
                                    .frame(width: isMilestone ? 34 : 18, height: isMilestone ? 34 : 18)
                                
                                if isMilestone {
                                    Image(systemName: isReached ? "star.fill" : "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(isReached ? .white : .puliCharcoal.opacity(0.3))
                                }
                            }
                            
                            if isMilestone {
                                Text(category.milestoneTitles[level] ?? "")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(isReached ? .puliCharcoal : .puliCharcoal.opacity(0.35))
                                    .fixedSize()
                            }
                        }
                        .frame(width: isMilestone ? 60 : 30)
                        
                        if level < 8 {
                            Rectangle()
                                .fill(level < currentLevel ? category.skillColor : Color.puliBeige.opacity(0.5))
                                .frame(width: 16, height: 3)
                                .padding(.bottom, isMilestone ? 16 : 0)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    let store = AppStore()
    store.completeTask(PuliTask.allTasks[3])
    store.completeTask(PuliTask.allTasks[4])
    store.completeTask(PuliTask.allTasks[3])
    
    return ScrollView {
        SkillTreeContentView()
            .padding(20)
    }
    .background(Color.puliBackground)
    .environment(store)
}
