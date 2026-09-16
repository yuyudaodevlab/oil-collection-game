import SwiftUI
import AppKit

@main
struct RenderPreview {
    @MainActor static func main() {
        let root = CommandLine.arguments[1]
        func render<V: View>(_ view: V, size: CGSize, path: String) {
            let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
            renderer.scale = 1
            guard let image = renderer.cgImage else { fatalError("No rendered image") }
            let bitmap = NSBitmapImageRep(cgImage: image)
            try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: root + "/" + path))
        }
        render(ContentView(), size: .init(width: 1100, height: 780), path: "Preview/mac.png")
        render(ContentView(), size: .init(width: 393, height: 852), path: "Preview/phone-layout.png")
        let icon = ZStack {
            Color.garden
            RadialGradient(colors: [Color(hex: 0x4B6550), Color.garden], center: .topLeading, startRadius: 0, endRadius: 1100)
            RamenArt(broth: .shoyu).padding(40)
            Canvas { c, _ in
                for (x,y,r) in [(470.0,450.0,74.0),(569.0,521.0,51.0),(442.0,559.0,36.0)] {
                    let p = Path(ellipseIn: CGRect(x:x-r,y:y-r,width:r*2,height:r*2))
                    c.fill(p, with: .color(Color.gold.opacity(0.65)))
                    c.stroke(p, with: .color(Color(hex: 0xFFE9A4)), lineWidth: 5)
                    var shine = Path(); shine.addArc(center: .init(x:x,y:y),radius:r*0.76,startAngle:.degrees(205),endAngle:.degrees(280),clockwise:false)
                    c.stroke(shine, with: .color(.white.opacity(0.9)), style: .init(lineWidth:5,lineCap:.round))
                }
                for offset in [0.0, 43.0] {
                    var stick = Path(); stick.move(to: .init(x:536+offset,y:544-offset)); stick.addLine(to: .init(x:882+offset,y:910-offset))
                    c.stroke(stick, with: .color(Color(hex: 0xE0B67E)), style: .init(lineWidth:15,lineCap:.round))
                }
            }
        }
        render(icon, size: .init(width: 1024, height: 1024), path: "Resources/Assets.xcassets/AppIcon.appiconset/Icon.png")
    }
}
