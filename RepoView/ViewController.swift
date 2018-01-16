//
//  ViewController.swift
//  RepoView
//
//  Created by Bryon Martin on 1/11/18.
//  Copyright © 2018 Bryon Martin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    let viewModel = ViewModel()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTextField.rx.text
            .orEmpty
            .bind(to: viewModel.userSearchString)
            .disposed(by: disposeBag)
        
        viewModel.aggregatedData
            .drive(tableView.rx.items(cellIdentifier: "Cell")) { _, repository, cell in
                cell.textLabel?.text = repository.name
                cell.detailTextLabel?.text = repository.description
            }
            .disposed(by: disposeBag)
        
        let searchString = "facebook"
        
        ServiceManager.sharedManager.getReposForUser(searchUserId: searchString, page:1) { results, more, lastPageNumber, errorMessage in
            print("Repos on page: " , results.count)
            //print("Fetched Repos: " , results as Any)
            print("More Pages?  : " , more)
            print("Last Page #? : " , lastPageNumber)
            print("Error msg?   : " , errorMessage)
            
            if ( more ) {
                print("We have more!")
                // we will need to perform a series of requests for subsequent pages until all are fetched...
                let operationQueue = OperationQueue()
                operationQueue.maxConcurrentOperationCount = 1
                let lastPageRange = lastPageNumber + 1
                
                for pageNumber in 2..<lastPageRange  { // Create operations as an example
                    let operation = BlockOperation(block: {
                        
                        ServiceManager.sharedManager.getReposForUser(searchUserId: searchString, page:pageNumber) { results, more, lastPageNumber, errorMessage in
                            print("Total Repos Fetched: " , results.count)
                            //print("Fetched Repos: " , results as Any)
                            print("More Pages?  : " , more)
                            print("Error msg?   : " , errorMessage)
                            
                        }
                    })
                    operation.name = "Operation #\(pageNumber)"
                    
                    if pageNumber > 2 {
                        operation.addDependency(operationQueue.operations.last!)
                    }
                    operationQueue.addOperation(operation)
                }
            } else {
                print("No mas!")
                // post a notification, that we can process the data and reload the table...
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

