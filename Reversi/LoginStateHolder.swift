//
//  LoginStateHolder.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/22.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

struct LoginStateHolder {
    var load: () -> Bool
    var save: () -> Void
    var remove: () -> Void
}

extension LoginStateHolder {
    static var live = LoginStateHolder(
        load: {
            return defaults.bool(forKey: key)
    }, save: {
        defaults.set(true, forKey: key)
    }, remove: {
        defaults.removeObject(forKey: key)
    })
}

private let key = "loggedIn"
private var defaults: UserDefaults = .standard
