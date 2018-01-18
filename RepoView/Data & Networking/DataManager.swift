//
//  DataManager.swift
//  RepoView
//
//  Created by Bryon Martin on 1/14/18.
//  Copyright © 2018 Bryon Martin. All rights reserved.
//

import Foundation

class DataManager {
    static let sharedManager = DataManager()
    typealias SearchResult = ([GitRepository], Bool, Int, String) -> ()
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    var repos: [GitRepository] = []
    
    var errorMessage = ""
    var moreResults = false
    var lastResultPageNumber = 1
    
    func getReposForUser(searchUserId: String, page: Int, completion: @escaping SearchResult) {
        print("*** Fetching for id: ", searchUserId, " Page: ", page)
        
        guard let url = URL(string: "https://api.github.com/users/\(searchUserId)/repos?page=\(page)&per_page=100")
            else { return }
        
        dataTask = defaultSession.dataTask(with: url) { data, response, error in
            defer { self.dataTask = nil }
            if let error = error {
                self.errorMessage += "DATA_TASK_ERROR: " + error.localizedDescription + "\n"
    
            } else if let data = data,
                let httpResponse = response as? HTTPURLResponse {
                if (httpResponse.statusCode == 200) {
                    self.errorMessage = ""
                    self.updateSearchResults(data)
                    if let linksString = httpResponse.allHeaderFields["Link"] as? String {
                        self.moreResults = self.hasMorePages(linkString:linksString)
                        if (self.moreResults) {
                            self.lastResultPageNumber = self.lastPageNumber(linkString: linksString)
                        } else {
                            self.lastResultPageNumber = page
                        }
                    } else {
                        self.moreResults = false
                    }
                } else if ( httpResponse.statusCode == 403 ) {
                    self.errorMessage = "RATE_LIMIT_EXCEEDED"
                    self.clearCache()
                } else if ( httpResponse.statusCode == 404 ) {
                    self.errorMessage = "NO_RESULTS_FOUND"
                    self.clearCache()
                } else {
                    self.errorMessage = "Other Error"
                    self.clearCache()
                }
                
                DispatchQueue.main.async {
                    completion(self.repos, self.moreResults, self.lastResultPageNumber, self.errorMessage)
                }
            }
        }
        dataTask?.resume()
    }
    
    func clearCache() {
        repos.removeAll()
        lastResultPageNumber = 1
    }
    
    fileprivate func hasMorePages(linkString: String) -> Bool {
        return linkString.contains("next")
    }
    
    // Parse the response headers to get the URL that includes the last page of repos for the user
    fileprivate func lastPageNumber(linkString: String) -> Int {
        let linksArray = linkString.components(separatedBy:  ",")
        
        for link in linksArray {
            if (link.contains("rel=\"last\"") ) {
                if let pageTagIndex = link.index(of: "?") { // the start index of the ?page=nnn tag...
                    if let itemsPerPageIndex = link.index(of: "&") {
                        let substring = link[pageTagIndex..<itemsPerPageIndex]
                        let pageNumberTagString = String(substring)
                
                        let pageNumberStringIndex = pageNumberTagString.index(pageNumberTagString.startIndex, offsetBy: 6)
                            let substring2 = pageNumberTagString[pageNumberStringIndex...]
                            let pageNumberString = String(substring2)
                            
                        if let pageNumber = Int(pageNumberString)  {
                            return pageNumber
                        } else {
                            return 1
                        }
                    }
                }
            }
        }
        return 1
    }
    // Map the fetched JSON data to GitRepo objects and append them to the cache
    fileprivate func updateSearchResults(_ data: Data) {
        let decoder = JSONDecoder()
        
        do {
            let responseRepos = try decoder.decode([GitRepository].self, from: data)
            repos.append(contentsOf: responseRepos)
        } catch {
            print("error trying to convert data to JSON")
            print(error)
        }
    }
    
    // Sort the cached results and create a dictionary of repo counts by language
    func prepareResults () {
        repos.sort {
            if ( $0.stargazersCount != $1.stargazersCount ) {
                return $0.stargazersCount > $1.stargazersCount
            } else {
                return $0.name > $1.name
            }
        }
    }
}
