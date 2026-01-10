//
//  SubscriptionManager.swift
//  VaccineCalendar
//

import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    // MARK: - Public state

    @Published private(set) var products: [Product] = []
    @Published private(set) var hasPremiumAccess: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastErrorMessage: String?

    // MARK: - Constants

    /// Product IDs must match App Store Connect.
    /// Configure **1 week free trial** as an introductory offer for the yearly subscription in App Store Connect.
    enum ProductID {
        static let monthly = "com.vaccinecalendar.subscription.monthly"
        static let yearly = "com.vaccinecalendar.subscription.yearly"
        static let all: [String] = [monthly, yearly]
    }

    private var updatesTask: Task<Void, Never>?

    // MARK: - Init / deinit

    init() {
        updatesTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }

        Task { [weak self] in
            await self?.configure()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Public API

    func configure() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: ProductID.all)
            products = storeProducts.sorted(by: { $0.displayName < $1.displayName })
        } catch {
            lastErrorMessage = error.localizedDescription
            products = []
        }
    }

    func purchase(product: Product) async {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try requireVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Internals

    func refreshEntitlements() async {
        var isActive = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? requireVerified(result) else { continue }
            if ProductID.all.contains(transaction.productID) {
                isActive = true
                break
            }
        }
        setPremiumAccess(isActive)
    }

    private func listenForTransactionUpdates() async {
        for await update in Transaction.updates {
            guard let transaction = try? requireVerified(update) else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    private func setPremiumAccess(_ newValue: Bool) {
        hasPremiumAccess = newValue
    }

    private func requireVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
}

