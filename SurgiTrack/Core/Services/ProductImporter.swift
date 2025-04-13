//
//  ProductImporter.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 14/03/25.
//


import Foundation
import CoreData

class ProductImporter {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// Checks if any products already exist; if not, imports from Products.txt.
    func importProductsIfNeeded() {
        let request: NSFetchRequest<Product> = Product.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            if count > 0 {
                // Products already imported
                return
            }
        } catch {
            print("Error counting products: \(error)")
        }
        
        guard let fileURL = Bundle.main.url(forResource: "Products", withExtension: "txt") else {
            print("Products.txt not found in bundle")
            return
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            var lines = content.components(separatedBy: .newlines)
            // Assume the first line is the header; remove it.
            guard !lines.isEmpty else { return }
            lines.removeFirst()
            
            for line in lines where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let columns = line.components(separatedBy: "\t")
                // Ensure we have at least 8 columns.
                if columns.count >= 8 {
                    let product = Product(context: context)
                    product.applNo = columns[0]
                    product.productNo = columns[1]
                    product.form = columns[2]
                    product.strength = columns[3]
                    product.referenceDrug = columns[4]
                    product.drugName = columns[5]
                    product.activeIngredient = columns[6]
                    product.referenceStandard = columns[7]
                }
            }
            try context.save()
            print("Imported \(lines.count) products")
        } catch {
            print("Error importing products: \(error)")
        }
    }
}
