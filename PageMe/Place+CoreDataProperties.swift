//
//  Place+CoreDataProperties.swift
//  PageMe
//
//  Created by Yuna Kim on 5/15/21.
//
//

import Foundation
import CoreData


extension Place {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Place> {
        return NSFetchRequest<Place>(entityName: "Place")
    }

    @NSManaged public var name: String
    @NSManaged public var woeID: Int32

}

extension Place : Identifiable {

}
