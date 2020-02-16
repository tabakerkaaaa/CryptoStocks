//
//  Utility.swift
//  Crypto
//
//  Created by Никита Бабенко on 12/02/2020.
//  Copyright © 2020 Nikita Babenko. All rights reserved.
//

import Foundation

protocol UtilityDelegate: AnyObject {
     func getCryptoData(completionHandler: @escaping (_ crypto: [cryptoInfo]?) -> ())
}

class Utility: UtilityDelegate {
    var crypto: [cryptoInfo]?
    
    func getCryptoData(completionHandler: @escaping ([cryptoInfo]?) -> ()) {
        if let url = URL(string: "https://api.hitbtc.com/api/2/public/ticker/") {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                    let readData = try JSONDecoder().decode([cryptoInfo].self, from: data)
                    completionHandler(readData)
                    } catch let error {
                        print(error)
                        completionHandler(nil)
                    }
                }
            }.resume()
        }
    }
}
