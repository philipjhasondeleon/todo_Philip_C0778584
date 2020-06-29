//
//  ViewController.swift
//  todo_Philip_C0778584
//
//  Created by user175490 on 6/28/20.
//  Copyright © 2020 user175490. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var categoryContext: NSManagedObjectContext!
    var notificationArray = [Todo]()
    
    var categoryName = UITextField()
    var categoryArray: [Category] = [Category]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        initializeCoreData()
        setUpTableView()
        firstTimeSetup()
        setUpNotifications()
    }

    @IBAction func addCategory(_ sender: Any) {
        
        let alert = UIAlertController(title: "Add a category", message: "", preferredStyle: .alert)
        alert.addTextField(configurationHandler: addCategoryName(textField:))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (action) in
            if(self.categoryName.text!.count < 1) {
                self.emptyFieldAlert()
                return
            }
            else {
                self.addNewCategory()
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)

    }

    func emptyFieldAlert() {
            
            let alert = UIAlertController(title: "Oops!", message: "Field can't be Empty", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
        
        func addCategoryName(textField: UITextField) {
            
            self.categoryName = textField
            self.categoryName.placeholder = "Enter Category Name"
            
        }

    }



    //MARK: core data methods implemented
    extension ViewController {
        
        
        func initializeCoreData() {
            print("initialized")
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            categoryContext = appDelegate.persistentContainer.viewContext
            
            fetchCategoryData()
            
        }
        
    //    Initializes a default archived folder
        func firstTimeSetup() {
            let categoryNames = self.categoryArray.map {$0.name}
            guard !categoryNames.contains("Archived") else {return}
            let newCategory = Category(context: self.categoryContext)
            newCategory.name = "Archived"
            self.categoryArray.append(newCategory)
            do {
                try categoryContext.save()
                tableView.reloadData()
            } catch {
                print("Error saving categories \(error.localizedDescription)")
            }
        }
        
        
        func fetchCategoryData() {
    //        request
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
    //        initialize
            request.sortDescriptors = [sortDescriptor]
            do {
                categoryArray = try categoryContext.fetch(request)
            } catch {
                print("Error loading categories: \(error.localizedDescription)")
            }
    //        data fetched
            tableView.reloadData()
            
        }
        
        func addNewCategory() {
            
            let categoryNames = self.categoryArray.map {$0.name}
            guard !categoryNames.contains(categoryName.text) else {self.showAlert(); return}
            let newCategory = Category(context: self.categoryContext)
            newCategory.name = categoryName.text!
            self.categoryArray.append(newCategory)
            do {
                try categoryContext.save()
                tableView.reloadData()
            } catch {
                print("Error saving categories \(error.localizedDescription)")
            }
            
        }
        
    //    to be shown if user enters existing category name
        func showAlert() {
            let alert = UIAlertController(title: "Category name already Exists!", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)

        }
        
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            let destination = segue.destination as! TaskListViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                destination.selectedCategory = categoryArray[indexPath.row]
            }
        }
        
    }




    //MARK: implements table view methods
    extension ViewController: UITableViewDelegate, UITableViewDataSource {
        
    //    MARK: does inital table view setup
        func setUpTableView() {
            tableView.delegate = self
            tableView.dataSource = self
    //        setup for auto size of cell
            tableView.estimatedRowHeight = 44
            tableView.rowHeight = UITableView.automaticDimension
        }
            
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return categoryArray.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
            let category = categoryArray[indexPath.row]
    //        sets different color for archived category
            if category.name == "Archived" {
                cell.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            }
            cell.textLabel?.text = category.name
            
            return cell
        }
        
        func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
                
                    self.categoryContext.delete(self.categoryArray[indexPath.row])
                    self.categoryArray.remove(at: indexPath.row)
                    do {
                        try self.categoryContext.save()
                    } catch {
                        print("Error saving the context \(error.localizedDescription)")
                    }
                    
                    //        reloads data
                    self.tableView.reloadData()
                    completion(true)
            }
            
            delete.backgroundColor = #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)
            delete.image = UIImage(systemName: "trash.fill")
            return UISwipeActionsConfiguration(actions: [delete])
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            performSegue(withIdentifier: "noteListScreen", sender: self)
        }
    }




    //MARK: implements notification center methods
    extension ViewController {
        
    //    sets up notifications for the tasks
        func setUpNotifications() {
            
            checkDueTasks()
            if notificationArray.count > 0 {
                for task in notificationArray {
                    
                    if let name = task.name {
                        let notificationCenter = UNUserNotificationCenter.current()
                        let notificationContent = UNMutableNotificationContent()
                        
                        notificationContent.title = "Task Reminder"
                        notificationContent.body = "This message is to remind that \(name) is due tommorow"
                        notificationContent.sound = .default
    //                    sets up notification for a day before the task
                        let fromDate = Calendar.current.date(byAdding: .day, value: -1, to: task.due_date!)!
                        let components = Calendar.current.dateComponents([.month, .day, .year], from: fromDate)
                        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                        let request = UNNotificationRequest(identifier: "\(name)taskid", content: notificationContent, trigger: trigger)
                        notificationCenter.add(request) { (error) in
                            if error != nil {
                                print(error ?? "notification center error")
                            }
                        }
                    }
                }
            }
            
        }
        
    //    fetches the list of due tasks
        func checkDueTasks() {
            
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let request: NSFetchRequest<Todo> = Todo.fetchRequest()
            do {
                let notifications = try context.fetch(request)
                for task in notifications {
                    if Calendar.current.isDateInTomorrow(task.due_date!) {
                        notificationArray.append(task)
                    }
                }
            } catch {
                print("Error loading todos \(error.localizedDescription)")
            }
            
        }
        
    }
