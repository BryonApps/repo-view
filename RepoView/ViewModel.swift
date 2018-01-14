//
//  ViewModel.swift
//  RepoView
//
//  Created by Bryon Martin on 1/12/18.
//  Copyright © 2018 Bryon Martin. All rights reserved.
//

import RxSwift
import RxCocoa

class ViewModel {
    let userSearchString = Variable("")
    //let displayRepositories: Variable<[GitRepository]> = Variable([])
    
    let disposeBag = DisposeBag()
    
    lazy var data: Driver<[GitRepository]> = {
        return self.userSearchString.asObservable()
            .throttle(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest {
                self.getRepositories(githubId: $0)
            }
            .asDriver(onErrorJustReturn: [])
    }()
    
    func getRepositories(githubId:String) -> Observable<[GitRepository]> {
        print("id :", githubId)
        if (githubId.count > 3) {
            guard let url = URL(string: "https://api.github.com/users/\(githubId)/repos?page=1&per_page=100")
                else { return Observable.just([]) }
            
            return URLSession.shared
                .rx.json(url: url)
                .retry(3)
                .map {
                    var data = [GitRepository]()

                    if let items = $0 as? [[String: AnyObject]] {
                        items.forEach {
                            guard let name = $0["name"] as? String,
                                let description = $0["description"] as? String,
                                let stargazersCount = $0["stargazers_count"] as? Int,
                                let forksCount = $0["forks_count"] as? Int,
                                let language = $0["language"] as? String,
                                let updatedString = $0["language"] as? String
                                else { return }
                            
                            data.append(GitRepository(name: name, description: description, stargazersCount: stargazersCount, forksCount: forksCount, language: language, updatedString: updatedString))
                        }
                    }
                    
                    data.sort { $0.language < $1.language }
                    return data }
            .catchErrorJustReturn(([]))
        } else {
            return Observable.just([])
        }
    }
    
}
