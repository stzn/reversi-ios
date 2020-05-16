//
//  AppViewController.swift
//  Reversi
//
//  Created by Shinzan Takata on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Combine
import UIKit
import ComposableArchitecture

class AppViewController: UINavigationController {
    let store: Store<AppState, AppAction>
    private var cancellables: Set<AnyCancellable> = []

    init(store: Store<AppState, AppAction>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "ログイン"
        self.store
            .scope(state: { $0.login }, action: AppAction.login)
            .ifLet { loginState in
                let login = LoginViewController.instantiate(store: loginState)
                self.setViewControllers([login], animated: true)
        }.store(in: &cancellables)

        self.store
            .scope(state: { $0.game }, action: AppAction.game)
            .ifLet { gameState in
                let game = GameViewController.instantiate(store: gameState)
                self.setViewControllers([game], animated: true)
        }.store(in: &cancellables)
    }
}
