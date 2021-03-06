//
//  SQLiteManager.swift
//  SQLite
//
//  Created by paomoliu on 16/9/5.
//  Copyright © 2016年 Sunshine Girl. All rights reserved.
//

import UIKit

class SQLiteManager: NSObject
{
    private static let manager: SQLiteManager = SQLiteManager()
    
    class func shareManager() -> SQLiteManager
    {
        return manager
    }
    
    //数据库对象
    private var db: COpaquePointer = nil
    
    //创建一个串行队列
    private let dbQueue = dispatch_queue_create("paomoliu", DISPATCH_QUEUE_SERIAL)
    
    /*
    插入一条记录
    解决插入很多条记录第一种方法，一定要创建串行队列，在一个子线程中执行，以为sqlite数据库就是一个文件
    对文件的操作如果在多个子线程中并行插入，就会造成混乱
    */
    func insertQueueSQL(action: (manager: SQLiteManager)->())
    {
        //开启一个子线程
        dispatch_async(dbQueue) { () -> Void in
            //执行闭包
            action(manager: self)
        }
    }
    
    // MARK: - 事务相关
    
    /*
    解决插入多条数据性能提升第二种方法
    每一次在调用execSQL执行SQL语句的时候都会自己默认做开启事务，提交事务，或回滚事务的处理，要插入10000条数据，就会做10000次这样的操作
    所以可以在插入数据之前开启事务，当开启事务之后，就不会在插入的时候再开启事务了，整个过程只进行一次开启事务，提交事务或回滚事务
    */
    
    //1.开启事务
    func beginTransaction()
    {
        execSQL("BEGIN TRANSACTION")
    }
    
    //2.提交事务
    func commitTransaction()
    {
        execSQL("COMMIT TRANSACTION")
    }
    
    //3.回滚
    func rollbackTransaction()
    {
        execSQL("ROLLBACK TRANSACTION")
    }
    
    // MARK: - 预编译
    
    /// 自定义一个SQLITE_TRANSIENT, 覆盖系统的
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)
    
    /**
     通过预编译SQL语句来提升性能第三种方法
     
     - parameter sql:  要执行的SQL语句
     - parameter args: 接收多个参数
     */
    func batchExecSQL(sql: String, args: CVarArgType...)
    {
        //数组
//        print(args)
        
        //将Swift字符串转为C语言字符串
        let cSQL = sql.cStringUsingEncoding(NSUTF8StringEncoding)!
        
        //预编译SQL语句
        var stmt: COpaquePointer = nil
        if sqlite3_prepare_v2(db, cSQL, -1, &stmt, nil) != SQLITE_OK
        {
            print("预编译失败")
            sqlite3_finalize(stmt)
            return
        }
        
        //绑定数据
        //index要从1开始，因为0是id
        var index: Int32 = 1
        for objc in args
        {
            if objc is Int
            {
//                print("通过int方法绑定数据 \(objc)")
                // 第二个参数就是SQL中('?', ?)的位置
                sqlite3_bind_int64(stmt, index, sqlite3_int64(objc as! Int))
            } else if objc is Double
            {
//                print("通过Double方法绑定数据 \(objc)")
                sqlite3_bind_double(stmt, index, objc as! Double)
            } else if objc is String
            {
//                print("通过Text方法绑定数据 \(objc)")
                
                // 第三个参数: 需要绑定的字符串, C语言
                // 第四个参数: 第三个参数的长度, 传入-1系统自动计算
                // 第五个参数: OC中直接传nil, 但是Swift传入nil会有大问题
                /*
                typedef void (*sqlite3_destructor_type)(void*);
                
                #define SQLITE_STATIC      ((sqlite3_destructor_type)0)
                #define SQLITE_TRANSIENT   ((sqlite3_destructor_type)-1)
                
                第五个参数如果传入SQLITE_STATIC/nil, 那么系统不会保存需要绑定的数据, 如果需要绑定的数据提前释放了, 那么系统就随便绑定一个值
                第五个参数如果传入SQLITE_TRANSIENT, 那么系统会对需要绑定的值进行一次copy, 直到绑定成功之后再释放
                */
                
                let text = objc as! String
                let cText = text.cStringUsingEncoding(NSUTF8StringEncoding)!
                sqlite3_bind_text(stmt, index, cText, -1, SQLITE_TRANSIENT)
            } // if ... else if
            
            index++
        } // for
        
        //执行SQL语句
        if sqlite3_step(stmt) != SQLITE_DONE
        {
            print("执行SQL语句失败")
            sqlite3_finalize(stmt)
            return
        }
        
        //重置stmt
        if sqlite3_reset(stmt) != SQLITE_OK
        {
            print("重置失败")
            sqlite3_finalize(stmt)
            return
        }
        
        //关闭stmt
        sqlite3_finalize(stmt)
    } // func
    
    
    /**
     打开数据库
     
     :param: SQLiteName 数据库名称
     */
    func openDataBase(SQLiteName: String)
    {
        // 0.拿到数据库的路径
        let path = SQLiteName.docDir()
        print(path)
        let cPath = path.cStringUsingEncoding(NSUTF8StringEncoding)!
        
        // 1.打开数据库
        /*
        第一个参数：需要打开的数据库文件的路径, C语言字符串
        第二个参数：打开之后的数据库对象 (指针), 以后所有的数据库操作, 都必须要拿到这个指针才能进行相关操作
        */
        // open方法特点: 如果指定路径对应的数据库文件已经存在, 就会直接打开
        //              如果指定路径对应的数据库文件不存在, 就会创建一个新的
        if sqlite3_open(cPath, &db) != SQLITE_OK
        {
            print("打开数据库失败")
            
            return
        }
        
        if createDataBase()
        {
            print("创建表成功")
        } else
        {
            print("创建表失败")
        }
    }
    
    /**
     创建表
     
     - returns: 创建结果，true创建成功，反之失败
     */
    func createDataBase() -> Bool
    {
        let sql = "CREATE TABLE IF NOT EXISTS T_Person(" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                    "name TEXT NOT NULL," +
                    "age INTEGER" +
                    ");"
        
        //执行sql语句
        return execSQL(sql)
    }
    
    /**
     执行除查询以外的SQL语句
     
     - parameter sql: 需要执行的SQL语句
     
     - returns: 是否执行成功，true执行成功，反之不成功
     */
    func execSQL(sql: String) -> Bool
    {
        //将Swift字符串转为C语言字符串
        let cSQL = sql.cStringUsingEncoding(NSUTF8StringEncoding)!
        
        /*
        在SQLite3中, 除了查询以外(创建/删除/新增/更新)都使用同一个函数
        第一个参数：已经打开的数据库对象
        第二个参数：需要执行的SQL语句, C语言字符串
        第三个参数：执行SQL语句之后的回调, 一般传nil
        第四个参数：是第三个参数的第一个参数, 一般传nil
        第五个参数：错误信息, 一般传nil
        */
        if sqlite3_exec(db, cSQL, nil, nil, nil) != SQLITE_OK
        {
            return false
        }
        
        return true
    }
    
    /**
     获取查询的所有数据
     
     - parameter sql: 需要执行的SQL语句
     
     - returns: 查询到的字典数组
     */
    func exexQuerySQL(sql: String) -> [[String: AnyObject]]
    {
        let cSQL = sql.cStringUsingEncoding(NSUTF8StringEncoding)!
        
        /*
        准备数据
        准备：理解为预编译SQL语句，检测里面的SQL是否有错误等等，它可以提高性能
        第一个参数：已经打开的数据库对象
        第二个参数：需要执行的SQL语句, C语言字符串
        第三个参数：需要执行的SQL语句的长度，传入－1系统自动计算
        第四个参数：预编译之后的句柄，若想取出数据，就需要这个句柄
        第五个参数：一般传nil
        */
        var stmt: COpaquePointer = nil
        if sqlite3_prepare_v2(db, cSQL, -1, &stmt, nil) != SQLITE_OK
        {
            print("准备失败")
        }
        
        //准备成功
        //查询数据
        //sqlite3_step代表取出一条数据，如果取到了数据就会返回SQLITE_ROW
        var records = [[String: AnyObject]]()
        while sqlite3_step(stmt) == SQLITE_ROW
        {
            //获取一条查询记录的值
            let record = recordWithStmt(stmt)
            //将当前获取到的这一条记录添加到数组中
            records.append(record)
        } //while
        
        return records
    } //func
    
    /**
    获取一条查询记录的值
    
    - parameter stmt: 预编译好的SQL语句
    
    - returns: 数据字典
    */
    private func recordWithStmt(stmt: COpaquePointer) -> [String: AnyObject]
    {
        //拿到当前这条数据所有的列
        let count = sqlite3_column_count(stmt)
        
        var record = [String: AnyObject]()
        for index in 0..<count
        {
            //拿到每一列名称
            let cName = sqlite3_column_name(stmt, index)
            let name = String(CString: cName, encoding: NSUTF8StringEncoding)!
            
            //拿到每一列的类型
            let type = sqlite3_column_type(stmt, index)
            
            //根据类型执行相关的语句取出列名对应的列值
            switch(type) {
            case SQLITE_INTEGER:
                //整型
                let num = sqlite3_column_int64(stmt, index)
                record[name] = Int(num)
            case SQLITE_FLOAT:
                //浮点型
                let double = sqlite3_column_double(stmt, index)
                record[name] = Double(double)
            case SQLITE3_TEXT:
                let cText = UnsafePointer<Int8>(sqlite3_column_text(stmt, index))
                let text = String(CString: cText, encoding: NSUTF8StringEncoding)!
                record[name] = text
                //文本类型
            case SQLITE_NULL:
                //空类型
                record[name] = NSNull()
            default :
                //二进制类型 SQLITE_BLOB
                //一般情况下，不会往数据库中存储二进制数据
                print("")
            } //switch
        } //for
        
        return record
    } // func
}
