/**
 * Copyright (c) 2016 Ivan Magda
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import CoreData

// MARK: Constants

let kPersistenceCentralDidChangeContentNotification = "PersistenceCentralDidChangeContent"
private let kSeedInitialDataKey = "initialDataSeeded"

// MARK: - PersistenceCentral: NSObject

class PersistenceCentral: NSObject {
    
    // MARK: Properties
    
    static let sharedInstance = PersistenceCentral()
    let coreDataStackManager = CoreDataStackManager.sharedInstance
    
    private (set) var trendingCategories: [Category]!
    private (set) var categories: [Category]!
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: Category.type)
        request.sortDescriptors = [
            NSSortDescriptor(key: Category.Key.Trending.rawValue, ascending: true),
            NSSortDescriptor(key: Category.Key.Name.rawValue, ascending: true,
                selector: #selector(NSString.caseInsensitiveCompare(_:)))
        ]
        request.returnsObjectsAsFaults = false
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: self.coreDataStackManager.managedObjectContext,
            sectionNameKeyPath: Category.Key.Trending.rawValue,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    // MARK: Init
    
    private override init() {
        super.init()
        setup()
    }
    
    // MARK: - Private Methods -
    // MARK: Setup
    
    private func setup() {
        seedInitialDataIfNeeded()
        _ = try! fetchedResultsController.performFetch()
        updateCategories()
    }
    
    private func seedInitialDataIfNeeded() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        guard userDefaults.boolForKey(kSeedInitialDataKey) == false else { return }
        
        let context = coreDataStackManager.managedObjectContext
        
        let categories = [
            "sunset", "beach", "water", "sky", "dance", "red",
            "blue", "nature", "night", "vacation", "white", "green",
            "flowers", "portrait", "art", "light", "snow", "dog",
            "sun", "clouds", "cat", "park", "winter", "street",
            "landscape", "summer", "trees", "sea", "city", "yellow",
            "lake", "christmas", "family", "bridge", "people", "bird",
            "river", "pink", "house", "car", "food", "bw",
            "old", "macro", "new", "music", "garden", "orange",
            "me", "baby"
        ]
        categories.forEach { let _ = Category(name: $0, context: context) }
        
        let trending = ["now", "this week"]
        trending.forEach {
            let category = Category(name: $0, context: context)
            category.trending = true
        }
        coreDataStackManager.saveContext()
        
        userDefaults.setBool(true, forKey: kSeedInitialDataKey)
    }
    
    // MARK: - Convenience -
    // MARK: Category
    
    func deleteCategory(category: Category) {
        coreDataStackManager.managedObjectContext.deleteObject(category)
        coreDataStackManager.saveContext()
    }
    
    func deleteAllCategories() {
        categories.forEach { coreDataStackManager.managedObjectContext.deleteObject($0) }
        coreDataStackManager.saveContext()
    }
    
    func deleteAllTagsInCategory(category: Category) {
        category.deleteAllTags()
        coreDataStackManager.saveContext()
    }
    
    func saveCategoryWithName(name: String) {
        let _ = Category(name: name, context: coreDataStackManager.managedObjectContext)
        coreDataStackManager.saveContext()
    }
    
}

// MARK: - PersistenceCentral: NSFetchedResultsControllerDelegate -

extension PersistenceCentral: NSFetchedResultsControllerDelegate {
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        updateCategories()
        PersistenceCentral.postDidChangeContentNotification()
    }
    
    // MARK: Helpers
    
    private func updateCategories() {
        func objectsForSection(section: Int) -> [Category] {
            return fetchedResultsController.sections?[section].objects as? [Category] ?? [Category]()
        }
        categories = objectsForSection(0)
        trendingCategories = objectsForSection(1)
    }
    
    private class func postDidChangeContentNotification() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.postNotificationName(kPersistenceCentralDidChangeContentNotification, object: self)
    }
    
}
