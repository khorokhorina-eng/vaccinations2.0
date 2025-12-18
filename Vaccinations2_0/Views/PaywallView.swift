//
//  PaywallView.swift
//  VaccineCalendar
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var viewModel: VaccineViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedProductID: String = SubscriptionManager.ProductID.yearly
    @State private var freeTrialEnabled: Bool = true

    @State private var promoCode: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var showGoBackConfirmation: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.92),
                    Color.pink.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerBar
                        .padding(.top, 8)

                    VStack(spacing: 10) {
                        Text("Choose your plan")
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        StarsRow()

                        Text("“Best app I love this app and all the insight it\ngives on health and your body!”")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("fefe prescod")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 6)
                    }
                    .padding(.top, 6)

                    trialToggle
                        .padding(.top, 6)

                    VStack(spacing: 12) {
                        ForEach(displayProducts, id: \.id) { product in
                            PlanCard(
                                title: planTitle(for: product),
                                leftSubtitle: planLeftSubtitle(for: product),
                                rightSubtitle: planRightSubtitle(for: product),
                                isSelected: selectedProductID == product.id
                            ) {
                                selectedProductID = product.id
                            }
                        }

                        if subscriptionManager.products.isEmpty && !subscriptionManager.isLoading {
                            Text("Plans are temporarily unavailable. You can still restore purchases or use a promo code.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 4)

                    promoCodeSection
                        .padding(.top, 6)

                    ctaButton
                        .padding(.top, 6)

                    Button("Go back") {
                        showGoBackConfirmation = true
                    }
                    .foregroundColor(.primary)
                    .padding(.top, 2)

                    Text("Monthly: $5. Yearly: $30. Yearly plan includes a 1-week free trial for eligible new subscribers (configured in App Store Connect).")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            if subscriptionManager.products.isEmpty {
                Task { await subscriptionManager.loadProducts() }
            }
        }
        .onChange(of: subscriptionManager.products) { newProducts in
            if !newProducts.isEmpty, selectedProduct == nil {
                selectedProductID = newProducts.first(where: { $0.id == SubscriptionManager.ProductID.yearly })?.id
                    ?? newProducts.first?.id
                    ?? selectedProductID
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
        .alert("Are you sure?", isPresented: $showGoBackConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Go back", role: .destructive) {
                viewModel.resetAllData()
            }
        } message: {
            Text("This will take you back to registration.")
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
        if selectedProductID == SubscriptionManager.ProductID.yearly, freeTrialEnabled {
            return "Start 7-Day Free Trial"
        }
        return "Continue"
    }

    private func planTitle(for product: Product) -> String {
        switch product.id {
        case SubscriptionManager.ProductID.monthly:
            return "Monthly"
        case SubscriptionManager.ProductID.yearly:
            return "Yearly Plan"
        default:
            return product.displayName
        }
    }

    private func planLeftSubtitle(for product: Product) -> String {
        switch product.id {
        case SubscriptionManager.ProductID.yearly:
            return "12 mo • \(product.displayPrice)"
        case SubscriptionManager.ProductID.monthly:
            return "Monthly"
        default:
            return ""
        }
    }

    private func planRightSubtitle(for product: Product) -> String {
        switch product.id {
        case SubscriptionManager.ProductID.yearly:
            if let perMonth = perMonthString(for: product) {
                return "\(perMonth) / mo"
            }
            return ""
        case SubscriptionManager.ProductID.monthly:
            return "\(product.displayPrice) / mo"
        default:
            return ""
        }
    }

    private func perMonthString(for yearlyProduct: Product) -> String? {
        guard yearlyProduct.id == SubscriptionManager.ProductID.yearly else { return nil }
        let total = yearlyProduct.price
        let perMonth = total / Decimal(12)
        let number = NSDecimalNumber(decimal: perMonth)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = yearlyProduct.priceFormatStyle.currencyCode
        return formatter.string(from: number)
    }

    private func purchaseSelected() async {
        guard let product = selectedProduct else { return }
        await subscriptionManager.purchase(product: product)
    }

    private var headerBar: some View {
        HStack {
            Button(action: {
                showGoBackConfirmation = true
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.primary)
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Circle())
            }

            Spacer()

            Button("Restore") {
                Task { await subscriptionManager.restorePurchases() }
            }
            .foregroundColor(.secondary)
            .disabled(subscriptionManager.isLoading)
        }
    }

    private var trialToggle: some View {
        HStack {
            Text("Free trial enabled")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: $freeTrialEnabled)
                .labelsHidden()
                .tint(.purple)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.purple.opacity(0.10))
        )
    }

    private var promoCodeSection: some View {
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
    }

    private var ctaButton: some View {
        Button(action: {
            Task { await purchaseSelected() }
        }) {
            HStack {
                Spacer()
                Text(primaryButtonTitle)
                    .font(.headline)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.pink)
            )
        }
        .disabled(subscriptionManager.isLoading || selectedProduct == nil)
        .overlay(alignment: .trailing) {
            if subscriptionManager.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(.trailing, 18)
            }
        }
    }
}

private struct StarsRow: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
            Image(systemName: "star.fill")
            Image(systemName: "star.fill")
            Image(systemName: "star.fill")
            Image(systemName: "star.leadinghalf.filled")
        }
        .font(.title3)
        .foregroundColor(Color.orange)
        .padding(.top, 2)
    }
}

private struct PlanCard: View {
    let title: String
    let leftSubtitle: String
    let rightSubtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(.primary)

                    if !leftSubtitle.isEmpty {
                        Text(leftSubtitle)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    if !rightSubtitle.isEmpty {
                        Text(rightSubtitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .pink : .secondary.opacity(0.6))
                        .font(.title2)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.pink : Color.gray.opacity(0.2), lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

