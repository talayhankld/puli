import SwiftUI
import FamilyControls

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(RealShieldService.self) private var shieldService
    @Environment(\.dismiss) private var dismiss
    
    // Gerçek AppStorage bağlantıları
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    @State private var isPickerPresented = false
    @State private var showLogoutAlert = false
    @State private var showSuccessToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.puliBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // 1. PROFİL KARTI
                        profileCard
                        
                        // 2. GÖRÜNÜM (Dark Mode Entegrasyonu)
                        appearanceSection
                        
                        // 3. EKRAN SÜRESİ (FamilyControls Picker)
                        screenTimeSection
                        
                        // 4. BİLDİRİMLER
                        notificationsSection
                        
                        // 5. HESAP VE OTURUM KAPATMA
                        accountAndAboutSection
                        
                        Text("Puli v1.0.0 • Odakla Kal")
                            .font(.caption2)
                            .foregroundColor(.puliCharcoal.opacity(0.4))
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // İşlem Başarılı Toast Bildirimi
                if showSuccessToast {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.puliInkFixed) // 👈 DEĞİŞTİ: dark modda beyaza dönmesin diye
                            .cornerRadius(16)
                            .shadow(radius: 8)
                            .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(200)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Tamam")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.puliPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.puliPrimary.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
            .alert("Oturumu Kapat", isPresented: $showLogoutAlert) {
                Button("İptal", role: .cancel) { }
                Button("Çıkış Yap", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Hesabından çıkış yapmak istediğine emin misin? Biriken puanların ve serilerin güvende kalacak.")
            }
        }
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
    }
    
    // MARK: - Subviews & Actions
    
    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.puliAccentYellow.opacity(0.2))
                    .frame(width: 64, height: 64)
                
                PuliMascotView(mood: .celebrating)
                    .scaleEffect(0.7)
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Talayhan Kalender")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.puliCharcoal)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.puliAccentYellow)
                        .font(.caption)
                    Text("\(store.streakCount) Günlük Seri Aktif")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.puliPrimary)
                }
            }
            
            Spacer()
        }
        .padding(18)
        .background(Color.puliSurface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.puliBeige.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: Color.puliCharcoal.opacity(0.03), radius: 8, y: 4)
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GÖRÜNÜM")
                .font(.caption.weight(.bold))
                .foregroundColor(.puliCharcoal.opacity(0.5))
                .padding(.horizontal, 4)
            
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.puliPrimary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: isDarkModeEnabled ? "moon.fill" : "sun.max.fill")
                        .foregroundColor(.puliPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Karanlık Mod")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.puliCharcoal)
                    Text(isDarkModeEnabled ? "Koyu tema aktif" : "Açık tema aktif")
                        .font(.caption2)
                        .foregroundColor(.puliCharcoal.opacity(0.6))
                }
                
                Spacer()
                
                Toggle("", isOn: $isDarkModeEnabled)
                    .labelsHidden()
                    .tint(.puliPrimary)
                    .onChange(of: isDarkModeEnabled) { _, newValue in
                        triggerToast(newValue ? "Karanlık mod açıldı 🌙" : "Açık moda geçildi ☀️")
                    }
            }
            .padding(16)
            .background(Color.puliSurface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.puliBeige.opacity(0.8), lineWidth: 1)
            )
        }
    }
    
    private var screenTimeSection: some View {
        let service = shieldService
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("EKRAN SÜRESİ VE KABUK")
                .font(.caption.weight(.bold))
                .foregroundColor(.puliCharcoal.opacity(0.5))
                .padding(.horizontal, 4)
            
            Button(action: { isPickerPresented = true }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.puliAccentYellow.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "shield.fill")
                            .foregroundColor(.puliAccentYellow)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kalkan Uygulamalarını Düzenle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.puliCharcoal)
                        Text("Kilitlenecek uygulamaları seç")
                            .font(.caption2)
                            .foregroundColor(.puliCharcoal.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.puliCharcoal.opacity(0.4))
                }
                .padding(16)
                .background(Color.puliSurface)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.puliBeige.opacity(0.8), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: Bindable(service).appSelection
            )
        }
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BİLDİRİMLER")
                .font(.caption.weight(.bold))
                .foregroundColor(.puliCharcoal.opacity(0.5))
                .padding(.horizontal, 4)
            
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.puliPrimary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: notificationsEnabled ? "bell.badge.fill" : "bell.slash.fill")
                        .foregroundColor(.puliPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Seri ve Görev Hatırlatıcıları")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.puliCharcoal)
                    Text(notificationsEnabled ? "Hatırlatıcılar açık" : "Bildirimler sessizde")
                        .font(.caption2)
                        .foregroundColor(.puliCharcoal.opacity(0.6))
                }
                
                Spacer()
                
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(.puliPrimary)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        triggerToast(newValue ? "Bildirimler etkinleştirildi 🔔" : "Bildirimler kapatıldı 🔕")
                    }
            }
            .padding(16)
            .background(Color.puliSurface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.puliBeige.opacity(0.8), lineWidth: 1)
            )
        }
    }
    
    private var accountAndAboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HESAP & OTURUM")
                .font(.caption.weight(.bold))
                .foregroundColor(.puliCharcoal.opacity(0.5))
                .padding(.horizontal, 4)
            
            Button(action: { showLogoutAlert = true }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Oturumu Kapat")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.red)
                        Text("Hesap oturumunu sonlandır")
                            .font(.caption2)
                            .foregroundColor(.red.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.puliSurface)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring()) {
            showSuccessToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showSuccessToast = false
            }
        }
    }
    
    private func performLogout() {
        triggerToast("Oturum kapatıldı 👋")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            hasCompletedOnboarding = false
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppStore())
        .environment(RealShieldService())
}
