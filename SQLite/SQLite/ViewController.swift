//
//  ViewController.swift
//  SQLite
//
//  Created by paomoliu on 16/9/5.
//  Copyright © 2016年 Sunshine Girl. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let person = Person(dict: ["name": "li", "age": 35])
//        print(person.insertPerson())
//        print(p.updatePerson("ww"))
//        print(p.deletePerson())
//        print(Person.loadPerson())
        
//        let start = CFAbsoluteTimeGetCurrent()
//        for i in 0..<10000
//        {
//            let person = Person(dict: ["name": "li + \(i)", "age": 20 + i])
//            person.insertPerson()
//        }
//        print("耗时 = \(CFAbsoluteTimeGetCurrent() - start)")
        
        let person = Person(dict: ["name": "li", "age": 35])
        person.insertQueuePerson()
    }
}

