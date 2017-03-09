//
//  JSONParcelable.swift
//  RESTClient
//
//  Created by Evgeny Kubrakov on 09.03.17.
//  Copyright © 2017 Evgeny Kubrakov. All rights reserved.
//

import Foundation

public protocol JSONParcelable {
    var parcelableType: JSONParcelableType {get}
}

public enum JSONParcelableType {
    case dictionary
    case array
}

extension Dictionary: JSONParcelable {
    public var parcelableType: JSONParcelableType {
        return .dictionary
    }
}

extension Array: JSONParcelable {
    public var parcelableType: JSONParcelableType {
        return .array
    }
}
