import SwiftUI
import Charts

struct AchievementsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    private enum ProgressTab: String, CaseIterable {
        case achievements = "Başarımlar"
        case statistics = "İstatistik"
        case skills = "Yetenek"
    }
    
    @State private var selectedTab: ProgressTab = .achievements
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.puliBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        streakCard
                        
                        Picker("Görünüm", selection: $selectedTab) {
                            ForEach(ProgressTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        switch selectedTab {
                        case .achievements:
                            achievementsList
                        case .statistics:
                            statisticsContent
                        case .skills:
                            SkillTreeContentView()
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("İlerlemen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.puliPrimary)
                }
            }
        }
    }
    
    private var streakCard: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.puliAccentYellow.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.puliAccentYellow)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(store.streakCount) Günlük Seri! 🔥")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.puliCharcoal)
                
                Text("Zinciri kırma, her gün odaklanmaya devam et.")
                    .font(.subheadline)
                    .foregroundColor(.puliCharcoal.opacity(0.6))
            }
            
            Spacer()
        }
        .puliCardStyle()
    }
    
    private var achievementsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rozetler ve Başarılar")
                .font(.headline)
                .foregroundColor(.puliCharcoal)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(store.achievements) { achievement in
                    achievementRow(for: achievement)
                }
            }
        }
    }
    
    private func achievementRow(for achievement: PuliAchievement) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? Color.puliPrimary.opacity(0.15) : Color.puliBeige.opacity(0.4))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: achievement.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(achievement.isUnlocked ? .puliPrimary : .puliCharcoal.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(achievement.isUnlocked ? .puliCharcoal : .puliCharcoal.opacity(0.4))
                    
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.puliCharcoal.opacity(0.6))
                }
                
                Spacer()
                
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.puliPrimary)
                        .font(.title3)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.puliCharcoal.opacity(0.3))
                        .font(.subheadline)
                }
            }
            
            if !achievement.isUnlocked {
                progressBar(for: achievement)
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
    
    @ViewBuilder
    private func progressBar(for achievement: PuliAchievement) -> some View {
        let current = currentProgress(for: achievement)
        let total = achievement.requirementCount
        let ratio = total > 0 ? min(Double(current) / Double(total), 1.0) : 0
        
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.puliBeige.opacity(0.5))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(Color.puliPrimary.opacity(0.7))
                        .frame(width: geo.size.width * ratio, height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(min(current, total))/\(total)")
                .font(.caption2.weight(.medium))
                .foregroundColor(.puliCharcoal.opacity(0.5))
        }
    }
    
    private func currentProgress(for achievement: PuliAchievement) -> Int {
        switch achievement.title {
        case "İlk Adım", "Odak Ustası":
            return store.completedTasksCount
        case "Kararlı Kuş":
            return store.streakCount
        case "Zaman Bükücü":
            return 0
        default:
            return 0
        }
    }
    
    // MARK: - İstatistikler
    
    private var statisticsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if store.completionHistory.isEmpty {
                emptyStatisticsState
            } else {
                summaryCards
                weeklyChartSection
                categoryBreakdownSection
                historySection
            }
        }
    }
    
    private var emptyStatisticsState: some View {
        VStack(spacing: 16) {
            PuliMascotView(mood: .focused)
                .frame(height: 90)
            
            VStack(spacing: 6) {
                Text("Henüz İstatistik Yok")
                    .font(.headline)
                    .foregroundColor(.puliCharcoal)
                
                Text("İlk görevini tamamladığında burada haftalık ilerlemeni ve geçmişini görebileceksin.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.puliCharcoal.opacity(0.6))
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var summaryCards: some View {
        HStack(spacing: 12) {
            statCard(title: "Tamamlanan", value: "\(store.completedTasksCount)", icon: "checkmark.seal.fill")
            statCard(title: "Kazanılan Puan", value: "\(totalCoinsEarned)", icon: "leaf.fill")
            statCard(title: "En Uzun Seri", value: "\(store.longestStreak)", icon: "flame.fill")
        }
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.puliPrimary)
            
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.puliCharcoal)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.puliCharcoal.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.puliSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.puliBeige.opacity(0.6), lineWidth: 1)
        )
    }
    
    private var totalCoinsEarned: Int {
        store.completionHistory.reduce(0) { $0 + $1.coinsEarned }
    }
    
    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Son 7 Gün")
                .font(.headline)
                .foregroundColor(.puliCharcoal)
                .padding(.horizontal, 4)
            
            Chart(weeklyData, id: \.day) { item in
                BarMark(
                    x: .value("Gün", dayLabel(for: item.day)),
                    y: .value("Görev", item.count)
                )
                .foregroundStyle(Color.puliPrimary.gradient)
                .cornerRadius(6)
            }
            .frame(height: 160)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.puliBeige.opacity(0.5))
                    AxisValueLabel()
                        .foregroundStyle(Color.puliCharcoal.opacity(0.5))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.puliCharcoal.opacity(0.6))
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
    }
    
    private struct DayCount {
        let day: Date
        let count: Int
    }
    
    private var weeklyData: [DayCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let count = store.completionHistory.filter {
                calendar.isDate($0.date, inSameDayAs: day)
            }.count
            return DayCount(day: day, count: count)
        }
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kategori Dağılımı")
                .font(.headline)
                .foregroundColor(.puliCharcoal)
                .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                ForEach(categoryBreakdown, id: \.category) { item in
                    categoryRow(category: item.category, count: item.count, maxCount: categoryBreakdown.first?.count ?? 1)
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
    }
    
    private var categoryBreakdown: [(category: PuliTaskCategory, count: Int)] {
        let grouped = Dictionary(grouping: store.completionHistory, by: { $0.category })
        return grouped
            .map { (category: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    private func categoryRow(category: PuliTaskCategory, count: Int, maxCount: Int) -> some View {
        let ratio = maxCount > 0 ? Double(count) / Double(maxCount) : 0
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.puliCharcoal)
                
                Spacer()
                
                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.puliCharcoal.opacity(0.6))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.puliBeige.opacity(0.5))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(category.skillColor)
                        .frame(width: geo.size.width * ratio, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Geçmiş")
                .font(.headline)
                .foregroundColor(.puliCharcoal)
                .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                ForEach(recentHistory) { record in
                    historyRow(for: record)
                }
            }
        }
    }
    
    private var recentHistory: [TaskCompletionRecord] {
        store.completionHistory
            .sorted { $0.date > $1.date }
            .prefix(20)
            .map { $0 }
    }
    
    private func historyRow(for record: TaskCompletionRecord) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(record.category.skillColor.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(record.category.rawValue.prefix(1)))
                        .font(.caption.weight(.bold))
                        .foregroundColor(record.category.skillColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.taskTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.puliCharcoal)
                
                Text(relativeDate(record.date))
                    .font(.caption2)
                    .foregroundColor(.puliCharcoal.opacity(0.5))
            }
            
            Spacer()
            
            Text("+\(record.coinsEarned)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.puliPrimary)
        }
        .padding(12)
        .background(Color.puliSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.puliBeige.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let store = AppStore()
    store.completeTask(PuliTask.allTasks[3])
    store.completeTask(PuliTask.allTasks[1])
    store.completeTask(PuliTask.allTasks[5])
    
    return AchievementsView()
        .environment(store)
}
