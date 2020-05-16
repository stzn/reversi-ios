import Combine
import ComposableArchitecture
import UIKit

class GameViewController: UIViewController {
    var viewStore: ViewStore<GameState, GameAction>!
    var cancellables: Set<AnyCancellable> = []

    static func instantiate(store: Store<GameState, GameAction>) -> GameViewController {
        let viewController =
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(
                identifier: "GameViewController") as! GameViewController
        viewController.viewStore = ViewStore(store)
        return viewController
    }

    @IBOutlet private var boardView: BoardView!

    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `messageDiskSize` に保管された値を使います。
    private var messageDiskSize: CGFloat!

    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!

    /// プレイヤーの動作が完了した後に次のターンへ移るときに使います。
    private var playing: Bool = false {
        didSet {
            if !playing {
                self.updateMessageViews(turn: viewStore.turn, board: viewStore.board)
                self.updateCountLabels(on: viewStore.board)
                self.waitForPlayer()
            }
        }
    }

    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Game"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .done,
            target: self,
            action: #selector(logout))

        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant

        self.viewStore.publisher.players.sink { [weak self] players in
            guard let self = self else {
                return
            }
            for side in Disk.sides {
                self.playerControls[side.index].selectedSegmentIndex =
                    players[side.index].rawValue
            }
        }.store(in: &cancellables)

        self.viewStore.publisher.playingAsComputer
            .sink { [weak self] player in
                guard let self = self else {
                    return
                }

                if let player = player {
                    self.playerActivityIndicators[player.index].startAnimating()
                } else {
                    self.playerActivityIndicators.forEach { $0.stopAnimating() }
                }
            }.store(in: &cancellables)

        self.viewStore.publisher.shouldSkip.sink { [weak self] shouldSkip in
            guard let self = self else {
                return
            }

            if shouldSkip {
                let alertController = UIAlertController(
                    title: "Pass",
                    message: "Cannot place a disk.",
                    preferredStyle: .alert
                )
                alertController.addAction(
                    UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
                        self?.viewStore.send(.turnSkipped)
                    })
                self.present(alertController, animated: true)
                return
            }
        }.store(in: &cancellables)

        self.viewStore.publisher.sink { [weak self] state in
            guard let self = self else {
                return
            }

            guard let currentTapPosition = state.currentTapPosition else {
                for (position, disk) in state.board.disks {
                    self.boardView.setDisk(
                        disk,
                        atX: position.x, y: position.y,
                        animated: false)
                }
                self.updateMessageViews(turn: state.turn, board: state.board)
                self.updateCountLabels(on: state.board)
                return
            }

            self.playing = true
            let currentTurn = self.messageDiskView.disk
            self.placeDisk(
                currentTurn,
                atX: currentTapPosition.x, y: currentTapPosition.y,
                animated: true
            )
        }.store(in: &cancellables)

        viewStore.send(.gameStarted)
    }

    @objc private func logout() {
        self.viewStore.send(.logoutButtonTapped)
    }

    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if viewHasAppeared { return }
        viewHasAppeared = true
        playing = false

    }

    func waitForPlayer() {
        guard let turn = viewStore.turn else {
            return
        }
        switch viewStore.players[turn.index] {
        case .manual:
            break
        case .computer:
            viewStore.send(.computerPlay)
        }
    }
}

// MARK: Views

extension GameViewController {
    /// 各プレイヤーの獲得したディスクの枚数を表示します。
    func updateCountLabels(on board: Board) {
        for side in Disk.sides {
            countLabels[side.index].text = "\(board.countDisks(of: side))"
        }
    }

    /// 現在の状況に応じてメッセージを表示します。
    func updateMessageViews(turn: Disk?, board: Board) {
        switch turn {
        case .some(let side):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = side
            messageLabel.text = "'s turn"
        case .none:
            if let winner = board.sideWithMoreDisks() {
                messageDiskSizeConstraint.constant = messageDiskSize
                messageDiskView.disk = winner
                messageLabel.text = " won"
            } else {
                messageDiskSizeConstraint.constant = 0
                messageLabel.text = "Tied"
            }
        }
    }

    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    func placeDisk(
        _ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool,
        completion: ((Bool) -> Void)? = nil
    ) {
        let diskCoordinates = Rule.flippedDiskCoordinatesByPlacingDisk(
            disk, atX: x, y: y, on: boardView.currentDisks)
        if diskCoordinates.isEmpty {
            return
        }

        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.animationCanceller = nil
                self?.playing = false
            }
            animationCanceller = Canceller(cleanUp)
            animateSettingDisks(at: [(x, y)] + diskCoordinates, to: disk) {
                [weak self] isFinished in
                guard let self = self else { return }
                guard let canceller = self.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(isFinished)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                for (x, y) in diskCoordinates {
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                self.playing = false
                completion?(true)
            }
        }
    }

    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    private func animateSettingDisks<C: Collection>(
        at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void
    )
    where C.Element == (Int, Int) {
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }

        let animationCanceller = self.animationCanceller!
        boardView.setDisk(disk, atX: x, y: y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(
                    at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for (x, y) in coordinates {
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion(false)
            }
        }
    }

    //    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    //    private func playTurnOfComputer(
    //        turn: Disk, position: DiskPosition,
    //        completion: ((Bool) -> Void)?
    //    ) {
    //        self.placeDisk(
    //            turn, atX: position.x, y: position.y, animated: true,
    //            completion: completion)
    //    }
}

// MARK: Inputs

extension GameViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    /// アラートを表示して、ゲームを初期化して良いか確認し、
    /// "OK" が選択された場合ゲームを初期化します。
    @IBAction func pressResetButton(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                guard let self = self else { return }

                self.animationCanceller?.cancel()
                self.animationCanceller = nil

                self.boardView.reset()
                self.viewStore.send(.resetTapped)
            })
        present(alertController, animated: true)
    }

    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)

        self.viewStore.send(.playerChanged(side, Player(rawValue: sender.selectedSegmentIndex)!))

        if !isAnimating, side == viewStore.turn {
            waitForPlayer()
        }
    }
}

extension GameViewController: BoardViewDelegate {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        if isAnimating { return }
        self.viewStore.send(.manualPlayerDiskPlaced(.init(x: x, y: y)))
    }
}

// MARK: Additional types

final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?

    init(_ body: (() -> Void)?) {
        self.body = body
    }

    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}

// MARK: File-private extensions

extension Disk {
    init(index: Int) {
        for side in Disk.sides {
            if index == side.index {
                self = side
                return
            }
        }
        preconditionFailure("Illegal index: \(index)")
    }

    var index: Int {
        switch self {
        case .dark: return 0
        case .light: return 1
        }
    }
}
