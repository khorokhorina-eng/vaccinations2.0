//
//  PaywallView.swift
//  VaccineCalendar
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedProductID: String = SubscriptionManager.ProductID.yearly
    @State private var isFreeTrialEnabled: Bool = true

    @State private var promoCode: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var didTapPrimary: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    header
                        .padding(.top, 10)
                        .padding(.horizontal)
                    
                    VStack(spacing: 14) {
                        Toggle(isOn: $isFreeTrialEnabled) {
                            Text("Free trial enabled")
                                .font(.headline)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.purple.opacity(0.08))
                        )
                        .tint(.purple)
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(displayProducts, id: \.id) { product in
                                PaywallPlanCard(
                                    badgeText: planBadgeText(for: product),
                                    title: planTitle(for: product),
                                    durationAndTotal: durationAndTotal(for: product),
                                    perMonth: perMonthLabel(for: product),
                                    isSelected: selectedProductID == product.id
                                ) {
                                    selectedProductID = product.id
                                }
                            }
                            
                            if subscriptionManager.products.isEmpty && !subscriptionManager.isLoading {
                                Text("Plans are temporarily unavailable. You can still restore purchases or use a promo code.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Promo code")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 10) {
                            TextField("Enter promo code", text: $promoCode)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Apply") {
                                subscriptionManager.applyPromoCode(promoCode)
                                if subscriptionManager.hasPremiumAccess {
                                    promoCode = ""
                                } else if subscriptionManager.lastErrorMessage != nil {
                                    showErrorAlert = true
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            didTapPrimary = true
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
                            .background(subscriptionManager.isLoading ? Color.gray : Color(red: 0.96, green: 0.29, blue: 0.41))
                            .cornerRadius(16)
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
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // If user taps primary while products are not loaded, show a clear error.
                    if didTapPrimary && selectedProduct == nil {
                        Text("Unable to start purchase. Please check your connection or try Restore purchases.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                    
                    Spacer(minLength: 12)
                }
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
        if isFreeTrialEnabled {
            return "Start 14-Day Free Trial"
        }
        return "Continue"
    }

    private func planTitle(for product: Product) -> String {
        switch product.id {
        case SubscriptionManager.ProductID.monthly:
            return "Monthly Plan"
        case SubscriptionManager.ProductID.yearly:
            return "Yearly Plan"
        default:
            return product.displayName
        }
    }
    
    private func planBadgeText(for product: Product) -> String? {
        switch product.id {
        case SubscriptionManager.ProductID.yearly:
            return isFreeTrialEnabled ? "14-DAY FREE TRIAL" : "BEST VALUE"
        case SubscriptionManager.ProductID.monthly:
            return "MONTHLY PLAN"
        default:
            return nil
        }
    }
    
    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color.black.opacity(0.04))
                        .clipShape(Circle())
                }
                .disabled(true) // Paywall is root; keep visual parity without allowing bypass.
                
                Spacer()
                
                Button(action: {
                    Task { await subscriptionManager.restorePurchases() }
                }) {
                    Text("Restore")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .disabled(subscriptionManager.isLoading)
            }
            
            Text("Choose your plan")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
    }
    
    private func durationAndTotal(for product: Product) -> String {
        // Match the reference shape: "12 mo • TRY 439.99"
        let total = product.displayPrice
        if product.id == SubscriptionManager.ProductID.yearly {
            return "12 mo • \(total)"
        }
        if product.id == SubscriptionManager.ProductID.monthly {
            return "1 mo • \(total)"
        }
        return total
    }
    
    private func perMonthLabel(for product: Product) -> String {
        // Match the reference shape: "TRY 36.67 / mo"
        if product.id == SubscriptionManager.ProductID.monthly {
            return "\(product.displayPrice) / mo"
        }
        if product.id == SubscriptionManager.ProductID.yearly {
            if let monthly = perMonthPriceString(forYearlyProduct: product) {
                return "\(monthly) / mo"
            }
            return "\(product.displayPrice) / yr"
        }
        return product.displayPrice
    }
    
    private func perMonthPriceString(forYearlyProduct product: Product) -> String? {
        // Best-effort monthly price calculation, formatted with the product's currency style.
        let monthly = product.price / Decimal(12)
        return monthly.formatted(product.priceFormatStyle)
    }

    private func purchaseSelected() async {
        guard let product = selectedProduct else { return }
        await subscriptionManager.purchase(product: product)
    }
}

private struct PaywallPlanCard: View {
    let badgeText: String?
    let title: String
    let durationAndTotal: String
    let perMonth: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                if let badgeText = badgeText {
                    Text(badgeText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.96, green: 0.29, blue: 0.41),
                                    Color(red: 0.98, green: 0.42, blue: 0.55)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.85)
                            .lineLimit(1)
                        
                        Text(durationAndTotal)
                            .font(.headline)
                            .foregroundColor(.primary.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(perMonth)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? Color(red: 0.96, green: 0.29, blue: 0.41) : .secondary)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(red: 0.96, green: 0.29, blue: 0.41).opacity(0.12) : Color.gray.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(red: 0.96, green: 0.29, blue: 0.41) : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

