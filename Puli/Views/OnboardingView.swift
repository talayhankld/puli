import SwiftUI

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @Binding var hasCompletedOnboarding: Bool
    
    // Ekranda gösterilecek tüm seçenekler
    let availableInterests = [
        "Ders", "Sağlık", "Spor", "Ev İşleri",
        "Yoga", "Yazılım", "Akademik", "Kardiyo",
        "Düzen", "Hızlı", "Açık Hava"
    ]
    
    @State private var selectedInterests: Set<String> = []
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            Color.puliBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                
                // Başlık Kısmı
                VStack(alignment: .leading, spacing: 8) {
                    PuliMascotView(mood: .celebrating)
                        .scaleEffect(0.6)
                        .frame(width: 60, height: 60)
                        .padding(.bottom, 8)
                    
                    Text("Neler yapmaktan\nhoşlanırsın?")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.puliCharcoal)
                    
                    Text("Sana özel görevler önerebilmemiz için en az 2 alan seç.")
                        .font(.subheadline)
                        .foregroundColor(.puliCharcoal.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                
                // Seçim Baloncukları (Chips)
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(availableInterests, id: \.self) { interest in
                            interestChip(for: interest)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                // Devam Butonu
                Button(action: {
                    store.saveInterests(selectedInterests)
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }) {
                    Text("Ana Ekrana Geç")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedInterests.count >= 2 ? Color.puliPrimary : Color.puliBeige)
                        .cornerRadius(16)
                }
                .disabled(selectedInterests.count < 2)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func interestChip(for interest: String) -> some View {
        let isSelected = selectedInterests.contains(interest)
        
        return Text(interest)
            .font(.subheadline.weight(isSelected ? .bold : .medium))
            .foregroundColor(isSelected ? .white : .puliCharcoal.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.puliPrimary : Color.puliSurface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.puliBeige, lineWidth: 1)
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    if isSelected {
                        selectedInterests.remove(interest)
                    } else {
                        selectedInterests.insert(interest)
                    }
                }
            }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(AppStore())
}
