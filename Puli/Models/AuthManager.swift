import Foundation
import Observation
import AuthenticationServices

@Observable
final class AuthManager {
    var isAuthenticated: Bool = false
    var userId: String? = nil
    
    // Oturum durumunu kontrol et (Örn: UserDefaults veya Keychain'den)
    func checkSession() {
        if let savedUserId = UserDefaults.standard.string(forKey: "puli_user_id") {
            self.userId = savedUserId
            self.isAuthenticated = true
        }
    }
    
    // Başarılı giriş sonrası çağrılacak
    func login(with appleUserId: String) {
        self.userId = appleUserId
        self.isAuthenticated = true
        UserDefaults.standard.set(appleUserId, forKey: "puli_user_id")
        
        // Gelecekte: Burada token'ı .NET Core backend'ine gönderip JWT alacaksın.
    }
    
    func logout() {
        self.userId = nil
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "puli_user_id")
    }
}
