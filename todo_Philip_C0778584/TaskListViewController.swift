//
//  TaskListViewController.swift
//  todo_Philip_C0778584
//
//  Created by user175490 on 6/28/20.
//  Copyright © 2020 user175490. All rights reserved.
//

import UIKit
import CoreData

class TaskListViewController: UIViewController {
    
    var selectedSort = 0
    var selectedCategory: Category? {
        didSet {
            loadTodos()
        }
    }
    
    var categoryName: String!
    let todoListContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var tasksArray = [Todo]()
    var selectedTodo: Todo?
    var todoToMove = [Todo]()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var sortSegment: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setUpTableView()
        showSearchBar()
        categoryLabel.text = selectedCategory!.name
    }
    

    @IBAction func addTodo(_ sender: Any) {
        performSegue(withIdentifier: "todoViewScreen", sender: self)
    }
    
    
    @IBAction func sortTool(_ sender: UISegmentedControl) {
           switch sender.selectedSegmentIndex {
           case 0: selectedSort = 0
               break
           case 1: selectedSort = 1
               break
           default:
               break
           }
           
           loadTodos()
           tableView.reloadData()
       }
       
       override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           
           if let destination = segue.destination as? TodoViewController {
               destination.delegate = self
               if selectedTodo != nil
               {
                   destination.todo = selectedTodo
               }
           }
           
           if let destination = segue.destination as? MoveTodoViewController {
                   destination.selectedTodo = todoToMove
           }
           
       }
    
    
        @IBAction func unwindToTaskListView(_ unwindSegue: UIStoryboardSegue) {
            saveTodos()
            loadTodos()
            tableView.reloadData()
        }
        
}

//MARK: implement core data methods
extension TaskListViewController {
    
    func loadTodos(with request: NSFetchRequest<Todo> = Todo.fetchRequest(), predicate: NSPredicate? = nil) {
        
        let sortOptions = ["date", "name"]
        let todoPredicate = NSPredicate(format: "parentFolder.name=%@", selectedCategory!.name!)
        request.sortDescriptors = [NSSortDescriptor(key: sortOptions[selectedSort], ascending: true)]
        if let addtionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [todoPredicate, addtionalPredicate])
        } else {
            request.predicate = todoPredicate
        }
        
        do {
            tasksArray = try todoListContext.fetch(request)
        } catch {
            print("Error loading todos \(error.localizedDescription)")
        }
        
    }
    
    func deleteTodoFromList() {
        
        todoListContext.delete(selectedTodo!)
        tasksArray.removeAll { (Todo) -> Bool in
            Todo == selectedTodo!
        }
        tableView.reloadData()
        
    }
    
    
    func saveTodos() {
        do {
            try todoListContext.save()
        } catch {
            print("Error saving the context \(error.localizedDescription)")
        }
    }
    
    func updateTodo() {
        saveTodos()
        tableView.reloadData()
    }
    
    
//    sends the todos to archived folder if saved
    func markTodoCompleted() {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        let folderPredicate = NSPredicate(format: "name MATCHES %@", "Archived")
        request.predicate = folderPredicate
        do {
            let category = try context.fetch(request)
            self.selectedTodo?.parentFolder = category.first
            saveTodos()
            tasksArray.removeAll { (Todo) -> Bool in
                Todo == selectedTodo!
            }
            tableView.reloadData()
        } catch {
            print("Error fetching data \(error.localizedDescription)")
        }
        
    }
    
    func saveTodo(title: String, dueDate: Date)
    {
        let todo = Todo(context: todoListContext)
        todo.name = title
        todo.due_date = dueDate
        todo.date = Date()
        todo.parentFolder = selectedCategory
        saveTodos()
        tasksArray.append(todo)
        tableView.reloadData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        selectedTodo = nil
    }
    
}


extension TaskListViewController: UITableViewDelegate, UITableViewDataSource {
    //    MARK: does inital table view setup
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        //        setup for auto size of cell
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todoCell", for: indexPath)
        let task = tasksArray[indexPath.row]
        cell.textLabel?.text = task.name
//        sets color of missed tasks in categories except Archived
        if (task.due_date! < Date() && task.parentFolder?.name != "Archived") {
            cell.backgroundColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        }
//        sets color of due tasks in categories except Archived
        if (Calendar.current.isDateInToday(task.due_date!) && task.parentFolder?.name != "Archived") {
            cell.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
            
            self.todoListContext.delete(self.tasksArray[indexPath.row])
            self.tasksArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completion(true)
        }
        
        delete.backgroundColor = #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)
        delete.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let complete = UIContextualAction(style: .normal, title: "Completed") { (action, view, completion) in
            self.selectedTodo = self.tasksArray[indexPath.row]
            self.markTodoCompleted()
        }
        let move = UIContextualAction(style: .normal, title: "Move") { (action, view, completion) in
            self.todoToMove.append(self.tasksArray[indexPath.row])
            self.performSegue(withIdentifier: "moveTodoScreen", sender: nil)
        }
        complete.image = UIImage(systemName: "checkmark.fill")
        move.image = UIImage(systemName: "folder.fill")
        return UISwipeActionsConfiguration(actions: [complete, move])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTodo = tasksArray[indexPath.row]
        performSegue(withIdentifier: "todoViewScreen", sender: self)
    }
}


//MARK: implemenets search bar methods
extension TaskListViewController: UISearchBarDelegate {
    
    func showSearchBar() {
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Folder"
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.searchBar.searchTextField.textColor = .white
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
                
        let predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchBar.text!)
        loadTodos(predicate: predicate)
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadTodos()

            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }

        }
        loadTodos()
        tableView.reloadData()
    }
    
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        loadTodos()
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
}
