//
//  NetworkingProtocol.swift
//  Crypto
//
//  Created by Никита Бабенко on 17/02/2020.
//  Copyright © 2020 Nikita Babenko. All rights reserved.
//

import Foundation


protocol NetworkingProtocol {
    func getData(completionHandler: @escaping ([Any]) -> ())
    func showError()
}
