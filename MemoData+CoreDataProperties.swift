//
//  MemoData+CoreDataProperties.swift
//  EveryDayMemo
//
//  Created by 加藤周 on 2021/08/28.
//
//

import Foundation
import CoreData


extension MemoData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemoData> {
        return NSFetchRequest<MemoData>(entityName: "MemoData")
    }

    @NSManaged public var memoDate: String?
    @NSManaged public var memoText: String?

}

extension MemoData : Identifiable {

}
