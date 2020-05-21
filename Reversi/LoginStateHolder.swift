//
//  LoginStateHolder.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/22.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import ComposableArchitecture
import Foundation

struct LoginStateHolder {
    var load: () -> Effect<Bool, Never>
    var login: () -> Effect<Bool, Never>
    var logout: () -> Effect<Bool, Never>
}

extension LoginStateHolder {
    static let live = LoginStateHolder(
        load: {
            Effect(value: defaults.bool(forKey: key))
        },
        login: {
            defaults.set(true, forKey: key)
            return Effect(value: true)
        },
        logout: {
            defaults.removeObject(forKey: key)
            return Effect(value: true)
        })
}

private let key = "loggedIn"
private var defaults: UserDefaults = .standard

#if DEBUG

extension LoginStateHolder {
    static let mock = LoginStateHolder(
        load: {
            Effect(value: isLoggedIn)
        },
        login: {
            isLoggedIn = true
            return Effect(value: true)
        },
        logout: {
            isLoggedIn = false
            return Effect(value: true)
        })
}

private var isLoggedIn = false

#endif
