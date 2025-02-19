//
//  WorkSheetListViewComponent.swift
//  Memorable
//
//  Created by Minhyeok Kim on 6/28/24.
//

import SnapKit
import UIKit

protocol WorksheetListViewComponentDelegate: AnyObject {
    func didRequestBookmarkUpdate(for document: Document, inCategory category: String, displayType: WorksheetListViewComponent.DisplayDocumentType)
    func didDeleteDocuments(for document: Document)
    func didModifyDocument(for document: Document, newName: String)
    func didTapWorksheetCell(inCategory category: String, displayType: WorksheetListViewComponent.DisplayDocumentType)
}

class WorksheetListViewComponent: UIView {
    enum DisplayDocumentType {
        case all, worksheet, testsheet, wrongsheet
    }

    private var currentDisplayType: DisplayDocumentType = .worksheet
    private var currentCategory: String = "전체보기"
    private var lastDisplayType: DisplayDocumentType?
    private var lastCategory: String?
    
    private var selectedDocuments: [Document] = []
    private var actionSheetView: EditActionSheetView?
    weak var delegate: WorksheetListViewComponentDelegate?
    let worksheetTableView: UITableView
    private let filterScrollView: UIScrollView
    private let filterStackView: UIStackView
    private var allButton = UIButton()

    private var currentFilterButton = UIButton() // MARK: 즐겨찾기 수정

    private let settingButton: UIButton
    private var editButton: UIBarButtonItem?
    private var doneButton: UIBarButtonItem?
    
    private var isModifying: Bool = false
    
    private var worksheets: [Document] = []
    private var categories: Set<String> = []
    private var filteredWorksheets: [Document] = []
    
    private var isEditingMode: Bool = false {
        didSet {
            worksheetTableView.setEditing(isEditingMode, animated: true)
        }
    }
    
    override init(frame: CGRect) {
        self.worksheetTableView = UITableView(frame: .zero, style: .plain)
        self.filterScrollView = UIScrollView()
        self.filterStackView = UIStackView()
        self.settingButton = UIButton()
        super.init(frame: frame)
        self.backgroundColor = MemorableColor.White
        layer.cornerRadius = 40
        self.clipsToBounds = true
        self.allButton = createFilterButton(title: "전체보기")

        self.currentFilterButton = allButton // MARK: 즐겨찾기 수정
        
        setupViews()
        setupTableView()
        setupGradientView()
        setupEditingButtons()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(filterScrollView)
        filterScrollView.addSubview(filterStackView)
        addSubview(settingButton)
        addSubview(worksheetTableView)
        
        filterScrollView.showsHorizontalScrollIndicator = false
        
        filterStackView.axis = .horizontal
        filterStackView.spacing = 8
        filterStackView.alignment = .center
        
        worksheetTableView.register(RecentsheetCell.self, forCellReuseIdentifier: "WorksheetTableViewCell")
        
        setupConstraints()
        setupSettingButton()
    }
    
    private func setupConstraints() {
        filterScrollView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(54)
        }
        
        filterStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().offset(28)
            make.height.equalTo(30)
        }
        
        settingButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(27)
            make.trailing.equalToSuperview().offset(-28)
            make.width.height.equalTo(24)
        }
        
        worksheetTableView.snp.makeConstraints { make in
            make.top.equalTo(filterScrollView.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-56)
        }
    }
    
    private func setupTableView() {
        worksheetTableView.dataSource = self
        worksheetTableView.delegate = self
        worksheetTableView.rowHeight = 62
        worksheetTableView.separatorStyle = .none // 구분선 삭제
        worksheetTableView.allowsSelection = true
        worksheetTableView.allowsMultipleSelectionDuringEditing = true
        
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: worksheetTableView.frame.width, height: 22)
        worksheetTableView.tableHeaderView = headerView
    }
    
    private func setupGradientView() {
        let gradientView = GradientView(startColor: MemorableColor.White ?? .white, endColor: MemorableColor.White ?? .white)
        addSubview(gradientView)
        
        gradientView.snp.makeConstraints { make in
            make.top.equalTo(filterScrollView.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
    }
    
    private func setupEditingButtons() {
        editButton = UIBarButtonItem(title: "편집", style: .plain, target: self, action: #selector(toggleEditingMode))
        doneButton = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(toggleEditingMode))
        
        if let viewController = findViewController() as? UIViewController {
            viewController.navigationItem.rightBarButtonItem = editButton
        }
    }
    
    @objc private func toggleEditingMode() {
        isEditingMode.toggle()
    }
    
    func setWorksheets(_ documents: [Document], _ category: String, displayType: DisplayDocumentType = .all) {
        self.currentDisplayType = displayType
        self.worksheets = documents.sorted(by: { $0.createdDate > $1.createdDate })
        
        // 카테고리에 따라 필터링
        if category == "전체보기" {
            self.filteredWorksheets = self.worksheets
        } else {
            self.filteredWorksheets = self.worksheets.filter { $0.category == category }
        }
        
        self.categories = Set(documents.map { $0.category })
        updateButtonState(currentFilterButton, isSelected: true)
        updateCurrentDocuments()
        setupFilterButtons()
        worksheetTableView.reloadData()
    }
    
    private func setupFilterButtons() {
        filterStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        filterStackView.addArrangedSubview(allButton)
        filterStackView.distribution = .fillProportionally
        
        for category in categories.sorted() {
            let button = createFilterButton(title: category)
            filterStackView.addArrangedSubview(button)
        }
        
        // 초기 상태 설정
        updateButtonState(allButton, isSelected: true)
    }
    
    private func createFilterButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = MemorableFont.BodyCaption()
            return outgoing
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        configuration.cornerStyle = .capsule
        
        if title == "전체보기" {
            configuration.baseBackgroundColor = MemorableColor.Black
            configuration.baseForegroundColor = MemorableColor.White
        } else {
            configuration.baseBackgroundColor = MemorableColor.Gray1
            configuration.baseForegroundColor = MemorableColor.Gray5
        }
        
        button.configuration = configuration
        button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func filterButtonTapped(_ sender: UIButton) {
        updateButtonState(sender, isSelected: true)
        currentFilterButton = sender
        currentCategory = sender.configuration?.title ?? "전체보기"
        updateCurrentDocuments()
    }
    
    private func updateButtonState(_ sender: UIButton, isSelected: Bool) {
        for view in filterStackView.arrangedSubviews {
            if let button = view as? UIButton {
                var config = button.configuration
                config?.baseBackgroundColor = MemorableColor.Gray1
                config?.baseForegroundColor = MemorableColor.Gray5
                button.configuration = config
            }
        }
        
        var config = sender.configuration
        config?.baseBackgroundColor = MemorableColor.Black
        config?.baseForegroundColor = MemorableColor.White
        sender.configuration = config
    }
    
    private func updateCurrentDocuments() {
        if currentFilterButton.configuration?.title == "전체보기" {
            filteredWorksheets = worksheets
        } else {
            filteredWorksheets = worksheets.filter { $0.category == currentFilterButton.configuration?.title }
        }
        
        worksheetTableView.reloadData()
    }
    
    private func setupSettingButton() {
        let image = UIImage(systemName: "ellipsis")?.withRenderingMode(.alwaysTemplate)
        
        settingButton.setImage(image, for: .normal)
        settingButton.tintColor = MemorableColor.Gray1
        
        let editAction = UIAction(title: "수정하기", image: UIImage(systemName: "pencil")) { _ in
            self.isModifying = true
            self.worksheetTableView.allowsMultipleSelection = false
            self.showActionSheet(title: "수정하기")
        }
        
        let deleteAction = UIAction(title: "삭제하기", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            self.isModifying = false
            self.worksheetTableView.allowsMultipleSelection = true
            self.showActionSheet(title: "삭제하기")
        }
        
        let menu = UIMenu(title: "", children: [editAction, deleteAction])
        
        settingButton.menu = menu
        settingButton.showsMenuAsPrimaryAction = true
    }
    
    private func showActionSheet(title: String) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        
        actionSheetView = EditActionSheetView(title: title)
        window.addSubview(actionSheetView!)
        
        actionSheetView?.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(window.snp.bottom)
            make.height.equalTo(100)
        }
        
        actionSheetView?.transform = CGAffineTransform(translationX: 0, y: 59)
        
        actionSheetView?.onCancel = { [weak self] in
            self?.hideActionSheet()
        }
        
        actionSheetView?.onConfirm = { [weak self] in
            if title == "삭제하기" {
                self?.deleteSelectedDocuments()
            }
            
            if title == "수정하기" {
                self?.modifySelectedDocument()
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.actionSheetView?.transform = .identity
        }
        
        // 액션 시트를 표시하면서 동시에 편집 모드 활성화
        toggleEditingMode()
    }
    
    func hideActionSheet() {
        UIView.animate(withDuration: 0.3, animations: {
            self.actionSheetView?.transform = CGAffineTransform(translationX: 0, y: 59)
        }) { _ in
            self.actionSheetView?.removeFromSuperview()
            self.actionSheetView = nil
            
            // 편집 모드 종료
            self.isEditingMode = false
            
            // 선택된 행 모두 선택 해제
            if let selectedRows = self.worksheetTableView.indexPathsForSelectedRows {
                for indexPath in selectedRows {
                    self.worksheetTableView.deselectRow(at: indexPath, animated: true)
                }
            }
        }
    }
    
    private func modifySelectedDocument() {
        print("파일 수정")
        guard let selectedIndexPath = worksheetTableView.indexPathForSelectedRow else { return }
        
        let documentToModify = filteredWorksheets[selectedIndexPath.row]
        
        let alert = UIAlertController(
            title: "파일명 수정",
            message: "새로운 파일명을 입력해주세요.",
            preferredStyle: .alert
        )
            
        alert.addTextField { textField in
            textField.text = documentToModify.name
            textField.placeholder = "새 파일명"
        }
            
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            print("취소하기")
        }
            
        let confirmAction = UIAlertAction(title: "확인", style: .default) { _ in
            guard let textField = alert.textFields?.first,
                  let newFileName = textField.text, !newFileName.isEmpty
            else {
                print("새 파일명이 비어있습니다.")
                return
            }
            print("이름 변경: \(newFileName)")
            
            // API 호출 등을 통해 서버에 변경사항을 반영해야 할 수 있습니다.
            self.delegate?.didModifyDocument(for: documentToModify, newName: newFileName)
            
            self.worksheetTableView.reloadData()
        }
            
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        
        if let viewController = window?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
        
        var isEditingMode: Bool = false {
            didSet {
                worksheetTableView.setEditing(isEditingMode, animated: true)
            }
        }
        hideActionSheet()
    }
    
    private func deleteSelectedDocuments() {
        guard let selectedRows = worksheetTableView.indexPathsForSelectedRows else { return }
        
        for indexPath in selectedRows {
            if indexPath.row < filteredWorksheets.count {
                let documentToDelete = filteredWorksheets[indexPath.row]
                delegate?.didDeleteDocuments(for: documentToDelete)
                
                filteredWorksheets.remove(at: indexPath.row)
                if let index = worksheets.firstIndex(where: { $0.id == documentToDelete.id }) {
                    worksheets.remove(at: index)
                }
            }
        }
        
        // 삭제 후 선택 해제 및 편집 모드 종료
        worksheetTableView.reloadData()
        isEditingMode = false
        hideActionSheet()
    }
    
    func selectCategory(_ category: String) {
        if let button = filterStackView.arrangedSubviews.first(where: { ($0 as? UIButton)?.configuration?.title == category }) as? UIButton {
            print(category)
            filterButtonTapped(button)
        }
    }
    
    func saveCurrentState() {
        lastDisplayType = currentDisplayType
        lastCategory = currentCategory
    }

    func restoreLastState() {
        if let lastDisplayType = lastDisplayType, let lastCategory = lastCategory {
            currentDisplayType = lastDisplayType
            currentCategory = lastCategory
            updateCurrentDocuments()
            selectCategory(lastCategory)
        }
    }
    
    func resetFilterButtonState() {
        selectCategory("전체보기")
    }
}

extension WorksheetListViewComponent: UITableViewDataSource, UITableViewDelegate, RecentsheetCellDelegate {
    func didTapBookmark<T: Document>(for document: T) {
        delegate?.didRequestBookmarkUpdate(for: document, inCategory: currentCategory, displayType: currentDisplayType)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredWorksheets.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorksheetTableViewCell", for: indexPath) as! RecentsheetCell
        let document = filteredWorksheets[indexPath.row]
        cell.configure(with: document)
        cell.delegate = self
        return cell
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditingMode {
            if isModifying {
                // 수정 모드일 때는 하나의 셀만 선택 가능
                for otherIndexPath in tableView.indexPathsForSelectedRows ?? [] {
                    if otherIndexPath != indexPath {
                        tableView.deselectRow(at: otherIndexPath, animated: false)
                    }
                }
            }
            print("Selected row: \(indexPath.row)")
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            let document = worksheets[indexPath.row]
                    
            saveCurrentState()
            
            switch document.fileType {
            case "빈칸학습지":
                if let worksheet = document as? Worksheet {
                    // Fetch WorksheetDetail before navigating
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
                            print("isMakeTestSheet: \(detail.isMakeTestSheet)")
                            
                            let workSheetVC = WorkSheetViewController()
                            self.delegate?.didTapWorksheetCell(inCategory: self.currentCategory, displayType: .worksheet)
                            WorkSheetManager.shared.worksheetDetail = detail
                            self.navigateToViewController(workSheetVC)
                        }
                    }
                }
            case "나만의 시험지":
                if let testsheet = document as? Testsheet {
                    APIManagere.shared.getTestsheet(testsheetId: testsheet.id) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let testsheetDetail):
                                let testSheetVC = TestSheetViewController()
                                self.delegate?.didTapWorksheetCell(inCategory: self.currentCategory, displayType: .testsheet)
                                testSheetVC.testsheetDetail = testsheetDetail
                                self.navigateToViewController(testSheetVC)
                            case .failure(let error):
                                print("Error fetching testsheet detail: \(error)")
                            }
                        }
                    }
                }
            case "오답노트":
                APIManager.shared.getData(to: "/api/wrongsheet/\(document.id)") { (sheetDetail: WrongsheetDetail?, error: Error?) in
                    DispatchQueue.main.async {
                        // 3. 받아온 데이터 처리
                        if let error = error {
                            print("Error fetching data: \(error.localizedDescription)")
                            return
                        }
                                            
                        guard let detail = sheetDetail else {
                            print("No data received")
                            return
                        }
                                            
                        // wrong sheet detail
                        print("GET: \(detail.name)")
                        print("GET: \(detail.category)")
                        print("GET: \(detail.questions)")
                        
                        let wrongSheetVC = WrongSheetViewController()
                        self.delegate?.didTapWorksheetCell(inCategory: self.currentCategory, displayType: .worksheet)
                        wrongSheetVC.wrongsheetDetail = detail
                        self.navigateToViewController(wrongSheetVC)
                    }
                }
            default:
                print("Unknown file type")
            }
        }
    }
        
    private func navigateToViewController(_ viewController: UIViewController) {
        if let navigationController = window?.rootViewController as? UINavigationController {
            navigationController.pushViewController(viewController, animated: true)
        } else if let presentingViewController = window?.rootViewController {
            presentingViewController.present(viewController, animated: true, completion: nil)
        }
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = next as? UIViewController {
            return nextResponder
        } else if let nextResponder = next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}


