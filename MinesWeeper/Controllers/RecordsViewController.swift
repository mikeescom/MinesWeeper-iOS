//
//  RecordsViewController.swift
//  MinesWeeper
//
//  The player's records, best first, like PersonalRecordsFragment on Android. Opened from the
//  account menu on the game screen; updates as new wins are saved or synced.
//

import UIKit

final class RecordsViewController: UITableViewController {

    private var records: [RecordItem] = []
    private let emptyLabel = UILabel()

    init() {
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My best times"
        view.backgroundColor = Theme.surface1
        tableView.separatorStyle = .none
        tableView.register(RecordCell.self, forCellReuseIdentifier: RecordCell.reuseIdentifier)

        emptyLabel.text = "No records yet. Win a game to set your first time!"
        emptyLabel.textColor = Theme.surface3
        emptyLabel.font = .systemFont(ofSize: 18)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0

        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: LocalRecordStore.didChangeNotification, object: nil)
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let navigationBar = navigationController?.navigationBar else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.surface1
        appearance.titleTextAttributes = [.foregroundColor: Theme.primaryText]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.tintColor = Theme.primaryText
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @objc private func reload() {
        records = RecordRanking.rank(RecordsRepository.shared.loadAllRecords())
        tableView.backgroundView = records.isEmpty ? emptyLabel : nil
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecordCell.reuseIdentifier, for: indexPath)
        (cell as? RecordCell)?.show(records[indexPath.row], rank: indexPath.row + 1)
        return cell
    }
}

/// One record, laid out like personal_record_item.xml on Android.
private final class RecordCell: UITableViewCell {

    static let reuseIdentifier = "RecordCell"

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    private let rankLabel = RecordCell.label(size: 19)
    private let difficultyLabel = RecordCell.label(size: 19)
    private let timeLabel = RecordCell.label(size: 19)
    private let minesLabel = RecordCell.label(size: 17)
    private let fieldSizeLabel = RecordCell.label(size: 17)
    private let dateLabel = RecordCell.label(size: 17)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        let card = UIView()
        card.layer.cornerRadius = 15
        card.layer.borderWidth = 2
        card.layer.borderColor = UIColor(hex: 0x1363DF).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        let mainRow = UIStackView(arrangedSubviews: [difficultyLabel, timeLabel])
        mainRow.distribution = .fillEqually
        let detailRow = UIStackView(arrangedSubviews: [minesLabel, fieldSizeLabel, dateLabel])
        detailRow.distribution = .fillEqually
        let rows = UIStackView(arrangedSubviews: [mainRow, detailRow])
        rows.axis = .vertical
        rows.spacing = 4

        rankLabel.setContentHuggingPriority(.required, for: .horizontal)
        rankLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let content = UIStackView(arrangedSubviews: [rankLabel, rows])
        content.spacing = 12
        content.alignment = .center
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(_ record: RecordItem, rank: Int) {
        rankLabel.text = "\(rank).-"
        difficultyLabel.text = String(format: "%.2f mines/sqr.", RecordRanking.density(record))
        timeLabel.text = "\(record.timeInSeconds) secs."
        minesLabel.text = "\(record.numberOfMines) mines"
        fieldSizeLabel.text = "\(record.fieldSize) sqr."
        let date = Date(timeIntervalSince1970: TimeInterval(record.timeStamp) / 1000)
        dateLabel.text = Self.dateFormatter.string(from: date)
    }

    private static func label(size: CGFloat) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: size)
        label.textColor = UIColor(hex: 0xDFF6FF)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }
}
