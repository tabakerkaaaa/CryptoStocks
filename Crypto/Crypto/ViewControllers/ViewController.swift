//
//  ViewController.swift
//  Crypto
//
//  Created by Никита Бабенко on 11/02/2020.
//  Copyright © 2020 Nikita Babenko. All rights reserved.
//

import UIKit

struct CryptoInfo: Codable {
    var symbol: String
    var last: String?
    var volume: String
    var low: String?
    var high: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol = "symbol"
        case last = "last"
        case volume = "volume"
        case low = "low"
        case high = "high"
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var noInternetLabel: UILabel!

    @IBOutlet weak var refreshButton: UIButton!
    
    var activityIndicator: UIActivityIndicatorView?
    
    private let refreshControl = UIRefreshControl()
    
    var searchController : UISearchController?
    private var isSearchBarEmpty: Bool {
        return searchController?.searchBar.text?.isEmpty ?? true
    }
    private var isSearching: Bool {
        return (searchController?.isActive ?? false) && !isSearchBarEmpty
    }
    
    var cryptoViewController: CryptoViewController?
    
    private let cellId = "CryptoCell"
    private let apiURL = "https://api.hitbtc.com/api/2/public/ticker/"
    
    private var cryptoArray: [CryptoInfo] = []
    private var filteredCryptoArray: [CryptoInfo] = []
    private var searchedCryptoArray: [CryptoInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: cellId, bundle: nil), forCellReuseIdentifier: cellId)
        tableView.isHidden = true
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshCryptoInfo(_:)), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Crypto Data...")
        
        noInternetLabel.isHidden = true
        refreshButton.isHidden = true
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator!.center = self.view.center
        activityIndicator!.hidesWhenStopped = true
        self.view.addSubview(activityIndicator!)
        activityIndicator!.startAnimating()
        
        getData { [unowned self] cryptoArray in
            self.cryptoArray = cryptoArray as! [CryptoInfo]
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating()
                self.tableView.isHidden = false
                self.indexChange(self.segmentedControl!)
            }
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "CryptoViewController") as? CryptoViewController else {return}
        cryptoViewController = controller
        
        let singleCrypto: CryptoInfo = isSearching
                                     ? self.searchedCryptoArray[indexPath.row]
                                     : self.filteredCryptoArray[indexPath.row]
        
        cryptoViewController?.title = insertSlash(singleCrypto.symbol)
        cryptoViewController?.exactCrypto = singleCrypto
        
        self.navigationController?.pushViewController(self.cryptoViewController!, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchedCryptoArray.count : filteredCryptoArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as?
            CryptoCell else {
                fatalError("The dequeued cell is not an instance of CryptoCell.")
        }
        
        let singleCrypto: CryptoInfo = isSearching
                                     ? self.searchedCryptoArray[indexPath.row]
                                     : self.filteredCryptoArray[indexPath.row]
 
        cell.priceLabel.text = singleCrypto.last ?? "Unknown"
        cell.priceLabel.textColor = .gray
        
        cell.symbolLabel.text = insertSlash(singleCrypto.symbol)
        cell.volumeLabel.text = "Vol 24 " + singleCrypto.volume + " USD"
        cell.volumeLabel.textColor = .gray
        
        return cell
    }
}

extension ViewController:  UISearchControllerDelegate, UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController?.searchBar.isHidden = true
        searchController?.isActive = false
        navigationItem.searchController = nil
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
        self.indexChange(self.segmentedControl!)
        searchButton.isHidden = false
    }
}

extension ViewController:  UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
}

extension ViewController {
    @IBAction func refreshActionByButton(_ sender: UIButton) {
        callRefresh()
    }
    
    @IBAction func indexChange(_ sender: Any) {
        filteredCryptoArray = cryptoArray.filter { (singleCrypto: CryptoInfo) -> Bool in
            return singleCrypto.symbol.hasPrefix(segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)!) ||
                   singleCrypto.symbol.hasSuffix(segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)!)
        }
        
        if isSearching {
            let searchBar = searchController!.searchBar
            filterContentForSearchText(searchBar.text!)
        }
        
        tableView.reloadData()
    }
    
    @IBAction func searchingButton(_ sender: Any) {
        searchController = UISearchController(searchResultsController: nil)
        searchController!.delegate = self
        searchController!.searchBar.delegate = self
        searchController!.searchBar.showsCancelButton = true
        searchController!.searchBar.placeholder = "All Currency Pairs"
        searchController!.hidesNavigationBarDuringPresentation = false
        searchController!.obscuresBackgroundDuringPresentation = false
        searchController!.searchResultsUpdater = self
        definesPresentationContext = true
        navigationItem.searchController = self.searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchButton.isHidden = true
        
        present(searchController!, animated: true, completion: nil)
    }
    
    @objc private func refreshCryptoInfo(_ sender: Any) {
        callRefresh()
    }
}

extension ViewController {
    private func filterContentForSearchText(_ searchText: String) {
        searchedCryptoArray = filteredCryptoArray.filter { (singleCrypto: CryptoInfo) -> Bool in
            return singleCrypto.symbol.lowercased().contains(searchText.lowercased())
        }
    
        tableView.reloadData()
    }
    
    private func insertSlash(_ symbol: String) -> String {
        var newSymbol = symbol
        
        let currentCrypto = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)!
        if newSymbol.hasPrefix(currentCrypto) {
            newSymbol.insert("/", at: newSymbol.index(newSymbol.startIndex, offsetBy: currentCrypto.count))
        } else if newSymbol.hasSuffix(currentCrypto) {
            newSymbol.insert("/", at: newSymbol.index(newSymbol.endIndex, offsetBy: -currentCrypto.count))
        }
        
        return newSymbol
    }
    
    private func callRefresh() {
        getData { [unowned self] cryptoArray in
            self.cryptoArray = cryptoArray as! [CryptoInfo]
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.noInternetLabel.isHidden = true
                self.refreshButton.isHidden = true
                self.tableView.isHidden = false
                self.indexChange(self.segmentedControl!)
            }
        }
    }
}

extension ViewController: NetworkingProtocol {
    internal func getData(completionHandler: @escaping ([Any]) -> ()) {
        if let url = URL(string: apiURL) {
            URLSession.shared.dataTask(with: url) { [unowned self] data, response, error in
                if let data = data {
                    do {
                        let readData = try JSONDecoder().decode([CryptoInfo].self, from: data)
                        completionHandler(readData)
                    } catch let error {
                        self.showError()
                        print(error.localizedDescription)
                    }
                }
                if let error = error {
                    self.showError()
                    print(error.localizedDescription)
                }
            }.resume()
        }
    }
    
    internal func showError() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator?.stopAnimating()
            self?.tableView.isHidden = true
            self?.noInternetLabel.isHidden = false
            self?.refreshButton.isHidden = false
        }
    }
}


