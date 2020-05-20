//
//  LoginClient.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/17.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation
import ComposableArchitecture

public struct LoginClient {
    var login: (LoginRequest) -> Effect<LoginResponse, LoginError>
}

public struct LoginRequest: Equatable {
    var email: String
    var password: String
}
public struct LoginResponse: Equatable {}
public struct LoginError: Error, Equatable {}

extension LoginClient {
    public static var live = LoginClient { request in
        Effect.result {
            let isSuccess = Int.random(in: 0...100).isMultiple(of: 2)
            if isSuccess {
                return .success(.init())
            } else {
                return .failure(.init())
            }
        }
        .eraseToEffect()
    }

    public static var mock = LoginClient { request in
        Effect.result { .success(.init()) }
    }
}
