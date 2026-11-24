//
//  GameBoardViewController.swift
//  MinesWeeper
//
//  Draws the current Board and forwards taps to it, like MineFieldFragment on Android.
//  All game rules live in Board.
//

import UIKit

final class GameBoardViewController: UIViewController {

    private enum Face: String {
        case angry, happy, killed, scared, smile
    }

    private static let faceResetDelay: TimeInterval = 0.5

    private let minesCounter = DigitDisplayView(digits: 3)
    private let timerDisplay = DigitDisplayView(digits: 4)
    private let faceButton = UIButton(type: .custom)
    private let userButton = UIButton(type: .custom)
    private let boardContainer = UIView()
    private let boardView = BoardView()

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private var board: Board?
    /// Board dimensions that fit the available space, measured after layout.
    private var fittedWidth = 0
    private var fittedHeight = 0

    private var timerStartedAt: Date?
    private var timerStoppedAt: Date?
    private var ticker: Timer?
    private var faceReset: DispatchWorkItem?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.surface1
        setUpHeader()
        setUpBoard()
        loadUserPhoto()
        if let userId = container.auth.currentUserId {
            container.records.startSync(userId: userId)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = boardContainer.bounds.size
        let width = max(2, Int(size.width / BoardView.cellSize))
        let height = max(2, Int(size.height / BoardView.cellSize))
        guard size.width > 0, size.height > 0, width != fittedWidth || height != fittedHeight else { return }
        fittedWidth = width
        fittedHeight = height
        // Keep a game in progress; a game nobody has tapped yet is resized to the new space.
        if board == nil || board?.status == .ready {
            startNewGame()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ticker?.invalidate()
        ticker = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if isTimerRunning { startTicker() }
    }

    // MARK: - Layout

    private func setUpHeader() {
        faceButton.imageView?.contentMode = .scaleAspectFit
        faceButton.addTarget(self, action: #selector(faceTapped), for: .touchUpInside)
        setFace(.happy, keepSmiling: true)

        userButton.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
        userButton.tintColor = Theme.primaryText
        userButton.imageView?.contentMode = .scaleAspectFit
        userButton.contentHorizontalAlignment = .fill
        userButton.contentVerticalAlignment = .fill
        userButton.showsMenuAsPrimaryAction = true
        userButton.menu = UIMenu(children: [
            UIAction(title: "Settings", image: UIImage(systemName: "gearshape")) { [weak self] _ in
                self?.showSettings()
            },
            UIAction(title: "Records", image: UIImage(systemName: "trophy")) { [weak self] _ in
                guard let self else { return }
                self.navigationController?.pushViewController(RecordsViewController(records: self.container.records),
                                                              animated: true)
            },
            UIAction(title: "Log Out", image: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
                     attributes: .destructive) { [weak self] _ in
                self?.logOut()
            },
        ])

        let header = UIStackView(arrangedSubviews: [minesCounter, faceButton, timerDisplay, userButton])
        header.axis = .horizontal
        header.spacing = 8
        header.alignment = .fill
        header.distribution = .fill
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            header.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 6),
            header.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -6),
            header.heightAnchor.constraint(equalToConstant: 48),
            // Same proportions as the Android header (1.2 : 1 : 1.8 : 0.6).
            minesCounter.widthAnchor.constraint(equalTo: faceButton.widthAnchor, multiplier: 1.2),
            timerDisplay.widthAnchor.constraint(equalTo: faceButton.widthAnchor, multiplier: 1.8),
            userButton.widthAnchor.constraint(equalTo: faceButton.widthAnchor, multiplier: 0.6),
        ])

        boardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(boardContainer)
        NSLayoutConstraint.activate([
            boardContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            boardContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            boardContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            boardContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
    }

    private func setUpBoard() {
        boardView.translatesAutoresizingMaskIntoConstraints = false
        boardContainer.addSubview(boardView)
        NSLayoutConstraint.activate([
            boardView.centerXAnchor.constraint(equalTo: boardContainer.centerXAnchor),
            boardView.topAnchor.constraint(equalTo: boardContainer.topAnchor),
        ])
        boardView.onTap = { [weak self] x, y in self?.cellTapped(x, y) }
        boardView.onLongPress = { [weak self] x, y in self?.cellLongPressed(x, y) }
    }

    private func loadUserPhoto() {
        guard let url = container.auth.currentUserPhotoURL else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                guard let self else { return }
                self.userButton.setImage(image, for: .normal)
                self.userButton.imageView?.layer.cornerRadius = self.userButton.bounds.height / 2
                self.userButton.imageView?.clipsToBounds = true
            }
        }.resume()
    }

    // MARK: - Game

    private func startNewGame() {
        guard fittedWidth > 0, fittedHeight > 0 else { return }
        let maxMines = Board.maxMines(width: fittedWidth, height: fittedHeight)
        let numberOfMines = min(container.settings.numberOfMines, maxMines)
        container.settings.numberOfMines = numberOfMines
        container.settings.fieldSize = fittedWidth * fittedHeight
        guard let newBoard = Board(width: fittedWidth, height: fittedHeight, mineCount: numberOfMines) else { return }
        board = newBoard
        resetTimer()
        boardView.show(newBoard)
        minesCounter.show(digitsOf: newBoard.flagsRemaining)
        setFace(.happy, keepSmiling: true)
    }

    private func cellTapped(_ x: Int, _ y: Int) {
        guard let board, !board.isOver, board.state(x, y) == .covered else { return }
        boardView.render(board.reveal(x, y))
        switch board.status {
        case .lost:
            gameLost()
        case .won:
            gameWon(board)
        default:
            setFace(.scared, keepSmiling: true)
            startTimer()
        }
    }

    private func cellLongPressed(_ x: Int, _ y: Int) {
        guard let board else { return }
        let wasFlagged = board.state(x, y) == .flagged
        guard board.toggleFlag(x, y) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        boardView.render(x, y)
        minesCounter.show(digitsOf: board.flagsRemaining)
        if board.status == .won {
            gameWon(board)
        } else {
            setFace(wasFlagged ? .angry : .scared, keepSmiling: true)
        }
    }

    private func gameLost() {
        setFace(.killed, keepSmiling: false)
        stopTimer()
        showAlert(title: "You Lost!", message: "You have lost!. Do you want to start a new game?") { [weak self] in
            self?.startNewGame()
        }
    }

    private func gameWon(_ board: Board) {
        setFace(.happy, keepSmiling: false)
        // The first tap can win a very small board, before the timer was ever started.
        startTimer()
        stopTimer()

        if let userId = container.auth.currentUserId {
            let record = RecordItem(
                numberOfMines: board.mineCount,
                fieldSize: board.width * board.height,
                timeInSeconds: elapsedSeconds(),
                timeStamp: Int64(Date().timeIntervalSince1970 * 1000))
            container.records.addRecord(record, userId: userId)
        }

        showAlert(title: "You Won!", message: "You have won!. Do you want to start a new game?") { [weak self] in
            self?.startNewGame()
        }
    }

    @objc private func faceTapped() {
        showAlert(title: "Game Restart", message: "Do you really want to restart your game?") { [weak self] in
            self?.startNewGame()
        }
    }

    private func showSettings() {
        let settings = SettingsViewController(
            container: container,
            maxMines: Board.maxMines(width: fittedWidth, height: fittedHeight),
            onNumberOfMinesChanged: { [weak self] in self?.numberOfMinesChanged() },
            onLogOut: { [weak self] in self?.logOut() })
        navigationController?.pushViewController(settings, animated: true)
    }

    /// A changed mine count drops the game in progress so a fresh one starts, as on Android.
    private func numberOfMinesChanged() {
        if board?.mineCount != container.settings.numberOfMines {
            startNewGame()
        }
    }

    private func logOut() {
        ticker?.invalidate()
        container.logOut()
        switchRoot(to: LogInViewController(container: container))
    }

    // MARK: - Timer

    private var isTimerRunning: Bool { timerStartedAt != nil && timerStoppedAt == nil }

    private func elapsedSeconds() -> Int {
        guard let start = timerStartedAt else { return 0 }
        return Int((timerStoppedAt ?? Date()).timeIntervalSince(start))
    }

    private func startTimer() {
        guard timerStartedAt == nil else { return }
        timerStartedAt = Date()
        startTicker()
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.timerDisplay.show(seconds: self.elapsedSeconds())
        }
        timerDisplay.show(seconds: elapsedSeconds())
    }

    private func stopTimer() {
        if timerStartedAt != nil && timerStoppedAt == nil { timerStoppedAt = Date() }
        ticker?.invalidate()
        ticker = nil
        timerDisplay.show(seconds: elapsedSeconds())
    }

    private func resetTimer() {
        ticker?.invalidate()
        ticker = nil
        timerStartedAt = nil
        timerStoppedAt = nil
        timerDisplay.show(seconds: 0)
    }

    // MARK: - Face

    private func setFace(_ face: Face, keepSmiling: Bool) {
        faceReset?.cancel()
        faceButton.setImage(UIImage(named: face.rawValue), for: .normal)
        guard keepSmiling else { return }
        let reset = DispatchWorkItem { [weak self] in
            self?.faceButton.setImage(UIImage(named: Face.smile.rawValue), for: .normal)
        }
        faceReset = reset
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.faceResetDelay, execute: reset)
    }
}
