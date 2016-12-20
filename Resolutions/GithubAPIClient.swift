//
//  GithubAPIClient.swift
//  Resolutions
//
//  Created by Daniel Ma on 12/20/16.
//  Copyright © 2016 Daniel Ma. All rights reserved.
//

import Foundation

Alamofire.request(url, method: .get).validate().responseJSON { response in
  switch response.result {
  case .success(let value):
    let json = JSON(value)
    print("JSON: \(json)")
  case .failure(let error):
    print(error)
  }
}
