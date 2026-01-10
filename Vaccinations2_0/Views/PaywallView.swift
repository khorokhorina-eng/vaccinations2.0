//
//  PaywallView.swift
//  VaccineCalendar
//

import SwiftUI
import StoreKit
import Foundation

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.openURL) private var openURL
    @State private var selectedProductID: String = SubscriptionManager.ProductID.yearly

    @State private var showErrorAlert: Bool = false

    private let privacyPolicyExternalURL = URL(string: "https://raw.githubusercontent.com/khorokhorina-eng/vaccinations2.0/main/Vaccinations2_0/Resources/Legal/privacy-policy.md")!
    private let appleEULAURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unlock Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("After registration, choose a plan to continue.")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Plans")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ForEach(displayProducts, id: \.id) { product in
                            PlanRow(
                                title: planTitle(for: product),
                                subtitle: planSubtitle(for: product),
                                price: product.displayPrice,
                                isSelected: selectedProductID == product.id
                            ) {
                                selectedProductID = product.id
                            }
                        }

                        if subscriptionManager.products.isEmpty && !subscriptionManager.isLoading {
                            Text("Plans are temporarily unavailable. You can still restore purchases.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }

                    VStack(spacing: 12) {
                        Button(action: {
                            Task { await purchaseSelected() }
                        }) {
                            HStack {
                                Text(primaryButtonTitle)
                                Spacer()
                                if subscriptionManager.isLoading {
                                    ProgressView()
                                } else {
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(subscriptionManager.isLoading ? Color.gray : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(subscriptionManager.isLoading || selectedProduct == nil)

                        Button(action: {
                            Task { await subscriptionManager.restorePurchases() }
                        }) {
                            Text("Restore purchases")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(subscriptionManager.isLoading)
                    }
                    .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(subscriptionDisclosure)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 14) {
                            Button("Privacy Policy") { openURL(privacyPolicyExternalURL) }
                                .buttonStyle(.plain)
                            Button("Terms of Use (EULA)") { openURL(appleEULAURL) }
                                .buttonStyle(.plain)
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationBarHidden(true)
            .onAppear {
                if subscriptionManager.products.isEmpty {
                    Task { await subscriptionManager.loadProducts() }
                }
            }
            .onChange(of: subscriptionManager.products) { newProducts in
                if !newProducts.isEmpty, selectedProduct == nil {
                    selectedProductID = newProducts.first?.id ?? selectedProductID
                }
            }
            .onChange(of: subscriptionManager.lastErrorMessage) { newValue in
                if newValue != nil {
                    showErrorAlert = true
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscriptionManager.lastErrorMessage ?? "Unknown error")
            }
        }
        // iPad: prevent split-view with empty detail column.
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var displayProducts: [Product] {
        let dict = Dictionary(uniqueKeysWithValues: subscriptionManager.products.map { ($0.id, $0) })
        return [SubscriptionManager.ProductID.yearly, SubscriptionManager.ProductID.monthly]
            .compactMap { dict[$0] }
    }

    private var selectedProduct: Product? {
        subscriptionManager.products.first(where: { $0.id == selectedProductID })
    }

    private var primaryButtonTitle: String {
        return "Continue"
    }
    
    private var subscriptionDisclosure: String {
        guard let product = selectedProduct else {
            return "Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period."
        }
        
        let name = product.displayName
        let price = product.displayPrice
        
        if let period = product.subscription?.subscriptionPeriod {
            return "\(name) — \(price) per \(subscriptionPeriodText(period)). Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period."
        }
        
        return "\(name) — \(price). Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period."
    }

    private func planTitle(for product: Product) -> String {
        switch product.id {
        case SubscriptionManager.ProductID.monthly:
            return "Monthly"
        case SubscriptionManager.ProductID.yearly:
            return "Yearly"
        default:
            return product.displayName
        }
    }

    private func planSubtitle(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        return "Billed every \(subscriptionPeriodText(period))"
    }
    
    private func subscriptionPeriodText(_ period: Product.SubscriptionPeriod) -> String {
        let unitText: String
        switch period.unit {
        case .day:
            unitText = period.value == 1 ? "day" : "days"
        case .week:
            unitText = period.value == 1 ? "week" : "weeks"
        case .month:
            unitText = period.value == 1 ? "month" : "months"
        case .year:
            unitText = period.value == 1 ? "year" : "years"
        @unknown default:
            unitText = "period"
        }
        return "\(period.value) \(unitText)"
    }

    private func purchaseSelected() async {
        guard let product = selectedProduct else { return }
        await subscriptionManager.purchase(product: product)
    }
}

private struct PlanRow: View {
    let title: String
    let subtitle: String
    let price: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(price)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

