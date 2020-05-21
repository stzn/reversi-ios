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
    var loggedIn: () -> Effect<Never, Never>
    var loggedOut: () -> Effect<Never, Never>
}

extension LoginStateHolder {
    static let live = LoginStateHolder(
        load: {
            Effect(value: defaults.bool(forKey: key))
        },
        loggedIn: {
            .fireAndForget { defaults.set(true, forKey: key) }
        },
        loggedOut: {
            .fireAndForget { defaults.removeObject(forKey: key) }
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
        loggedIn: {
            .fireAndForget { isLoggedIn = true }
        },
        loggedOut: {
            .fireAndForget { isLoggedIn = false }
        })
}

private var isLoggedIn = false

#endif
