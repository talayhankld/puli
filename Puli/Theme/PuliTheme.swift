import SwiftUI

// MARK: - Color Palette (Dinamik Dark Mode Destekli)
extension Color {
    // A helper initializer to use Hex codes directly
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Core Brand Colors (Karanlık ve Aydınlık Mod Otomatik Geçişli)
    static let puliBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: 0x121212) // Koyu mod için derin siyah/gri arkaplan
            : UIColor(hex: 0xFDF9F1) // Aydınlık mod için krem tonu
    })
    
    static let puliPrimary = Color(hex: "6B8F6B") // Adaçayı Yeşili
    
    static let puliCharcoal = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: 0xF0F0F0) // Koyu modda açık gri/beyaz yazı rengi
            : UIColor(hex: 0x2D2D2D) // Aydınlık modda kömür siyahı yazı rengi
    })
    
    static let puliAccentYellow = Color(hex: "F7B74D") // Sıcak Sarı
    
    static let puliBeige = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: 0x2C2C2E) // Koyu mod için sınır/çizgi beji
            : UIColor(hex: 0xEADFCC) // Aydınlık mod için açık bej
    })
    
    // UI Specific Colors (Kartlar için dinamik yüzey rengi)
    static let puliSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: 0x1E1E20) // Koyu mod kart arkaplanı (Hafif koyu gri)
            : UIColor.white           // Aydınlık mod kart arkaplanı (Saf beyaz)
    })
    
    // 👇 YENİ: Temaya göre DÖNMEYEN, her iki modda da sabit koyu kalan renk.
    // "Her zaman koyu chip/buton zemini" ya da "her zaman koyu metin" istediğin
    // yerlerde puliCharcoal yerine bunu kullan — puliCharcoal koyu modda
    // açık renge dönüyor, bu ise sabit kalıyor.
    static let puliInkFixed = Color(hex: "2D2D2D")
}

// MARK: - View Modifiers
struct PuliCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color.puliSurface)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.puliBeige.opacity(colorScheme == .dark ? 0.3 : 0.6), lineWidth: 1)
            )
            .shadow(color: Color.puliCharcoal.opacity(colorScheme == .dark ? 0.15 : 0.04), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func puliCardStyle() -> some View {
        self.modifier(PuliCard())
    }
}

// MARK: - Mascot Components
enum PuliMood {
    case calm
    case celebrating
    case focused
}

struct PuliMascotView: View {
    var mood: PuliMood
    
    private var imageName: String {
        switch mood {
        case .calm:
            return "mascot_standing"
        case .focused:
            return "mascot_reading"
        case .celebrating:
            return "mascot_walking"
        }
    }
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .shadow(color: Color.puliPrimary.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Previews
#Preview {
    ZStack {
        Color.puliBackground.ignoresSafeArea()
        
        VStack(spacing: 32) {
            HStack(spacing: 20) {
                PuliMascotView(mood: .calm)
                    .frame(width: 80, height: 80)
                PuliMascotView(mood: .focused)
                    .frame(width: 80, height: 80)
                PuliMascotView(mood: .celebrating)
                    .frame(width: 80, height: 80)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Önce sen. Sonra ekran.")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.puliCharcoal)
                
                Text("Gerçek hayatta iyi alışkanlıklar, daha güzel bir dijital yaşam.")
                    .font(.subheadline)
                    .foregroundColor(.puliCharcoal.opacity(0.7))
            }
            .puliCardStyle()
            .padding(.horizontal)
        }
    }
}

// UIColor Hex Helper for Dynamic Colors
private extension UIColor {
    convenience init(hex: UInt64, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
