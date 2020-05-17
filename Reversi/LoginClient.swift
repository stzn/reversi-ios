//
//  LoginClient.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/17.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation
import ComposableArchitecture

protocol LoginClient {
    func login(request: LoginRequest) -> Effect<LoginResponse, LoginError>
}

struct LoginRequest: Equatable {
    var email: String
    var password: String
}
struct LoginResponse: Equatable {}
struct LoginError: Error, Equatable {}

struct FlakyLoginClient: LoginClient {
    func login(request: LoginRequest) -> Effect<LoginResponse, LoginError> {
        Effect.result {
            let isSuccess = Int.random(in: 0...100).isMultiple(of: 2)
            if isSuccess {
                return .success(.init())
            } else {
                return .failure(.init())
            }
        }
        .delay(for: 1.0, scheduler: DispatchQueue.main)
        .eraseToEffect()
    }
}


