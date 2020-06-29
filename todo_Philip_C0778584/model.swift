//
//  model.swift
//  todo_Philip_C0778584
//
//  Created by user175490 on 6/29/20.
//  Copyright © 2020 user175490. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class MyList:NSManagedObject
{
    @NSManaged var task: String?
    @NSManaged var priority:String?
    @NSManaged var color: UIColor
    @NSManaged var order: Int16
    
}
