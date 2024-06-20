//  ContentView.swift
//
//  Spending Report
//
//  Created by Kye Conway on 3/27/24.

import SwiftUI

// Structure to hold expense information
struct ExpenseItem: Identifiable, Codable {
    var id = UUID()
    var category: String
    var amount: Double
    var date: Date
    var description: String
}

// Global expense store to manage expenses
class ExpenseStore: ObservableObject {
    @Published var expenses = [ExpenseItem]()
    
    // Function to add an expense
    func addExpense(_ expense: ExpenseItem) {
        expenses.append(expense)
    }
    
    // Function to update an expense
    func updateExpense(_ expense: ExpenseItem) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        }
    }
    
    // Function to delete an expense
    func deleteExpense(_ expense: ExpenseItem) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses.remove(at: index)
        }
    }
}

// Opening page
struct ContentView: View {
    @StateObject var expenseStore = ExpenseStore() // Initialize expense store
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Image(systemName: "dollarsign")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Spacer()
                HStack {
                    NavigationLink(destination: Spenditures().environmentObject(expenseStore)) {
                        Text("Spenditures")
                            .bold()
                            .controlSize(.large)
                            .padding()
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: Budget()) {
                        Text("Budget")
                            .bold()
                            .controlSize(.large)
                            .padding()
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: Holder()) {
                        Text("Holder")
                            .bold()
                            .controlSize(.large)
                            .padding()
                            .foregroundColor(.primary)
                    }
                }
                .navigationBarTitle("")
                .navigationBarHidden(true)
            }
        }
    }
}

class ExpenseViewModel: ObservableObject {
    @Published var category = ""
    @Published var amountString = ""
    @Published var date = Date()
    @Published var description = ""
    @Published var resetNavigationID = UUID()

    var amount: Double {
        return Double(amountString) ?? 0
    }

    func addExpense(to store: ExpenseStore) {
        if !category.isEmpty && amount > 0 {
            let newExpense = ExpenseItem(category: category, amount: amount, date: date, description: description)
            store.addExpense(newExpense)
            
            // Clearing fields
            category = ""
            amountString = ""
            description = ""
            
            // Reset navigation ID to force view refresh
            resetNavigationID = UUID()
        }
    }
}

struct Spenditures: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @StateObject private var viewModel = ExpenseViewModel()
    
    let categories = ["", "Gas", "Sweet Treats", "Eating Out", "Fun Items", "Video Games", "Gifts", "Necessities", "Groceries", "Experiences"]

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Expense Group")) {
                        Picker("Category", selection: $viewModel.category) {
                            ForEach(categories.sorted(), id: \.self) {
                                Text($0)
                            }
                        }
                    }
                    Section(header: Text("Amount")) {
                        TextField("$", text: $viewModel.amountString)
                            .keyboardType(.decimalPad)
                    }
                    Section(header: Text("Date")) {
                        DatePicker("Date of Purchase", selection: $viewModel.date, displayedComponents: .date)
                    }
                    Section(header: Text("Description")) {
                        TextField("Description", text: $viewModel.description)
                    }
                    List {
                        ForEach(expenseStore.expenses.suffix(5).reversed(), id: \.id) { expense in
                            if let index = expenseStore.expenses.firstIndex(where: { $0.id == expense.id }) {
                                NavigationLink(destination: Details(expense: $expenseStore.expenses[index]).environmentObject(expenseStore)) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("\(expense.category): $\(String(format: "%.2f", expense.amount)) - \(formattedDate(date: expense.date))")
                                            .font(.headline)
                                        if !expense.description.isEmpty {
                                            Text(expense.description)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 40)
                }
                
                Button("Add Expense") {
                    withAnimation {
                        viewModel.addExpense(to: expenseStore)
                    }
                }
                .padding()
            }
            .frame(height: 750)
            .id(viewModel.resetNavigationID)
        }
    }
}

func formattedDate(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

struct Details: View {
    @Binding var expense: ExpenseItem
    @State private var category = ""
    @State private var amountString = ""
    @State private var date = Date()
    @State private var description = ""
    
    @EnvironmentObject var expenseStore: ExpenseStore
    
    private var amount: Double {
        return Double(amountString) ?? 0
    }
    
    private func saveChanges() {
        if !category.isEmpty && amount > 0 {
            expense.category = category
            expense.amount = amount
            expense.date = date
            expense.description = description
            expenseStore.updateExpense(expense)
        }
    }
    
    private func deleteEntry() {
        expenseStore.deleteExpense(expense)
    }
    
    let categories = ["", "Gas", "Sweet Treats", "Eating Out", "Fun Items", "Video Games", "Gifts", "Necessities", "Groceries", "Experiences"]
    
    var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Expense Group")) {
                        Picker("Category", selection: $category) {
                            ForEach(categories.sorted(), id: \.self) {
                                Text($0)
                            }
                        }
                    }

                    Section(header: Text("Amount")) {
                        TextField("$$", text: $amountString)
                            .keyboardType(.decimalPad)
                    }

                    Section(header: Text("Date")) {
                        DatePicker("Date of Purchase", selection: $date, displayedComponents: .date)
                    }

                    Section(header: Text("Description")) {
                        TextField("Description", text: $description)
                    }
                }
                .onAppear {
                    // Populate fields with existing expense data if available
                    category = expense.category
                    amountString = String(expense.amount)
                    date = expense.date
                    description = expense.description
                }
                .navigationBarItems(trailing: HStack {
                    Button("Save") {
                        saveChanges()
                    }
                    Button("Delete") {
                        deleteEntry()
                    }
                })
                .navigationBarTitle("Edit Expense", displayMode: .inline)
        }
    }
}

struct Budget: View {
    var body: some View {
        Text("Budget")
    }
}

struct Holder: View {
    var body: some View {
        Text("Holder")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ExpenseStore())
            .preferredColorScheme(.dark)
    }
}
