import SwiftUI

struct StoreView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStore.self) private var store
    
    let storeItems = [
        (minutes: 15, cost: 50),
        (minutes: 30, cost: 90),
        (minutes: 60, cost: 160) // Toplu alımlarda küçük bir indirim mantığı
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.puliBackground.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Puan Göstergesi
                    VStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.puliPrimary)
                        
                        Text("\(store.puliCoins)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.puliCharcoal)
                        
                        Text("Mevcut Puli Puanı")
                            .font(.subheadline)
                            .foregroundColor(.puliCharcoal.opacity(0.6))
                    }
                    .padding(.top, 40)
                    
                    // Satın Alma Seçenekleri
                    VStack(spacing: 16) {
                        ForEach(storeItems, id: \.minutes) { item in
                            StoreItemCard(minutes: item.minutes, cost: item.cost)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Ödül Mağazası")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(.puliCharcoal)
                }
            }
        }
    }
}

struct StoreItemCard: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let minutes: Int
    let cost: Int
    
    var canAfford: Bool {
        store.puliCoins >= cost
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(minutes) Dk Ekran Süresi")
                    .font(.headline)
                    .foregroundColor(.puliCharcoal)
                
                Text("Anında kalkanı açar")
                    .font(.caption)
                    .foregroundColor(.puliCharcoal.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: {
                if store.purchaseScreenTime(minutes: minutes, cost: cost) {
                    dismiss() // Satın alım başarılıysa mağazayı kapat ve Dashboard'a dön
                }
            }) {
                HStack(spacing: 4) {
                    Text("\(cost)")
                        .font(.headline.weight(.bold))
                    Image(systemName: "leaf.fill")
                        .font(.caption)
                }
                .foregroundColor(canAfford ? .white : .puliCharcoal.opacity(0.4))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(canAfford ? Color.puliPrimary : Color.puliBeige.opacity(0.5))
                .cornerRadius(12)
            }
            .disabled(!canAfford)
        }
        .padding(16)
        .background(Color.puliSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.puliBeige.opacity(0.8), lineWidth: 1)
        )
    }
}
