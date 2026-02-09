import Foundation
import WidgetKit
import StoreKit
import SwiftUI

@MainActor
class PurchaseManager: ObservableObject {
    @Published var isPro: Bool = false
    @Published var products: [Product] = []
    @Published var purchaseInFlight: Bool = false

    private let productID = "com.prabhakaran.timeprogresstracker.pro.lifetime"
    private let entitlementKey = "isPro"
    private let appGroup = "group.com.prabhakaran.timeprogresstracker"

    init() {
        Task {
            await loadProducts()
            await refreshEntitlement()
        }
    }

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [productID])
            products = storeProducts
        } catch {
            print("⚠️ [PurchaseManager] Failed to load products: \(error)")
        }
    }

    func purchase() async {
        guard let product = products.first(where: { $0.id == productID }) else { return }
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(.verified(let transaction)):
                await transaction.finish()
                setPro(true)
            case .success(.unverified(_, _)):
                print("⚠️ [PurchaseManager] Unverified transaction")
            case .userCancelled:
                break
            default:
                break
            }
        } catch {
            print("⚠️ [PurchaseManager] Purchase failed: \(error)")
        }
    }

    func restore() async {
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == productID {
                setPro(true)
                return
            }
        }
        setPro(false)
    }

    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: entitlementKey)
        if let shared = UserDefaults(suiteName: appGroup) {
            shared.set(value, forKey: entitlementKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func refreshEntitlement() async {
        let local = UserDefaults.standard.bool(forKey: entitlementKey)
        if local {
            isPro = true
            return
        }
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == productID {
                setPro(true)
                return
            }
        }
        setPro(false)
    }
}
