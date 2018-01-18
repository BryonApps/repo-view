//
//  SearchViewController.swift
//  RepoView
//
//  Created by Bryon Martin on 1/11/18.
//  Copyright © 2018 Bryon Martin. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var messageTitleLabel: UILabel!
    @IBOutlet weak var messageDescriptionLabel: UILabel!
    
    var userSearchString = ""
    var errorMessage = ""
    
    // MARK: - ViewController lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        resetDisplay()
    }
    
    // MARK: - UI Actions
    @IBAction func searchButtonTapAction(_ sender: Any) {
        guard let searchString = searchTextField.text
            else { return }
        searchTextField.resignFirstResponder()
        userSearchString = formatUserSearchString(searchString: searchString)
        initiateSearch()
    }
    
    func resetDisplay() {
        errorMessage = ""
        DataManager.sharedManager.clearCache()
        refreshTableView()
    }
    
    func initiateSearch() {
        resetDisplay()
        
        activityIndicator.startAnimating()
        
        DataManager.sharedManager.getReposForUser(searchUserId: userSearchString, page:1) { results, more, lastPageNumber, errorMessage in
            // we have the initial API request results here, or an error message...
            // we need to do the first fetch before we know how many pages are there in total...
            
            if ( more ) {
                // we will need to perform a series of requests for subsequent pages until all are fetched...
                let lastPageUpperRange = lastPageNumber + 1
                var completedCount = 1
                
                let operationQueue = OperationQueue()
                operationQueue.maxConcurrentOperationCount = 1
                
                // if we have to fetch additional pages, send those to be pracessed by the ServiceManager URLSession / dataTask...
                for pageNumber in 2..<lastPageUpperRange  {
                   
                    DataManager.sharedManager.getReposForUser(searchUserId: self.userSearchString, page:pageNumber) { results, more, lastPageNumber, errorMessage in
                        completedCount += 1
                        if (completedCount == lastPageNumber || errorMessage.count > 0) {
                            print("Final - GitHub Repos: " , results.count, "Error Msg: ", errorMessage )
                            self.errorMessage = errorMessage
                            DispatchQueue.main.async { [unowned self] in
                                self.refreshTableView()
                                self.activityIndicator.stopAnimating()
                            }
                        }
                    }
                }
            } else {
                self.activityIndicator.stopAnimating()
            
                print("Single Fetch - GitHub Repos: " , results.count, "Error Msg: ", errorMessage )
                self.errorMessage = errorMessage
                DispatchQueue.main.async { [unowned self] in
                    self.refreshTableView()
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    fileprivate func refreshTableView() {
        
        messageTitleLabel.isHidden = DataManager.sharedManager.repos.count > 0
        messageDescriptionLabel.isHidden = DataManager.sharedManager.repos.count > 0

        if (errorMessage.count == 0) {
            DataManager.sharedManager.prepareResults()
            
            messageTitleLabel.text = "Search GitHub"
            messageDescriptionLabel.text = "Type the GitHub user/org and tap Search."
        } else if (errorMessage == "RATE_LIMIT_EXCEEDED") {
            messageTitleLabel.text = "Rate Limit Reached!"
            messageDescriptionLabel.text = "Please try again later."
        } else if (errorMessage == "NO_RESULTS_FOUND") {
            messageTitleLabel.text = "No Repos Found"
            messageDescriptionLabel.text = "We didn't find any GitHub repos for that user."
        } else {
            messageTitleLabel.text = "No Repos Found"
            messageDescriptionLabel.text = "We didn't find any GitHub repos for that user."
        }
        tableView.reloadData()
    }
    
    // MARK: - Utility
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate func formatUserSearchString(searchString: String) -> String {
        return searchString.removeWhitespace().lowercased()
    }
}

// MARK: - UITextField Delegate
extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        resetDisplay()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        userSearchString = textField.text ?? ""
        initiateSearch()
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UITableView Delegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

// MARK: - UITableView DataSource
extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataManager.sharedManager.repos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: RepoCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RepoCell
        
        cell.titleLabel?.text = DataManager.sharedManager.repos[indexPath.row].name
        cell.descriptionLabel?.text = DataManager.sharedManager.repos[indexPath.row].description ?? ""
        cell.forkLabel?.text = String(DataManager.sharedManager.repos[indexPath.row].forksCount)
        cell.starLabel?.text = String(DataManager.sharedManager.repos[indexPath.row].stargazersCount)
        
        cell.updatedLabel?.text = String(DataManager.sharedManager.repos[indexPath.row].updatedString.prefix(10))
        
        return cell
    }
}
