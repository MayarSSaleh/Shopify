//
//  SearchViewController.swift
//  Shopify
//
//  Created by mayar on 06/06/2024.
//

import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout , CustomCategoriesCellDelegate {

    var settingsViewModel = SettingsViewModel()

    var comeFromHome : Bool? = true
    var products: [Product] = []
    var filteredProducts: [Product] = []
    var isSearching = false
    
    var searchViewModel = SearchViewModel()
    var searchCollectionView: UICollectionView!

    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        setUpUi()
        loadProducts()
    }
    
    func setUpUi(){
        let layout = UICollectionViewFlowLayout()
        searchCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.addSubview(searchCollectionView)
        searchCollectionView.translatesAutoresizingMaskIntoConstraints = false
        searchCollectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10).isActive = true
        searchCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        searchCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        searchCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        searchCollectionView.backgroundColor = UIColor.clear
        searchCollectionView.dataSource = self
        searchCollectionView.delegate = self
        searchCollectionView.register(CustomCategoriesCell.self, forCellWithReuseIdentifier: "CustomCategoriesCell")
               
    }
    
    func loadProducts() {
        if comeFromHome ?? false {
            searchViewModel.bindResultToViewController = { [weak self] in
                DispatchQueue.main.async {
                    self?.products = self?.searchViewModel.products ?? []
                    self?.searchCollectionView.reloadData()
                }
            }
            searchViewModel.getProducts()
        }
        searchCollectionView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredProducts = products
        } else {
            isSearching = true
             filteredProducts = products.filter { product in
                product.name.lowercased().contains(searchText.lowercased())
            }

        }
        searchCollectionView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        filteredProducts = products
        searchCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearching ? filteredProducts.count : products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCategoriesCell", for: indexPath) as! CustomCategoriesCell
        
         let product = isSearching ? filteredProducts[indexPath.row] : products[indexPath.row]
            cell.nameCategoriesLabel.text = product.name
            
            if let selectedCurrency = settingsViewModel.getSelectedCurrency(),
               let convertedPrice = settingsViewModel.convertPrice(product.variants.first?.price ?? "N/A", to: selectedCurrency) {
                cell.priceLabel.text = convertedPrice
            } else {
                cell.priceLabel.text = product.variants.first?.price
            }
            
            if let imageUrlString = product.images.first?.url, let imageUrl = URL(string: imageUrlString) {
                cell.categoriesImgView.kf.setImage(with: imageUrl)
            } else {
                cell.categoriesImgView.image = UIImage(named: "splash-img.jpg")
            }
            
            if product.variants[0].isSelected {
                print("is fav ")
                cell.heartButton.setImage(UIImage(systemName: "suit.heart.fill"), for: .normal)
            } else {
                print("is not fav")
                cell.heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
            }
            cell.heartButton.tag = indexPath.row
            cell.delegate = self
                    
        return cell
    }
    
    
    func didTapHeartButton(in cell: CustomCategoriesCell) {
        var productViewModel = ProductViewModel()
        if let indexPath = searchCollectionView.indexPath(for: cell) {
              let product = isSearching ? filteredProducts[indexPath.row] : products[indexPath.row]
              
            if Authorize.isRegistedCustomer() {
                cell.heartButton.isEnabled = false
                
                if product.variants[0].id != fakeProductInDraftOrder {
                    // deafult now if false
                    if product.variants[0].isSelected {
                        // Remove from fav
                        showAlertWithTwoOption(message: "Are you sure you want to remove from favorites?",
                                               okAction: { [weak self] _ in
                            print("OK button remove tapped")
                            productViewModel.removeFromFavDraftOrders(VariantsId: product.variants[0].id) { isSuccess in
                                DispatchQueue.main.async {
                                    if isSuccess {
                                        product.variants[0].isSelected = false
                                        cell.heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
                                        cell.heartButton.isEnabled = true
                                        print("remove succeful")
                                    } else {
                                        self?.showAlertWithTwoOption(message: "Failed to remove from favorites")
                                        cell.heartButton.isEnabled = true
                                    }
                                }
                            }
                            
                        }, cancelAction: { _ in
                            cell.heartButton.isEnabled = true
                        }
                        )
                    } else {
                        // Add to fav
                        productViewModel.addToFavDraftOrders(selectedVariantsData: [(product.variants[0].id, product.images.first?.url ?? "", 1)]) { [weak self] isSuccess in
                            DispatchQueue.main.async {
                                if isSuccess {
                                    cell.heartButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                                    cell.heartButton.isEnabled = true
                                    print("added succesfully ")
                                    product.variants[0].isSelected = true
                                    self?.showCheckMarkAnimation(mark: "heart.fill")
                                    
                                } else {
                                    self?.showAlertWithTwoOption(message: "Failed to add to favorites")
                                    cell.heartButton.isEnabled = true
                                }
                            }
                        }
                    }}else {
                        showAlert(message: "Sorry ,failed to handle favourite status of this product...check another products")

                    }
            } else {
                showAlertWithTwoOptionOkayAndCancel(message: "Login to add to favorites?",
                                       okAction: {  _ in
                    Navigation.ToALogin(from: self)
                    print("Login OK button tapped")
                })
            }
        }
    }
    private func showAlert(message: String, action: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: action)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func showAlertWithTwoOption(message: String, okAction: ((UIAlertAction) -> Void)? = nil, cancelAction: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let okAlertAction = UIAlertAction(title: "Delete", style: .destructive, handler: okAction)
        alertController.addAction(okAlertAction)
        
        if let cancelAction = cancelAction {
            let cancelAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelAction)
            alertController.addAction(cancelAlertAction)
        }
        
        present(alertController, animated: true, completion: nil)
    }
    private func showAlertWithTwoOptionOkayAndCancel(message: String, okAction: ((UIAlertAction) -> Void)? = nil, cancelAction: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let okAlertAction = UIAlertAction(title: "Okay", style: .default, handler: okAction)
        let cancelAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelAction)
        
        alertController.addAction(okAlertAction)
        alertController.addAction(cancelAlertAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width / 2 - 20 , height: 260)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = isSearching ? filteredProducts[indexPath.row] : products[indexPath.row]
        Navigation.ToProduct(productId: "\(product.id)", from: self)
    }

}
