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
        
//        let person = Person(dict: ["name": "li", "age": 35])
//        person.insertQueuePerson()
        
        let start = CFAbsoluteTimeGetCurrent()
        let manager = SQLiteManager.shareManager()
        
        //开启事务
        manager.beginTransaction()
        
        for i in 0..<10000
        {
            let person = Person(dict: ["name": "li + \(i)", "age": 20 + i])
            person.insertPerson()
            
            
            if i == 1000
            {
                manager.rollbackTransaction()
                // 注意点: 回滚之后一定要跳出循环停止更新
                break
            }
        }
        //提交事务
        manager.commitTransaction()
        
        print("耗时 = \(CFAbsoluteTimeGetCurrent() - start)")
        
        
    }
}

