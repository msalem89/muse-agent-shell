import SwiftUI

@MainActor
class TaskDashboardViewModel: ObservableObject {
    @Published var tasks: [AgentTask] = []
    
    var runningTasks: [AgentTask] { tasks.filter { $0.status == .running } }
    var approvalTasks: [AgentTask] { tasks.filter { $0.status == .needsApproval } }
    var completedTasks: [AgentTask] { tasks.filter { $0.status == .completed } }
    
    func loadTasks() {
        Task {
            let fetchedTasks = await BackendService.shared.fetchTasks()
            self.tasks = fetchedTasks
        }
    }
}

struct TaskDashboardView: View {
    @StateObject private var viewModel = TaskDashboardViewModel()
    
    var body: some View {
        NavigationView {
            List {
                if !viewModel.approvalTasks.isEmpty {
                    Section(header: Text("Needs Approval").foregroundColor(.orange)) {
                        ForEach(viewModel.approvalTasks) { task in
                            TaskRow(task: task)
                        }
                    }
                }
                
                if !viewModel.runningTasks.isEmpty {
                    Section(header: Text("Running").foregroundColor(.blue)) {
                        ForEach(viewModel.runningTasks) { task in
                            TaskRow(task: task)
                        }
                    }
                }
                
                if !viewModel.completedTasks.isEmpty {
                    Section(header: Text("Completed").foregroundColor(.green)) {
                        ForEach(viewModel.completedTasks) { task in
                            TaskRow(task: task)
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                viewModel.loadTasks()
            }
        }
    }
}

struct TaskRow: View {
    let task: AgentTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.headline)
            Text(task.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
