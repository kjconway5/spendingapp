//
//  ContentView.swift
//  Spending Report
//
//  Created by Kye Conway on 3/27/24.
//

import SwiftUI
import SwiftUICharts

// Structure to hold expense information
struct ExpenseItem: Identifiable, Codable {
    var id = UUID()
    var category: String
    var amount: Double
    var date: Date
}

// Global expense store to manage expenses
class ExpenseStore: ObservableObject {
    // Array to store expenses
    @Published var expenses = [ExpenseItem]()
    
    // Function to add an expense
    func addExpense(_ expense: ExpenseItem) {
        expenses.append(expense)
        // Update the UI
        objectWillChange.send()
    }
}

// Opening page
struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Image(systemName: "dollarsign")
                    .bold()
                    .imageScale(.large)
                    
                    
                Spacer()
                HStack{
                    NavigationLink(destination: Spenditures()) {
                        Text("Spenditures")
                            .bold()
                            .controlSize(.extraLarge)
                            .foregroundColor(.primary)
                            .padding()
                    }
                    
                    NavigationLink(destination: Budget()){
                        Text("Budget")
                            .bold()
                            .controlSize(.extraLarge)
                            .foregroundColor(.primary)
                            .padding()
                    }

                }
                .navigationBarTitle("")
                .navigationBarHidden(true) // Hide navigation bar on opening page
            }
        }
    }
}


// Page to add what was purchased
struct Spenditures: View {
    @State private var category = ""
    @State private var amountString = ""
    @State private var date = Date()
    
    // Variables to keep track of total spending for each category
    @State private var gasTot: Double = 0
    @State private var treatTot: Double = 0
    @State private var eatTot: Double = 0
    @State private var funTot: Double = 0
    @State private var gamesTot: Double = 0
    @State private var giftTot: Double = 0
    @State private var nessTot: Double = 0
    @State private var grocTot: Double = 0
    @State private var expTot: Double = 0

    @StateObject var expenseStore = ExpenseStore() // Initialize expense store
    
    private var amount: Double {
        return Double(amountString) ?? 0
    }
    
    var amountTotal: Double {
        return gasTot + treatTot + eatTot + funTot + gamesTot + giftTot + nessTot + grocTot + expTot
    }

    private func addExpense() {
        if !category.isEmpty && amount > 0 {
            let newExpense = ExpenseItem(category: category, amount: amount, date: date)
            expenseStore.addExpense(newExpense)
            
            // Update category totals
            updateCategoryTotals(newExpense: newExpense)
            
            // Clear input fields after adding expense
            category = ""
            amountString = ""
        }
    }
    
    private func updateCategoryTotals(newExpense: ExpenseItem) {
        switch newExpense.category {
        case "Gas":
            gasTot += newExpense.amount
        case "Sweet Treats":
            treatTot += newExpense.amount
        case "Eating Out":
            eatTot += newExpense.amount
        case "Fun Items":
            funTot += newExpense.amount
        case "Video Games":
            gamesTot += newExpense.amount
        case "Gifts":
            giftTot += newExpense.amount
        case "Necessities":
            nessTot += newExpense.amount
        case "Groceries":
            grocTot += newExpense.amount
        case "Experiences":
            expTot += newExpense.amount
        default:
            break
        }
    }
    
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func saveExpensesToUserDefaults() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(expenseStore.expenses) {
            UserDefaults.standard.set(encoded, forKey: "expenses")
        }
    }
    
    private func loadExpensesFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "expenses") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([ExpenseItem].self, from: data) {
                expenseStore.expenses = decoded
            }
        }
    }
    
    private func updateCategoryTotalsFromExpenses() {
        gasTot = expenseStore.expenses.filter { $0.category == "Gas" }.reduce(0) { $0 + $1.amount }
        treatTot = expenseStore.expenses.filter { $0.category == "Sweet Treats" }.reduce(0) { $0 + $1.amount }
        eatTot = expenseStore.expenses.filter { $0.category == "Eating Out" }.reduce(0) { $0 + $1.amount }
        funTot = expenseStore.expenses.filter { $0.category == "Fun Items" }.reduce(0) { $0 + $1.amount }
        gamesTot = expenseStore.expenses.filter { $0.category == "Video Games" }.reduce(0) { $0 + $1.amount }
        giftTot = expenseStore.expenses.filter { $0.category == "Gifts" }.reduce(0) { $0 + $1.amount }
        nessTot = expenseStore.expenses.filter { $0.category == "Necessities" }.reduce(0) { $0 + $1.amount }
        grocTot = expenseStore.expenses.filter { $0.category == "Groceries" }.reduce(0) { $0 + $1.amount }
        expTot = expenseStore.expenses.filter { $0.category == "Experiences" }.reduce(0) { $0 + $1.amount }
    }
    
    
    
    let categories = ["", "Gas", "Sweet Treats", "Eating Out", "Fun Items", "Video Games", "Gifts", "Necessities", "Groceries", "Experiences"]

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Expense Group")) {
                    Picker("Category", selection: $category) {
                        ForEach(categories.sorted(), id: \.self) {
                            Text($0)
                        }
                    }
                }
                Section(header: Text("Amount")){
                    TextField("$", text: $amountString)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("Date")){
                    DatePicker("Date of Purchase", selection: $date, displayedComponents: .date)
                }
                // Display the total expenditure for each category
                List {
                    ForEach(expenseStore.expenses.suffix(3).reversed(), id: \.id) { expense in
                        Text("\(expense.category): $\(String(format: "%.2f", expense.amount)) - \(formattedDate(date: expense.date))")
                    }
                }
            }
            
            let chartStyle = ChartStyle(backgroundColor: .black, accentColor: .primary, secondGradientColor: Colors.GradientNeonBlue, textColor: .primary, legendTextColor: .primary, dropShadowColor: .white)
            
            
            
            PieChartView(data: [gasTot, treatTot, eatTot, funTot, gamesTot, giftTot, nessTot, grocTot, expTot], title: "Spending Habits", legend: "Total: $\(String(format: "%.2f", amountTotal))", style: chartStyle, form: ChartForm.large, dropShadow: false)
            
            Spacer()
            Spacer()
            Spacer()
            
            Button("Add Expense"){
                addExpense()
            }
            .foregroundColor(.primary)
            
            
           
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            saveExpensesToUserDefaults()
        }
        .onAppear {
            loadExpensesFromUserDefaults()
            updateCategoryTotalsFromExpenses()
        }
    }
}


struct Budget: View {
    var body: some View {
        Text("Budget")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            Spenditures()
                .preferredColorScheme(.dark)
        }
    }
}
