//
//  AnimatedHeaderView.swift
//  TimeProgressTracker
//
//  Animated Header with Clouds, Sun, and Birds
//

import SwiftUI
import WebKit

struct AnimatedHeaderView: View {
    @State private var clouds: [CloudData] = []
    @State private var sunRotation: Double = 0
    @State private var birdGroups: [BirdGroupData] = []
    
    private let headerHeight: CGFloat = 200
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            Color.white
                .frame(height: headerHeight)
                .ignoresSafeArea(edges: .top)
            
            // Sun - centered, behind clouds, rotating slowly
            if let sunURL = Bundle.main.url(forResource: "sun", withExtension: "svg") {
                SVGImageView(url: sunURL)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(sunRotation))
                    .position(x: screenWidth / 2, y: headerHeight / 2)
                    .zIndex(0)
                    .onAppear {
                        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                            sunRotation = 360
                        }
                    }
            }
            
            // Clouds - in front of sun
            ForEach(clouds) { cloud in
                CloudView(cloud: cloud)
                    .zIndex(1)
            }
            
            // Birds - random appearances
            ForEach(birdGroups) { group in
                BirdGroupView(group: group)
                    .zIndex(2)
            }
        }
        .frame(height: headerHeight)
        .onAppear {
            initializeClouds()
            startBirdAnimations()
        }
    }
    
    private func initializeClouds() {
        var newClouds: [CloudData] = []
        let cloudNames = ["cloud-1", "cloud-2", "cloud-3"]
        
        // Create 6 clouds with random starting positions
        for i in 0..<6 {
            let cloudName = cloudNames[i % cloudNames.count]
            let sizeMultiplier = 0.7 + Double.random(in: 0...0.6) // 0.7x to 1.3x
            let baseWidth: CGFloat = 120
            let baseHeight: CGFloat = 60
            let width = baseWidth * sizeMultiplier
            let height = baseHeight * sizeMultiplier
            
            // Even Y distribution
            let top = (CGFloat(i) / 5.0) * (headerHeight - height - 20) + 10
            
            // Random starting X position (not always from edges)
            let startX = Double.random(in: -width...screenWidth + width)
            let direction: CloudDirection = i % 3 == 0 ? .rightToLeft : .leftToRight
            let duration = 50.0 + Double.random(in: -10...10) // Slower, 50+ seconds
            
            let cloud = CloudData(
                id: UUID(),
                name: cloudName,
                width: width,
                height: height,
                top: top,
                startX: startX,
                direction: direction,
                duration: duration,
                opacity: 0.65 + Double.random(in: 0...0.25)
            )
            newClouds.append(cloud)
        }
        
        clouds = newClouds
    }
    
    private func startBirdAnimations() {
        // Create bird groups with random timing
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 1...3), repeats: true) { _ in
            if birdGroups.count < 3 {
                let group = BirdGroupData(
                    id: UUID(),
                    count: Int.random(in: 2...10),
                    startX: -100,
                    startY: Double.random(in: 20...150)
                )
                birdGroups.append(group)
                
                // Remove after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                    birdGroups.removeAll { $0.id == group.id }
                }
            }
        }
    }
}

struct CloudData: Identifiable {
    let id: UUID
    let name: String
    let width: CGFloat
    let height: CGFloat
    let top: CGFloat
    let startX: CGFloat
    let direction: CloudDirection
    let duration: Double
    let opacity: Double
}

enum CloudDirection {
    case leftToRight
    case rightToLeft
}

struct CloudView: View {
    let cloud: CloudData
    @State private var offsetX: CGFloat = 0
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        if let cloudURL = Bundle.main.url(forResource: cloud.name, withExtension: "svg") {
            SVGImageView(url: cloudURL)
                .frame(width: cloud.width, height: cloud.height)
                .opacity(cloud.opacity)
                .offset(x: offsetX)
                .position(x: cloud.startX + offsetX, y: cloud.top + cloud.height / 2)
                .onAppear {
                    animateCloud()
                }
        }
    }
    
    private func animateCloud() {
        let endX = cloud.direction == .leftToRight
            ? screenWidth + cloud.width + 50
            : -cloud.width - 50
        
        withAnimation(.linear(duration: cloud.duration).repeatForever(autoreverses: false)) {
            offsetX = endX - cloud.startX
        }
        
        // Reset and loop
        Timer.scheduledTimer(withTimeInterval: cloud.duration, repeats: true) { _ in
            offsetX = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateCloud()
            }
        }
    }
}

struct BirdGroupData: Identifiable {
    let id: UUID
    let count: Int
    let startX: Double
    let startY: Double
}

struct BirdGroupView: View {
    let group: BirdGroupData
    @State private var offsetX: Double = 0
    @State private var offsetY: Double = 0
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<group.count, id: \.self) { _ in
                Text("🐦")
                    .font(.system(size: 4))
                    .offset(x: offsetX, y: offsetY + Double.random(in: -5...5))
            }
        }
        .position(x: group.startX + offsetX, y: group.startY + offsetY)
        .onAppear {
            let duration = Double.random(in: 15...25)
            let endX = screenWidth + 200
            let endY = group.startY + Double.random(in: -30...30)
            
            withAnimation(.linear(duration: duration)) {
                offsetX = endX - group.startX
                offsetY = endY - group.startY
            }
        }
    }
}

struct SVGImageView: View {
    let url: URL
    @State private var svgString: String = ""
    
    var body: some View {
        if !svgString.isEmpty {
            SVGView(svgString: svgString)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Color.clear
                .onAppear {
                    if let data = try? Data(contentsOf: url),
                       let string = String(data: data, encoding: .utf8) {
                        svgString = string
                    }
                }
        }
    }
}

struct SVGView: UIViewRepresentable {
    let svgString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; margin: 0; padding: 0; background: transparent; overflow: hidden; }
                svg { width: 100%; height: 100%; display: block; }
            </style>
        </head>
        <body>
            \(svgString)
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

