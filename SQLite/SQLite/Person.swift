//
//  Person.swift
//  SQLite
//
//  Created by paomoliu on 16/9/5.
//  Copyright © 2016年 Sunshine Girl. All rights reserved.
//

import UIKit

class Person: NSObject
{
    var id: Int = 0
    var age: Int = 0
    var name: String?
    
    // MARK: - 执行数据源CRUD的操作
    
    /**
    查询数据
    
    - returns: 查询结果
    */
    class func loadPerson() -> [Person]
    {
        let sql = "SELECT * FROM T_Person;"
        let res = SQLiteManager.shareManager().exexQuerySQL(sql)
        
        var models = [Person]()
        for dict in res
        {
            models.append(Person(dict: dict))
        }
        
        return models
    }
    
    /*
    插入一条记录
    */
    func insertPerson() -> Bool
    {
        assert(name != nil, "必须要给name赋值")
        
        let sql = "INSERT INTO T_Person" +
                    "(name, age)" +
                    "VALUES" +
                    "('\(name!)', \(age));"
        
        return SQLiteManager.shareManager().execSQL(sql)
    }
    
    /*
    更新一条记录
    */
    func updataPerson(name: String) -> Bool
    {
        // 1.编写SQL语句
        let sql = "UPDATE T_Person SET name = '\(name)' WHERE age = \(self.age);"
        print(sql)
        // 2.执行SQL语句
        return SQLiteManager.shareManager().execSQL(sql)
    }
    
    /**
     删除记录
     */
    func deletePerson() -> Bool
    {
        // 1.编写SQL语句
        let sql = "DELETE FROM T_Person WHERE age IS \(self.age);"
        
        // 2.执行SQL语句
        return SQLiteManager.shareManager().execSQL(sql)
    }
    
    // MARK: - 系统内部方法
    
    init(dict: [String: AnyObject]) {
        super.init()
        setValuesForKeysWithDictionary(dict)
    }
    
    override func setValue(value: AnyObject?, forUndefinedKey key: String) {
        
    }
    
    override var description: String
        {
            return "id = \(id), age = \(age), name = \(name!)"
    }
}
