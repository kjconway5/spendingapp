//
//  ContentView.swift
//  Spending Report
//
//  Created by Kye Conway on 3/27/24.
//

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
        saveExpensesToUserDefaults()
        // Update the UI
        objectWillChange.send()
    }
    
    // Function to update an expense
    func updateExpense(_ expense: ExpenseItem) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveExpensesToUserDefaults()
            // Update the UI
            objectWillChange.send()
        }
    }
    
    // Function to delete an expense
    func deleteExpense(_ expense: ExpenseItem) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses.remove(at: index)
            saveExpensesToUserDefaults()
            objectWillChange.send()
        } else {
            print("Error: Attempted to delete an expense that does not exist.")
        }
    }
    
    // Save expenses to UserDefaults
    func saveExpensesToUserDefaults() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: "expenses")
        }
    }
    
    // Load expenses from UserDefaults
    func loadExpensesFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "expenses") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([ExpenseItem].self, from: data) {
                expenses = decoded
            }
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
        .onAppear {
            expenseStore.loadExpensesFromUserDefaults()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            expenseStore.saveExpensesToUserDefaults()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
            expenseStore.saveExpensesToUserDefaults()
        }
    }
}

// Page to add what was purchased
struct Spenditures: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    
    @State private var category = ""
    @State private var amountString = ""
    @State private var date = Date()
    @State private var description = "" // New state variable for description
    @State private var resetNavigationID = UUID() // Unique identifier to reset navigation view

    private var amount: Double {
        return Double(amountString) ?? 0
    }

    private func addExpense() {
        if !category.isEmpty && amount > 0 {
            let newExpense = ExpenseItem(category: category, amount: amount, date: date, description: description)
            expenseStore.addExpense(newExpense)
            
            // Clearing fields
            category = ""
            amountString = ""
            description = ""
        }
    }
    
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    let categories = ["", "Gas", "Sweet Treats", "Eating Out", "Fun Items", "Video Games", "Gifts", "Necessities", "Groceries", "Experiences"]

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Expense Group")) {
                        Picker("Category", selection: $category) {
                            ForEach(categories.sorted(), id: \.self) {
                                Text($0)
                            }
                        }
                    }
                    Section(header: Text("Amount")) {
                        TextField("$", text: $amountString)
                            .keyboardType(.decimalPad)
                    }
                    Section(header: Text("Date")) {
                        DatePicker("Date of Purchase", selection: $date, displayedComponents: .date)
                    }
                    Section(header: Text("Description")) {
                        TextField("Description", text: $description)
                    }
                    List {
                        ForEach(expenseStore.expenses.suffix(5).reversed(), id: \.id) { expense in
                            VStack(alignment: .leading) {
                                if let index = expenseStore.expenses.firstIndex(where: { $0.id == expense.id }) {
                                    NavigationLink(destination: Details(expense: $expenseStore.expenses[index]).environmentObject(expenseStore)) {
                                        Text("\(expense.category): $\(String(format: "%.2f", expense.amount)) - \(formattedDate(date: expense.date))")
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer()
                Button("Add Expense") {
                    addExpense()
                }
                .foregroundColor(.primary)
                Spacer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            expenseStore.saveExpensesToUserDefaults()
        }

    }
}



struct Details: View {
    @Binding var expense: ExpenseItem
    @State private var category = ""
    @State private var amountString = ""
    @State private var date = Date()
    @State private var description = ""
    
    @Environment(\.presentationMode) var presentationMode
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
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func deleteEntry() {
        expenseStore.deleteExpense(expense)
        presentationMode.wrappedValue.dismiss()
        }
    
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    let categories = ["", "Gas", "Sweet Treats", "Eating Out", "Fun Items", "Video Games", "Gifts", "Necessities", "Groceries", "Experiences"]
    
    var body: some View {
        Form {
            Section(header: Text("Expense Group")) {
                Picker("Category", selection: $category) {
                    ForEach(categories.sorted(), id: \.self) {
                        Text($0)
                    }
                }
                .onAppear {
                    category = expense.category
                    amountString = String(expense.amount)
                    date = expense.date
                    description = expense.description
                }
            }
            Section(header: Text("Amount")) {
                TextField("$", text: $amountString)
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
            category = expense.category
            amountString = String(expense.amount)
            date = expense.date
            description = expense.description
        }
        .navigationBarItems(trailing: Button("Save") {
            saveChanges()
        })
        .navigationBarItems(trailing: Button("Delete") {
            deleteEntry()
        })
        .navigationBarTitle("Edit Expense", displayMode: .inline)
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
        Group {
            ContentView()
                .environmentObject(ExpenseStore())
                .preferredColorScheme(.dark)
        }
    }
}
