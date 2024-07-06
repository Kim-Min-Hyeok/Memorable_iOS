//
//  StarView.swift
//  Memorable
//
//  Created by Minhyeok Kim on 6/30/24.
//

import SnapKit
import UIKit

class StarView: UIView {
    private let tableView: UITableView
    private let filterButtonsView = UIStackView()
    private let allFilterButton = UIButton(type: .system)
    private let worksheetFilterButton = UIButton(type: .system)
    private let testsheetFilterButton = UIButton(type: .system)
    private let wrongsheetFilterButton = UIButton(type: .system)
    
    private var allDocuments: [Document] = []
    private var filteredDocuments: [Document] = []
    
    override init(frame: CGRect) {
        tableView = UITableView()
        
        super.init(frame: frame)
        
        setupView()
        setupConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = MemorableColor.White
        layer.cornerRadius = 40
        layer.masksToBounds = true
        
        tableView.register(RecentsheetCell.self, forCellReuseIdentifier: "RecentsheetCell")
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        addSubview(filterButtonsView)
        addSubview(tableView)
        
        setupFilterButtons()
        setupGradientView()
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 22)
        tableView.tableHeaderView = headerView
    }
    
    private func setupFilterButtons() {
        filterButtonsView.axis = .horizontal
        filterButtonsView.spacing = 8
        filterButtonsView.alignment = .center
        filterButtonsView.distribution = .fill
        
        configureButton(allFilterButton, title: "전체보기")
        configureButton(worksheetFilterButton, title: "빈칸 학습지", imageName: "bookmark-blue")
        configureButton(testsheetFilterButton, title: "나만의 시험지", imageName: "bookmark-yellow")
        configureButton(wrongsheetFilterButton, title: "오답노트", imageName: "bookmark-gray-v2")
        
        filterButtonsView.addArrangedSubview(allFilterButton)
        filterButtonsView.addArrangedSubview(worksheetFilterButton)
        filterButtonsView.addArrangedSubview(testsheetFilterButton)
        filterButtonsView.addArrangedSubview(wrongsheetFilterButton)
        
        allFilterButton.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
        worksheetFilterButton.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
        testsheetFilterButton.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
        wrongsheetFilterButton.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
        
        // 초기 상태 설정
        updateButtonState(allFilterButton, isSelected: true)
    }
    
    private func configureButton(_ button: UIButton, title: String, imageName: String? = nil) {
        var config = UIButton.Configuration.filled()
        config.title = title
        
        // 폰트 크기 설정 및 라인 제한
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = MemorableFont.BodyCaption()
            return outgoing
        }
        
        // 타이틀을 한 줄로 제한
        config.titleLineBreakMode = .byTruncatingTail
        config.titleAlignment = .center
        
        if let imageName = imageName, let image = UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal) {
            let resizedImage = image.resized(to: CGSize(width: 16, height: 16))
            config.image = resizedImage
            config.imagePlacement = .leading
            config.imagePadding = 8
        }
        
        config.cornerStyle = .capsule
        
        // 기본 상태 (선택되지 않은 상태)
        config.baseForegroundColor = MemorableColor.Gray1
        config.baseBackgroundColor = MemorableColor.Gray5
        
        // 콘텐츠 패딩 설정
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        
        button.configuration = config
        
        // 버튼 크기 설정
        button.snp.makeConstraints { make in
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(80)
        }
    }
    
    private func setupConstraints() {
        filterButtonsView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(28)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(30)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterButtonsView.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    func setDocuments(documents: [Document]) {
        allDocuments = documents.filter { $0.isBookmarked }.sorted(by: { $0.createdDate > $1.createdDate })
        filteredDocuments = allDocuments
        tableView.reloadData()
    }
    
    @objc private func filterButtonTapped(_ sender: UIButton) {
        updateButtonState(sender, isSelected: true)
        
        switch sender {
        case allFilterButton:
            filteredDocuments = allDocuments
        case worksheetFilterButton:
            filteredDocuments = allDocuments.filter { $0.fileType == "빈칸학습지" }
        case testsheetFilterButton:
            filteredDocuments = allDocuments.filter { $0.fileType == "나만의 시험지" }
        case wrongsheetFilterButton:
            filteredDocuments = allDocuments.filter { $0.fileType == "오답노트" }
        default:
            break
        }
        tableView.reloadData()
    }
    
    private func updateButtonState(_ selectedButton: UIButton, isSelected: Bool) {
        for button in [allFilterButton, worksheetFilterButton, testsheetFilterButton, wrongsheetFilterButton] {
            var config = button.configuration
            if button == selectedButton && isSelected {
                config?.baseForegroundColor = MemorableColor.White
                config?.baseBackgroundColor = MemorableColor.Black
            } else {
                config?.baseForegroundColor = MemorableColor.Gray1
                config?.baseBackgroundColor = MemorableColor.Gray5
            }
            button.configuration = config
        }
    }
    
    private func setupGradientView() {
        let gradientView = GradientView(startColor: .white, endColor: .white)
        addSubview(gradientView)
        
        gradientView.snp.makeConstraints { make in
            make.top.equalTo(filterButtonsView.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
    }
}

extension StarView: UITableViewDataSource, UITableViewDelegate, RecentsheetCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDocuments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentsheetCell", for: indexPath) as! RecentsheetCell
        let document = filteredDocuments[indexPath.row]
        cell.configure(with: document)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62
    }
    
    // 라우팅
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let document = filteredDocuments[indexPath.row]
        
        switch document.fileType {
        case "빈칸학습지":
            if let worksheet = document as? Worksheet {
                APIManager.shared.getData(to: "/api/worksheet/ws/\(worksheet.id)") { (sheetDetail: WorksheetDetail?, error: Error?) in
                    
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Error fetching data: \(error)")
                            return
                        }
                        
                        guard let detail = sheetDetail else {
                            print("No data received")
                            return
                        }
                        
                        print("---GET WorkSheet---")
                        print("NAME: \(detail.name)")
                        print("CATE: \(detail.category)")
                        print("isComplete: \(detail.isCompleteAllBlanks)")
                        print("isAddWorksheet: \(detail.isAddWorksheet)")

                        let workSheetVC = WorkSheetViewController()
                        workSheetVC.worksheetDetail = detail
                        self.navigateToViewController(workSheetVC)
                    }
                }
            }
        case "나만의 시험지":
            let testSheetVC = TestSheetViewController()
            // testSheetVC.document = document // 필요하다면 document를 ViewController에 전달
            navigateToViewController(testSheetVC)
        case "오답노트":
            let wrongSheetVC = WrongSheetViewController()
            navigateToViewController(wrongSheetVC)
        default:
            print("Unknown file type")
        }
    }
    
    private func navigateToViewController(_ viewController: UIViewController) {
        if let navigationController = window?.rootViewController as? UINavigationController {
            navigationController.pushViewController(viewController, animated: true)
        } else if let presentingViewController = window?.rootViewController {
            presentingViewController.present(viewController, animated: true, completion: nil)
        }
    }
    
    func didTapBookmark(for document: Document) {
        if let worksheet = document as? Worksheet {
            APIManagere.shared.toggleWorksheetBookmark(worksheetId: worksheet.id) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let updatedWorksheet):
                        if let index = self?.allDocuments.firstIndex(where: { $0.id == updatedWorksheet.id }) {
                            self?.allDocuments[index] = updatedWorksheet
                        }
                        if let index = self?.filteredDocuments.firstIndex(where: { $0.id == updatedWorksheet.id }) {
                            self?.filteredDocuments[index] = updatedWorksheet
                        }
                        self?.tableView.reloadData()
                    case .failure(let error):
                        print("Error toggling bookmark: \(error)")
                        // 에러 처리 (예: 사용자에게 알림 표시)
                    }
                }
            }
        }
    }
}
