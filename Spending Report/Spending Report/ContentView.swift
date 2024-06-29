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
    var amount: Float
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

// Expense list item view
struct ExpenseListItemView: View {
    let expense: ExpenseItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(expense.category): $\(String(format: "%.2f", expense.amount)) - \(formattedDate(date: expense.date))")
                .font(.headline)
                .foregroundColor(.primary)
            if !expense.description.isEmpty {
                Text(expense.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// Utility function to format date
func formattedDate(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}


// Opening page
struct ContentView: View {
    @StateObject var expenseStore = ExpenseStore() // Initialize expense store
    
    var body: some View {
        NavigationView {
            TabView {
                NavigationView {
                    Spenditures()
                        .navigationBarTitle("Spenditures")
                }
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Spenditures")
                }
                NavigationView {
                    Budget()
                        .navigationBarTitle("Budget")
                }
                .tabItem {
                    Image(systemName: "dollarsign")
                    Text("Budget")
                }
                NavigationView {
                    Temp()
                        .navigationBarTitle("Temp")
                }
                .tabItem {
                    Image(systemName: "person")
                    Text("Temp")
                }
            }
            .navigationBarHidden(true)
        }
        .environmentObject(expenseStore)
    }
}

// View model for managing expense creation
class ExpenseViewModel: ObservableObject {
    @Published var category = ""
    @Published var amountString = ""
    @Published var date = Date()
    @Published var description = ""
    @Published var resetNavigationID = UUID()

    var amount: Float {
        return Float(amountString) ?? 0.0
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

// Spenditures view to display and manage expenses
struct Spenditures: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @StateObject private var viewModel = ExpenseViewModel()
    @State private var isShowingDetails = false
    @State private var selectedExpense: ExpenseItem?
    
    private func editExpense(_ expense: ExpenseItem) {
        selectedExpense = expense
        isShowingDetails = true
    }
    
    let categories = ["", "Gas", "Sweet Treats", "Eating Out", "Fun Items", "Video Games", "Gifts", "Necessities", "Groceries", "Experiences"]
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Group")) {
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
                        Button(action: {
                            editExpense(expense)
                        }) {
                            ExpenseListItemView(expense: expense)
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
            .bold()
            .controlSize(.extraLarge)
            .foregroundColor(.primary)
            .preferredColorScheme(.dark)
            .padding()
        }
        .id(viewModel.resetNavigationID)
        .sheet(item: $selectedExpense) { expense in
            Details(isPresented: $selectedExpense, expense: expense)
                .environmentObject(expenseStore)
        }
    }
}

// Details view for editing an expense
struct Details: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @Binding var isPresented: ExpenseItem?
    var expense: ExpenseItem

    @State private var editedCategory = ""
    @State private var editedAmountString = ""
    @State private var editedDate = Date()
    @State private var editedDescription = ""

    private var amount: Float {
        return Float(editedAmountString) ?? 0
    }
    
    private func saveChanges() {
        guard let index = expenseStore.expenses.firstIndex(where: { $0.id == expense.id }) else { return }

        let updatedExpense = ExpenseItem(
            id: expense.id,
            category: editedCategory,
            amount: amount,
            date: editedDate,
            description: editedDescription
        )

        expenseStore.expenses[index] = updatedExpense
        isPresented = nil // Dismiss the sheet
    }

    private func deleteEntry() {
        expenseStore.deleteExpense(expense)
        isPresented = nil // Dismiss the sheet
    }

    let categories = ["", "Gas", "Sweet Treats", "Eating Out", "Fun Items", "Video Games", "Gifts", "Necessities", "Groceries", "Experiences"]
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Group")) {
                        Picker("Category", selection: $editedCategory) {
                            ForEach(categories.sorted(), id: \.self) {
                                Text($0)
                            }
                        }
                    }

                    Section(header: Text("Amount")) {
                        TextField("$", text: $editedAmountString)
                            .keyboardType(.decimalPad)
                    }

                    Section(header: Text("Date")) {
                        DatePicker("Date of Purchase", selection: $editedDate, displayedComponents: .date)
                    }

                    Section(header: Text("Description")) {
                        TextField("Description", text: $editedDescription)
                    }
                }
                .onAppear {
                    // Initialize edited fields with existing expense data
                    editedCategory = expense.category
                    editedAmountString = String(expense.amount)
                    editedDate = expense.date
                    editedDescription = expense.description
                }
                .navigationBarTitle("Edit Expense", displayMode: .inline)

                HStack {
                    Button("Save") {
                        saveChanges()
                    }
                    .padding()
                    .bold()
                    .controlSize(.extraLarge)
                    .foregroundColor(.primary)

                    Button("Delete") {
                        deleteEntry()
                    }
                    .bold()
                    .controlSize(.extraLarge)
                    .padding()
                    .foregroundColor(.primary)
                }
            }
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}

// Placeholder views for other tabs
struct Budget: View {
    var body: some View {
        Text("Budget")
    }
}

struct Temp: View {
    var body: some View {
        Text("Temp")
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ExpenseStore())
            .preferredColorScheme(.dark)
    }
}
