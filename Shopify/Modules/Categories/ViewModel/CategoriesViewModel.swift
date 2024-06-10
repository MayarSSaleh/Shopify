//
//  CategoriesViewModel.swift
//  Shopify
//
//  Created by Rawan Elsayed on 10/06/2024.
//

import Foundation

class CategoriesViewModel{
    
    var categoryProducts: [CategoryProducts] = []
    var allProducts: [Product] = []

    func fetchCategoryProducts(_ categoryId: CategoryId ,completion: @escaping (Error?) -> Void) {
           
        let categoryId = categoryId.id
           
           let additionalParams = "\(categoryId)/products.json"
        
        let urlString = "https://\(API_KEY):\(TOKEN)\(baseUrl)\(Endpoint.productsByCategory.rawValue)\(additionalParams)"
            print("Request URL: \(urlString)")

           
           NetworkManager.fetchDataFromApi(endpoint: .productsByCategory, rootOfJson:.products, addition: additionalParams) { data, error in
               guard let data = data, error == nil else {
                   completion(error)
                   return
               }
               
               Decoding.decodeData(data: data, objectType: [CategoryProducts].self) { [weak self] (products, decodeError) in
                   guard let self = self else { return }
                   if let products = products {
                       self.categoryProducts = products
                       completion(nil)
                   } else if let decodeError = decodeError {
                       completion(decodeError)
                   } else {
                       completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                   }
               }
           }
       }
   
    func numberOfCategoryProducts() -> Int {
        return categoryProducts.count
    }

    func product(at index: Int) -> CategoryProducts? {
        guard index >= 0 && index < categoryProducts.count else {
            return nil
        }
        return categoryProducts[index]
    }

    func fetchAllProducts(completion: @escaping (Error?) -> Void) {
           
        NetworkManager.fetchDataFromApi(endpoint: .allProduct, rootOfJson:.products) { data, error in
            guard let data = data, error == nil else {
                completion(error)
                return
            }
            
            Decoding.decodeData(data: data, objectType: [Product].self) { [weak self] (allProducts, decodeError) in
                guard let self = self else { return }
                if let allProducts = allProducts {
                    self.allProducts = allProducts
                    completion(nil)
                } else if let decodeError = decodeError {
                    completion(decodeError)
                } else {
                    completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                }
            }
        }
    }
   
    func numberOfAllProducts() -> Int {
        return allProducts.count
    }

    func allProducts(at index: Int) -> Product? {
        guard index >= 0 && index < allProducts.count else { return nil }
        return allProducts[index]
    }
    
    func findProductInAllProducts(by id: String) -> Product? {
        return allProducts.first { "\($0.id)" == id }
    }

}

enum CategoryId: Int {
    case men = 429707493624
    case women = 429707526392
    case kids = 429707559160
    case sale = 429707591928
    
    var id: Int {
        return self.rawValue
    }
}
