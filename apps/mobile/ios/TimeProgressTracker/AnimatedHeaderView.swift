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
    @State private var sunScale: CGFloat = 0.1 // Start small
    @State private var birdGroups: [BirdGroupData] = []
    @State private var loadedSVGsCount: Int = 0 // Count individual SVG loads, not unique names
    @State private var svgCache: [String: String] = [:] // Cache SVG strings for faster loading
    @State private var sunAnimationStarted = false
    @State private var cloudsAnimationStarted = false
    @State private var birdsAnimationStarted = false
    var onSVGsLoaded: (() -> Void)? = nil
    var startAnimations: Bool = false
    var animationRestartTrigger: Int = 0 // External trigger to restart animations
    var onSunStarted: (() -> Void)? = nil
    var onCloudsStarted: (() -> Void)? = nil
    var onBirdsStarted: (() -> Void)? = nil
    
    private let headerHeight: CGFloat = 200
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            Color.white
                .frame(height: headerHeight)
                .ignoresSafeArea(edges: .top)
            
            // Sun - centered, behind clouds, rotating slowly
            if let sunString = svgCache["sun"] {
                SVGView(svgString: sunString)
                    .frame(width: 80, height: 80)
                    .scaleEffect(sunScale) // Scale animation
                    .rotationEffect(.degrees(sunRotation))
                    .position(x: screenWidth / 2, y: headerHeight / 2)
                    .zIndex(0)
                    .onAppear {
                        print("✅ [AnimatedHeaderView] Sun SVG rendered from cache")
                        loadedSVGsCount += 1
                        checkAllSVGsLoaded()
                    }
                    .onChange(of: startAnimations) { shouldStart in
                        if shouldStart && !sunAnimationStarted {
                            startSunAnimation()
                        }
                    }
                    .onChange(of: animationRestartTrigger) { _ in
                        restartAnimations()
                    }
            } else if let sunURL = Bundle.main.url(forResource: "sun", withExtension: "svg") {
                SVGImageView(url: sunURL, onLoaded: {
                    print("✅ [AnimatedHeaderView] Sun SVG loaded")
                    loadedSVGsCount += 1
                    checkAllSVGsLoaded()
                })
                    .frame(width: 80, height: 80)
                    .scaleEffect(sunScale) // Scale animation
                    .rotationEffect(.degrees(sunRotation))
                    .position(x: screenWidth / 2, y: headerHeight / 2)
                    .zIndex(0)
                    .onChange(of: startAnimations) { shouldStart in
                        if shouldStart && !sunAnimationStarted {
                            startSunAnimation()
                        }
                    }
                    .onChange(of: animationRestartTrigger) { _ in
                        restartAnimations()
                    }
            }
            
            // Clouds - in front of sun
            ForEach(clouds) { cloud in
                CloudView(
                    cloud: cloud,
                    svgCache: svgCache,
                    startAnimation: cloudsAnimationStarted,
                    onSVGLoaded: {
                        print("✅ [AnimatedHeaderView] Cloud SVG loaded: \(cloud.name)")
                        loadedSVGsCount += 1
                        checkAllSVGsLoaded()
                    }
                )
                    .zIndex(1)
            }
            
            // Birds - random appearances
            ForEach(birdGroups) { group in
                BirdGroupView(group: group, startAnimation: birdsAnimationStarted)
                    .zIndex(2)
            }
        }
        .frame(height: headerHeight)
        .onAppear {
            print("✅ [AnimatedHeaderView] onAppear called")
            // Preload all SVGs immediately
            preloadSVGs()
            initializeClouds()
            // Don't start bird animations immediately - wait for startAnimations signal
            print("✅ [AnimatedHeaderView] Initialized \(clouds.count) clouds")
        }
        .onChange(of: startAnimations) { shouldStart in
            if shouldStart && !birdsAnimationStarted {
                startBirdAnimations()
            }
        }
        .onChange(of: animationRestartTrigger) { _ in
            // Restart animations when trigger changes
            restartAnimations()
        }
    }
    
    private func restartAnimations() {
        print("🔄 [AnimatedHeaderView] Restarting animations")
        // Reset animation states
        sunAnimationStarted = false
        cloudsAnimationStarted = false
        birdsAnimationStarted = false
        sunScale = 0.1
        sunRotation = 0
        birdGroups = []
        
        // Reinitialize clouds
        initializeClouds()
        
        // Start animations immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startSunAnimation()
        }
    }
    
    private func startSunAnimation() {
        sunAnimationStarted = true
        print("✅ [AnimatedHeaderView] Starting sun animation (restart)")
        withAnimation(.easeOut(duration: 1.5)) {
            sunScale = 1.0
        }
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            sunRotation = 360
        }
        onSunStarted?()
        
        // Start clouds after sun
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            cloudsAnimationStarted = true
            onCloudsStarted?()
        }
        
        // Start birds after clouds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            birdsAnimationStarted = true
            startBirdAnimations()
            onBirdsStarted?()
        }
    }
    
    private func preloadSVGs() {
        // Preload all SVG files synchronously for faster rendering
        let cloudNames = ["cloud-1", "cloud-2", "cloud-3"]
        var loaded = 0
        let total = 1 + cloudNames.count // sun + 3 cloud types
        
        // Preload sun
        if let sunURL = Bundle.main.url(forResource: "sun", withExtension: "svg"),
           let sunData = try? Data(contentsOf: sunURL),
           let sunString = String(data: sunData, encoding: .utf8) {
            svgCache["sun"] = sunString
            loaded += 1
            print("✅ [AnimatedHeaderView] Preloaded sun SVG")
        }
        
        // Preload clouds
        for cloudName in cloudNames {
            if let cloudURL = Bundle.main.url(forResource: cloudName, withExtension: "svg"),
               let cloudData = try? Data(contentsOf: cloudURL),
               let cloudString = String(data: cloudData, encoding: .utf8) {
                svgCache[cloudName] = cloudString
                loaded += 1
                print("✅ [AnimatedHeaderView] Preloaded \(cloudName) SVG")
            }
        }
        
        print("✅ [AnimatedHeaderView] Preloaded \(loaded)/\(total) SVGs")
    }
    
    private func checkAllSVGsLoaded() {
        // Need: 1 sun + clouds (usually 6) = 7 SVGs
        let expectedCount = 1 + clouds.count
        print("🔍 [AnimatedHeaderView] checkAllSVGsLoaded - loadedSVGsCount: \(loadedSVGsCount), expected: \(expectedCount), clouds: \(clouds.count)")
        if clouds.count > 0 && loadedSVGsCount >= expectedCount {
            print("✅ [AnimatedHeaderView] All SVGs loaded! Calling callback")
            // Ensure we only call once - use a small delay to ensure all SVGs are rendered
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSVGsLoaded?()
            }
        }
    }
    
    private func initializeClouds() {
        var newClouds: [CloudData] = []
        let cloudNames = ["cloud-1", "cloud-2", "cloud-3"]
        
        // Create 7 clouds for better coverage (increased from 5, but less than 12)
        for i in 0..<7 {
            let cloudName = cloudNames[i % cloudNames.count]
            let sizeMultiplier = 0.7 + Double.random(in: 0...0.6) // 0.7x to 1.3x
            let baseWidth: CGFloat = 120
            let baseHeight: CGFloat = 60
            let width = baseWidth * sizeMultiplier
            let height = baseHeight * sizeMultiplier
            
            // Better Y distribution - spread clouds across the full header height with more breathing room
            // Use modulo to create layers, with random offset within each layer
            let layer = i % 4 // 4 layers now for 7 clouds
            let layerHeight = (headerHeight - height - 40) / 4 
            let randomOffset = CGFloat.random(in: 0...20) // Random offset within layer
            let top = 20 + (CGFloat(layer) * layerHeight) + randomOffset
            
            // Determine direction
            let direction: CloudDirection = i % 2 == 0 ? .leftToRight : .rightToLeft
            
            // Start clouds OFF-SCREEN to prevent sudden appearance
            let startX: CGFloat
            if direction == .leftToRight {
                // Start completely off the left edge
                startX = -width - 50
            } else {
                // Start completely off the right edge
                startX = screenWidth + width + 50
            }
            
            let duration = 50.0 + Double.random(in: -10...10) // Slower, 50+ seconds
            
            // Stagger cloud starts - each cloud starts at a different time
            // This spreads them across the screen instead of grouping them
            // Increase spread factor with more clouds
            let delay = Double(i) * (duration / 7.0) + Double.random(in: 0...5)
            
            let cloud = CloudData(
                id: UUID(),
                name: cloudName,
                width: width,
                height: height,
                top: top,
                startX: startX,
                direction: direction,
                duration: duration,
                opacity: 0.65 + Double.random(in: 0...0.25),
                delay: delay,
                restartDelay: Double.random(in: 10...30) // Random restart delay to break patterns
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
    let delay: Double // Delay before starting animation
    let restartDelay: Double // Random delay before restarting animation loop
}

enum CloudDirection {
    case leftToRight
    case rightToLeft
}

struct CloudView: View {
    let cloud: CloudData
    let svgCache: [String: String] // Pass cache from parent
    var startAnimation: Bool = false
    @State private var offsetX: CGFloat = 0
    @State private var hasAnimated = false
    var onSVGLoaded: (() -> Void)? = nil
    
    private let screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        if let cloudString = svgCache[cloud.name] {
            SVGView(svgString: cloudString)
                .frame(width: cloud.width, height: cloud.height)
                .opacity(cloud.opacity)
                .offset(x: offsetX)
                .position(x: cloud.startX + offsetX, y: cloud.top + cloud.height / 2)
                .onAppear {
                    print("✅ [CloudView] Cloud \(cloud.name) rendered from cache")
                    onSVGLoaded?()
                }
                .onChange(of: startAnimation) { shouldStart in
                    if shouldStart && !hasAnimated {
                        hasAnimated = true
                        // Delay animation start to spread clouds across screen
                        DispatchQueue.main.asyncAfter(deadline: .now() + cloud.delay) {
                            animateCloud()
                        }
                    }
                }
        } else if let cloudURL = Bundle.main.url(forResource: cloud.name, withExtension: "svg") {
            SVGImageView(url: cloudURL, onLoaded: onSVGLoaded)
                .frame(width: cloud.width, height: cloud.height)
                .opacity(cloud.opacity)
                .offset(x: offsetX)
                .position(x: cloud.startX + offsetX, y: cloud.top + cloud.height / 2)
                .onChange(of: startAnimation) { shouldStart in
                    if shouldStart && !hasAnimated {
                        hasAnimated = true
                        // Delay animation start to spread clouds across screen
                        DispatchQueue.main.asyncAfter(deadline: .now() + cloud.delay) {
                            animateCloud()
                        }
                    }
                }
        }
    }
    
    private func animateCloud() {
        // Calculate end position based on direction (always off-screen on the opposite side)
        let endX: CGFloat
        if cloud.direction == .leftToRight {
            endX = screenWidth + cloud.width + 50
        } else {
            endX = -cloud.width - 50
        }
        
        // Start from current position (which should be off-screen initially)
        withAnimation(.linear(duration: cloud.duration)) {
            offsetX = endX - cloud.startX
        }
        
        // Reset and loop after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + cloud.duration) {
            // Reset to starting position (off-screen)
            offsetX = 0
            
            // Wait for restart delay before animating again
            // Ensure some randomness in the restart to prevent patterns forming
            let restartWait = cloud.restartDelay + Double.random(in: 0...5)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + restartWait) {
                // Restart animation
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
    var startAnimation: Bool = false
    @State private var offsetX: Double = 0
    @State private var offsetY: Double = 0
    @State private var hasAnimated = false
    
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
        .onChange(of: startAnimation) { shouldStart in
            if shouldStart && !hasAnimated {
                hasAnimated = true
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
}

struct SVGImageView: View {
    let url: URL
    var onLoaded: (() -> Void)? = nil
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
                        // Small delay to ensure SVG is rendered
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onLoaded?()
                        }
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

