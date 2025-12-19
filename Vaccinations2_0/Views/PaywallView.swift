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
    
    // Display pricing (business model). Purchases still use StoreKit products.
    private let monthlyPriceUSD: Decimal = 4.99
    private let yearlyPriceUSD: Decimal = 19.99

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
                            PaywallPlanCard(
                                badgeText: planBadgeText(forProductId: SubscriptionManager.ProductID.yearly),
                                title: "Yearly Plan",
                                durationAndTotal: durationAndTotal(forProductId: SubscriptionManager.ProductID.yearly),
                                perMonth: perMonthLabel(forProductId: SubscriptionManager.ProductID.yearly),
                                isSelected: selectedProductID == SubscriptionManager.ProductID.yearly
                            ) {
                                selectedProductID = SubscriptionManager.ProductID.yearly
                            }
                            
                            PaywallPlanCard(
                                badgeText: planBadgeText(forProductId: SubscriptionManager.ProductID.monthly),
                                title: "Monthly Plan",
                                durationAndTotal: durationAndTotal(forProductId: SubscriptionManager.ProductID.monthly),
                                perMonth: perMonthLabel(forProductId: SubscriptionManager.ProductID.monthly),
                                isSelected: selectedProductID == SubscriptionManager.ProductID.monthly
                            ) {
                                selectedProductID = SubscriptionManager.ProductID.monthly
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
        // Trial applies to both plans (configured in App Store Connect).
        if isFreeTrialEnabled && (selectedProductID == SubscriptionManager.ProductID.yearly || selectedProductID == SubscriptionManager.ProductID.monthly) {
            return "Start 7-Day Free Trial"
        }
        return "Continue"
    }

    private func planBadgeText(forProductId id: String) -> String? {
        switch id {
        case SubscriptionManager.ProductID.yearly:
            return isFreeTrialEnabled ? "7-DAY FREE TRIAL" : "BEST VALUE"
        case SubscriptionManager.ProductID.monthly:
            return isFreeTrialEnabled ? "7-DAY FREE TRIAL" : "MONTHLY PLAN"
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
    
    private func durationAndTotal(forProductId id: String) -> String {
        // Match the reference shape: "12 mo • TRY 439.99"
        let total = formattedUSD(totalPriceUSD(forProductId: id))
        if id == SubscriptionManager.ProductID.yearly {
            return "12 mo • \(total)"
        }
        if id == SubscriptionManager.ProductID.monthly {
            return "1 mo • \(total)"
        }
        return total
    }
    
    private func perMonthLabel(forProductId id: String) -> String {
        // Match the reference shape: "TRY 36.67 / mo"
        if id == SubscriptionManager.ProductID.monthly {
            return "\(formattedUSD(monthlyPriceUSD)) / mo"
        }
        if id == SubscriptionManager.ProductID.yearly {
            return "\(formattedUSD(yearlyPriceUSD / Decimal(12))) / mo"
        }
        return "—"
    }
    
    private func totalPriceUSD(forProductId id: String) -> Decimal {
        switch id {
        case SubscriptionManager.ProductID.monthly:
            return monthlyPriceUSD
        case SubscriptionManager.ProductID.yearly:
            return yearlyPriceUSD
        default:
            return 0
        }
    }
    
    private func formattedUSD(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$\(amount)"
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
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(2)
                        
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

