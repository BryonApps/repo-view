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
        
        viewModel.data
            .drive(tableView.rx.items(cellIdentifier: "Cell")) { _, repository, cell in
                cell.textLabel?.text = repository.name
                cell.detailTextLabel?.text = repository.description
            }
            .disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }


}

