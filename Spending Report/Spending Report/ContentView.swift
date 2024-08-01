//  ContentView.swift
//
//  Spending Report
//
//  Created by Kye Conway on 3/27/24.

import SwiftUI
import Charts

// Structure to hold expense information
struct ExpenseItemStruct: Identifiable, Codable {
    var id = UUID()
    var category: String
    var amount: Float
    var date: Date
    var description: String
    
    init(id: UUID = UUID(), category: String, amount: Float, description: String, date: Date) {
            self.id = id
            self.category = category
            self.amount = amount
            self.description = description
            self.date = date
        }
}

// Global expense store to manage expenses
class ExpenseStore: ObservableObject {
    @Published var expenses = [ExpenseItemStruct]()
    private let fileName = "expenses.json"
    
    init() {
        loadExpenses()
    }
    
    // Function to add an expense
    func addExpense(_ expense: ExpenseItemStruct) {
        expenses.append(expense)
        saveExpenses()
    }
    
    // Function to update an expense
    func updateExpense(_ expense: ExpenseItemStruct) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveExpenses()
        }
    }
    
    // Function to delete an expense
    func deleteExpense(_ expense: ExpenseItemStruct) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses.remove(at: index)
            saveExpenses()
        }
    }

    private func saveExpenses() {
        if let data = try? JSONEncoder().encode(expenses) {
            let url = getDocumentsDirectory().appendingPathComponent(fileName)
            try? data.write(to: url)
        }
    }

    private func loadExpenses() {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: url) {
            if let decodedExpenses = try? JSONDecoder().decode([ExpenseItemStruct].self, from: data) {
                expenses = decodedExpenses
            }
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// Global budget store to manage the monthly budget
class BudgetStore: ObservableObject {
    @Published var totalBudget: Float = 0
    @Published var remainingBudget: Float = 0
    private let fileName = "budget.json"
    
    init() {
        loadBudget()
        resetMonthlyBudget()
    }
    
    // Function to set the monthly budget
    func setMonthlyBudget(_ amount: Float) {
        totalBudget = amount
        remainingBudget = amount
        saveBudget()
    }
    
    // Function to reset the budget at the start of each month
    func resetMonthlyBudget() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        if let firstDayOfMonth = calendar.date(from: components) {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth)!
            let timer = Timer(fireAt: nextMonth, interval: 0, target: self, selector: #selector(resetBudget), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: .default)
        }
    }
    
    @objc private func resetBudget() {
        remainingBudget = totalBudget
        saveBudget()
        resetMonthlyBudget() // Schedule the next reset
    }
    
    // Function to subtract expense from the budget
    func subtractExpense(_ amount: Float, date: Date) {
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month], from: Date())
        let expenseComponents = calendar.dateComponents([.year, .month], from: date)
        
        if currentComponents.year == expenseComponents.year && currentComponents.month == expenseComponents.month {
            remainingBudget -= amount
            saveBudget()
        }
    }

    private func saveBudget() {
        let budgetData = BudgetData(totalBudget: totalBudget, remainingBudget: remainingBudget)
        if let data = try? JSONEncoder().encode(budgetData) {
            let url = getDocumentsDirectory().appendingPathComponent(fileName)
            try? data.write(to: url)
        }
    }

    private func loadBudget() {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: url) {
            if let decodedBudget = try? JSONDecoder().decode(BudgetData.self, from: data) {
                totalBudget = decodedBudget.totalBudget
                remainingBudget = decodedBudget.remainingBudget
            }
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private struct BudgetData: Codable {
        let totalBudget: Float
        let remainingBudget: Float
    }
}

// Expense list item view
struct ExpenseListItemView: View {
    let expense: ExpenseItemStruct
    
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

// Utility function to get current month
func currentMonth() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM"
    return formatter.string(from: Date())
}

// Opening page
struct ContentView: View {
    @StateObject var expenseStore = ExpenseStore() // Initialize expense store
    @StateObject var budgetStore = BudgetStore()   // Initialize budget store
    
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
                        .navigationBarTitle("Budget - \(currentMonth())")
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
        .environmentObject(budgetStore)
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
    
    func addExpense(to store: ExpenseStore, budgetStore: BudgetStore) {
        if !category.isEmpty && amount > 0 {
            let newExpense = ExpenseItemStruct(category: category, amount: amount, description: description, date: date)
            store.addExpense(newExpense)
            budgetStore.subtractExpense(amount, date: date) // Ensure expense is subtracted from budget if within the current month
            
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
    @EnvironmentObject var budgetStore: BudgetStore
    @StateObject private var viewModel = ExpenseViewModel()
    @State private var isShowingDetails = false
    @State private var selectedExpense: ExpenseItemStruct? = nil

    private func editExpense(_ expense: ExpenseItemStruct) {
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
                    viewModel.addExpense(to: expenseStore, budgetStore: budgetStore)
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
                .environmentObject(budgetStore)
        }
    }
}

// Details view for editing an expense
struct Details: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @EnvironmentObject var budgetStore: BudgetStore
    @Binding var isPresented: ExpenseItemStruct?
    var expense: ExpenseItemStruct

    @State private var editedCategory = ""
    @State private var editedAmountString = ""
    @State private var editedDate = Date()
    @State private var editedDescription = ""

    private var amount: Float {
        return Float(editedAmountString) ?? 0
    }

    private func saveChanges() {
        guard let index = expenseStore.expenses.firstIndex(where: { $0.id == expense.id }) else { return }

        let updatedExpense = ExpenseItemStruct(
            id: expense.id,
            category: editedCategory,
            amount: amount,
            description: editedDescription,
            date: editedDate
            
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
    @EnvironmentObject var budgetStore: BudgetStore
    @EnvironmentObject var expenseStore: ExpenseStore
    @State private var budgetString = ""
    @State private var changeBudget = false
    @State private var selectedCategory: String = ""
    
    private var categories: [String] {
        return Array(Set(expenseStore.expenses.map { $0.category })).sorted()
    }
    
    private var selectedCategoryTotal: Float {
        return expenseStore.expenses
            .filter { $0.category == selectedCategory }
            .reduce(0) { $0 + $1.amount }
        }

    var body: some View {
        VStack {
            Form {
                if budgetStore.totalBudget == 0 || changeBudget {
                    Section(header: Text("Set Monthly Budget")) {
                        TextField("Enter budget", text: $budgetString)
                            .keyboardType(.decimalPad)
                        
                        Button("Set Budget") {
                            if let budget = Float(budgetString) {
                                budgetStore.setMonthlyBudget(budget)
                                budgetString = ""  // Clear the text field after setting the budget
                                changeBudget = false
                            }
                        }
                    }
                } else {
                    Section(header: Text("Current Monthly Budget")) {
                        Text("Total Budget: $\(String(format: "%.2f", budgetStore.totalBudget))")
                        Text("Remaining Budget: $\(String(format: "%.2f", budgetStore.remainingBudget))")
                        Button("Change Budget") {
                            changeBudget.toggle()
                        }
                    }
                    
                    if budgetStore.totalBudget != budgetStore.remainingBudget {
                        SectorChartExample()
                            .frame(height: 225)
                        
                        Section(header: Text("Breakdown by Group")) {
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) {
                                    Text($0)
                                }
                            }
                            
                            if !selectedCategory.isEmpty {
                                Text("Total for \(selectedCategory): $\(String(format: "%.2f", selectedCategoryTotal))")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SectorChartExample: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    
    struct ExpenseCategory: Identifiable {
        let id = UUID()
        let category: String
        let total: Float
    }
    
    var aggregatedExpenses: [ExpenseCategory] {
        let grouped = Dictionary(grouping: expenseStore.expenses, by: { $0.category })
        return grouped.map { category, expenses in
            ExpenseCategory(category: category, total: expenses.reduce(0) { $0 + $1.amount })
        }
    }
    
    var body: some View {
        Chart(aggregatedExpenses) { expenseCategory in
            SectorMark(
                angle: .value(expenseCategory.category, expenseCategory.total),
                innerRadius: .ratio(0.6),
                angularInset: 8
            )
            .foregroundStyle(by: .value("Category", expenseCategory.category))
        }
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
            .environmentObject(BudgetStore())
            .preferredColorScheme(.dark)
    }
}
