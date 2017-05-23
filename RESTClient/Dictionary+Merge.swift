//
//  Dictionary+Merge.swift
//  RESTClient
//
//  Created by Evgeny Kubrakov on 23.05.17.
//  Copyright © 2017 Evgeny Kubrakov. All rights reserved.
//

import Foundation

extension Dictionary {
    
    mutating func merge(with dictionary: Dictionary) {
        dictionary.forEach { updateValue($1, forKey: $0) }
    }
    
    func merged(with dictionary: Dictionary) -> Dictionary {
        var dict = self
        dict.merge(with: dictionary)
        return dict
    }
}
