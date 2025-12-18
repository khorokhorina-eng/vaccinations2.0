//
//  PaywallView.swift
//  VaccineCalendar
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedProductID: String = SubscriptionManager.ProductID.yearly

    @State private var promoCode: String = ""
    @State private var showErrorAlert: Bool = false

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
                            Text("Plans are temporarily unavailable. You can still restore purchases or use a promo code.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
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

                    Text("Monthly: $5. Yearly: $30. Yearly plan includes a 1-week free trial for new subscribers (configured in App Store Connect).")
                        .font(.footnote)
                        .foregroundColor(.secondary)
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
        if selectedProductID == SubscriptionManager.ProductID.yearly {
            return "Start free trial"
        }
        return "Continue"
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
        switch product.id {
        case SubscriptionManager.ProductID.yearly:
            return "1 week free, then billed yearly"
        case SubscriptionManager.ProductID.monthly:
            return "Billed monthly"
        default:
            return ""
        }
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

