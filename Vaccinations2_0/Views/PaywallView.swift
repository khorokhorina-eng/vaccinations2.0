//
//  PaywallView.swift
//  VaccineCalendar
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedProductID: String = SubscriptionManager.ProductID.yearly
    @State private var showErrorAlert: Bool = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    PaywallContent(
                        maxContentWidth: proxy.size.width >= 700 ? 920 : nil,
                        isWideLayout: proxy.size.width >= 700
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
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

    private var billingCaption: String {
        guard let product = selectedProduct else { return "" }
        if product.id == SubscriptionManager.ProductID.yearly {
            return "Then \(product.displayPrice)/year. Auto-renews until canceled."
        }
        if product.id == SubscriptionManager.ProductID.monthly {
            return "\(product.displayPrice)/month. Auto-renews until canceled."
        }
        return "Auto-renews until canceled."
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
            return "1 week free trial, then billed yearly"
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

    @ViewBuilder
    private func PaywallContent(maxContentWidth: CGFloat?, isWideLayout: Bool) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Unlock Premium")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Choose a plan to continue.")
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)

            if isWideLayout {
                HStack(alignment: .top, spacing: 20) {
                    featuresCard
                        .frame(maxWidth: .infinity, alignment: .leading)

                    plansCard
                        .frame(maxWidth: 420, alignment: .top)
                }
            } else {
                featuresCard
                plansCard
            }

            legalLinksRow
                .padding(.top, 4)
        }
        .frame(maxWidth: maxContentWidth, alignment: .leading)
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What you get")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(title: "Full vaccination schedule", subtitle: "See mandatory and recommended vaccines")
                FeatureRow(title: "Track completion", subtitle: "Mark doses and keep notes")
                FeatureRow(title: "Country schedules", subtitle: "Switch schedule by country")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var plansCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plans")
                .font(.headline)

            ForEach(displayProducts, id: \.id) { product in
                PlanRow(
                    title: planTitle(for: product),
                    subtitle: planSubtitle(for: product),
                    billedPrice: product.displayPrice,
                    billingUnit: billingUnit(for: product),
                    isSelected: selectedProductID == product.id
                ) {
                    selectedProductID = product.id
                }
            }

            if subscriptionManager.products.isEmpty && !subscriptionManager.isLoading {
                Text("Plans are temporarily unavailable. You can still restore purchases.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }

            VStack(spacing: 10) {
                Button(action: {
                    Task { await purchaseSelected() }
                }) {
                    VStack(alignment: .leading, spacing: 2) {
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

                        if !billingCaption.isEmpty {
                            Text(billingCaption)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
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

                Text("Auto-renewable subscription. Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    private func billingUnit(for product: Product) -> String {
        switch product.id {
        case SubscriptionManager.ProductID.yearly:
            return "per year"
        case SubscriptionManager.ProductID.monthly:
            return "per month"
        default:
            return ""
        }
    }

    private var legalLinksRow: some View {
        HStack(spacing: 16) {
            Link("Privacy Policy", destination: LegalLinks.privacyPolicyURL)
            Link("Terms of Use (EULA)", destination: LegalLinks.termsOfUseURL)
        }
        .font(.footnote)
        .foregroundColor(.blue)
    }
}

private struct PlanRow: View {
    let title: String
    let subtitle: String
    let billedPrice: String
    let billingUnit: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(billedPrice)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        if !billingUnit.isEmpty {
                            Text(billingUnit)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
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

private struct FeatureRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.blue)
                .font(.body)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

