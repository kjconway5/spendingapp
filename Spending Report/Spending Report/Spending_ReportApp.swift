//
//  Spending_ReportApp.swift
//  Spending Report
//
//  Created by Kye Conway on 3/27/24.
//

import SwiftUI

@main
struct Spending_ReportApp: App {
    @StateObject private var expenseStore = ExpenseStore()
    @StateObject private var budgetStore = BudgetStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(expenseStore)
                .environmentObject(budgetStore)
        }
    }
}
