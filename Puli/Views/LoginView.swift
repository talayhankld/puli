import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    
    var body: some View {
        ZStack {
            Color.puliBackground.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Maskot ve Marka
                VStack(spacing: 24) {
                    PuliMascotView(mood: .calm)
                        .scaleEffect(1.5)
                        .padding(.bottom, 16)
                    
                    // Daha önce oluşturduğumuz wordmark logon (Veya PuliLogoView)
                    Image("PuliWordmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 56)
                    
                    Text("Önce sen. Sonra ekran.")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.puliCharcoal.opacity(0.8))
                        .tracking(1) // Harf arası boşluk
                }
                
                Spacer()
                
                // Bilgilendirme metni
                VStack(spacing: 12) {
                    Text("Puan kazanmak, ekran süreni yönetmek ve\ngelişimini kaydetmek için giriş yap.")
                        .font(.subheadline)
                        .foregroundColor(.puliCharcoal.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // Native Apple Giriş Butonu
                    SignInWithAppleButton(
                        .continue,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black) // Koyu gri Puli temasına uygun
                    .frame(height: 56)
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 60)
            }
        }
    }
    
    // MARK: - Apple Auth Handler
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                
                let userId = appleIDCredential.user
                // let identityToken = appleIDCredential.identityToken
                // let email = appleIDCredential.email
                // let fullName = appleIDCredential.fullName
                
                print("✅ Başarılı Giriş: \(userId)")
                
                // UI'ı ana ekrana geçirmek için AuthManager'ı tetikliyoruz
                withAnimation {
                    authManager.login(with: userId)
                }
            }
        case .failure(let error):
            print("❌ Giriş başarısız: \(error.localizedDescription)")
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
