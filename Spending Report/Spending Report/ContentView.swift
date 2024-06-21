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
                    // List
                }
                Button("Add Expense") {
                    withAnimation {
                        addExpense()
                    }
                }
                
            }
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
    g
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
    
    let categories = ["", "Gas", "Sweet Treats", "Eating Out", "Fun Items", "Video Games", "Gifts", "Necessities", "Groceries", "Experiences"]
    
    var body: some View {
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
        }
        .onAppear {
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
