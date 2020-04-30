import UIKit
import ReversiCore

class ViewController: UIViewController {
    private var viewModel: ViewModel!
    static func instantiate(viewModel: ViewModel) -> ViewController {
        guard let viewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController() as? ViewController else {
                preconditionFailure("must not be nil")
        }
        viewController.viewModel = viewModel
        viewModel.delegate = viewController
        return viewController
    }

    @IBOutlet private(set) var boardView: BoardView!
    
    @IBOutlet private(set) var messageDiskView: DiskView!
    @IBOutlet private(set) var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `messageDiskSize` に保管された値を使います。
    private var messageDiskSize: CGFloat!
    
    @IBOutlet private(set) var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!
    
    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant

        viewModel.requestGameStart()
    }
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewHasAppeared { return }
        viewHasAppeared = true
    }
}

// MARK: ViewModelDelegate

extension ViewController: ViewModelDelegate {
    func startedComputerTurn(of player: GamePlayer) {
        playerActivityIndicators[player.side.index].startAnimating()
    }

    func endedComputerTurn(of player: GamePlayer) {
        playerActivityIndicators[player.side.index].stopAnimating()
    }

    func setInitialState(_ state: GameState) {
        boardView.reset()

        state.board.disks.forEach {
            let (position, disk) = $0
            boardView.setDisk(disk, atX: position.x, y: position.y, animated: false)
        }
        state.players.forEach { player in
            playerControls[player.side.index].selectedSegmentIndex = player.type.rawValue
        }
        setTurnMessages(for: state.activePlayerSide)
        updateCountLabels(on: state.board)
    }

    func setPlayerType(_ type: Int, of side: Disk) {
        playerControls[side.index].selectedSegmentIndex = type
    }

    func setDisk(_ disk: Disk, atX x: Int, y: Int, on board: Board) {
        self.placeDisk(disk, atX: x, y: y, animated: true) { [weak self] isSuccess in
            guard isSuccess else {
                return
            }
            self?.setTurnMessages(for: disk)
            self?.updateCountLabels(on: board)
            self?.viewModel.requestNextTurn()
        }
    }

    func passedTurn() {
        let alertController = UIAlertController(
            title: "Pass",
            message: "Cannot place a disk.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
            self?.viewModel.requestNextTurn()
        })
        present(alertController, animated: true)
    }

    func movedTurn(to player: GamePlayer) {
        setTurnMessages(for: player.side)
    }

    func finishedGame(wonBy player: GamePlayer?) {
        if let winner = player {
            setFinishedMessages(for: winner)
        } else {
            setTiedMessages()
        }
    }
}

// MARK: Place Disk

extension ViewController {
    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    func placeDisk(_ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) {
        let diskCoordinates = animationCoordinates(disk, atX: x, y: y)
        guard !diskCoordinates.isEmpty else {
            completion?(false)
            return
        }

        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.animationCanceller = nil
            }
            animationCanceller = Canceller(cleanUp)
            animateSettingDisks(at: [(x, y)] + diskCoordinates, to: disk) { [weak self] isFinished in
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
                completion?(true)
            }
        }
    }
    
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == (Int, Int)
    {
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }
        
        let animationCanceller = self.animationCanceller!
        boardView.setDisk(disk, atX: x, y: y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for (x, y) in coordinates {
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion(false)
            }
        }
    }

    private func animationCoordinates(_ disk: Disk, atX x: Int, y: Int) -> [(Int, Int)] {
        let directions = [
            (x: -1, y: -1),
            (x:  0, y: -1),
            (x:  1, y: -1),
            (x:  1, y:  0),
            (x:  1, y:  1),
            (x:  0, y:  1),
            (x: -1, y:  0),
            (x: -1, y:  1),
        ]

        guard boardView.diskAt(x: x, y: y) == nil else {
            return []
        }

        var diskCoordinates: [(Int, Int)] = []

        for direction in directions {
            var x = x
            var y = y

            var diskCoordinatesInLine: [(Int, Int)] = []
            flipping: while true {
                x += direction.x
                y += direction.y

                switch (disk, boardView.diskAt(x: x, y: y)) { // Uses tuples to make patterns exhaustive
                case (.dark, .some(.dark)), (.light, .some(.light)):
                    diskCoordinates.append(contentsOf: diskCoordinatesInLine)
                    break flipping
                case (.dark, .some(.light)), (.light, .some(.dark)):
                    diskCoordinatesInLine.append((x, y))
                case (_, .none):
                    break flipping
                }
            }
        }
        return diskCoordinates
    }

}

// MARK: Views

extension ViewController {
    private func setTurnMessages(for side: Disk) {
        messageDiskSizeConstraint.constant = messageDiskSize
        messageDiskView.disk = side
        messageLabel.text = "'s turn"
    }

    private func updateCountLabels(on board: Board) {
        for side in Disk.sides {
            countLabels[side.index].text = "\(board.countDisks(of: side))"
        }
    }

    private func setFinishedMessages(for winner: GamePlayer) {
        messageDiskSizeConstraint.constant = messageDiskSize
        messageDiskView.disk = winner.side
        messageLabel.text = " won"
    }

    private func setTiedMessages() {
        messageDiskSizeConstraint.constant = 0
        messageLabel.text = "Tied"
    }
}

// MARK: Inputs

extension ViewController {
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
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            self.animationCanceller?.cancel()
            self.animationCanceller = nil

            self.viewModel.requestGameReset()
        })
        present(alertController, animated: true)
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let type = sender.selectedSegmentIndex
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)
        viewModel.changedPlayerType(type, of: side)
    }
}

// MARK: BoardViewDelegate

extension ViewController: BoardViewDelegate {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        if isAnimating { return }
        viewModel.selectedCell(for: messageDiskView.disk, atX: x, y: y)
    }
}
