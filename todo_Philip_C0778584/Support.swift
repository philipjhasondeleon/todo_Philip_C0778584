//
//  Support.swift
//  todo_Philip_C0778584
//
//  Created by user175490 on 6/29/20.
//  Copyright © 2020 user175490. All rights reserved.
//

import Foundation
import CoreData
import UIKit

let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

func saveContext(){
    if context.hasChanges
    {
        do{
            try context.save()
        }
        catch
        {
            print(error)
        }
    }
    
}
