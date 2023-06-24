import UIKit

protocol IViewControllerDelegate: AnyObject {
    func save(with: TodoViewModel)
    func remove(with: TodoViewModel)
}
class ViewController: UIViewController,UIScrollViewDelegate, IRemoveDelegate {
    
    //MARK: - Constants
    enum Constraints {
        static let scrollViewTopAnchorConstraintConstant: CGFloat = 16
    }
    enum Constants {
        static let navigationBarElementsFontSize: CGFloat = 17
    }
    
    //MARK: - Initializer
    
    init(presenter: TodoPresenter) {
        self.presenter = presenter
        self.delegate = presenter
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: - Configuration
    
    enum StackViewConfiguration {
        static let stackViewLayoutLeftMargin: CGFloat = 16
        static let stactViewLayoutRightMargin: CGFloat = 16
        static let stackViewLayoutTopMargin: CGFloat = 0
        static let stackViewLayoutBottomMargin: CGFloat = 0
        static let stackViewSpacing: CGFloat = 16
    }
    
    // MARK: - Dependencies
    
    private let presenter:  TodoPresenter
    var todoViewModel: TodoViewModel?
    weak var delegate: IViewControllerDelegate?
    private var scrollConstraint: [NSLayoutConstraint] = []
    private lazy var tapGesture = UITapGestureRecognizer(target: self,
                                                         action: #selector(self.dismissKeyboard (_:)))
    //MARK: - UI
    
    private var scrollView = UIScrollView()
    private let txtView: TextView = TextView(frame: .zero)
    private let removeView: RemoveView = RemoveView(frame: .zero)
    private let settingsView: SettingsView = SettingsView(frame: .zero)
    private  var cancelButton =  UIButton(type: .system)
    private  var saveButton =  UIButton(type: .system)
    private lazy var stackView: UIStackView = {
        let stackView   = UIStackView()
        stackView.axis  = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = .fill //UIStackView.Alignment.center
        stackView.spacing   = StackViewConfiguration.stackViewSpacing
        return stackView
        
    }()
    
    // MARK: - Configuration
    
    func setupWithViewModel(model: TodoViewModel) {
        self.todoViewModel = model
        self.txtView.configureText(with: model.text)
        self.settingsView.setPriority(with: model.priority.rawValue)
        if let deadline = model.deadline {
            self.settingsView.setDeadline(with: deadline)
        }
        if let hexCode = model.hexCode {
            self.settingsView.setHexCode(code: hexCode)
        }
        
    }
    func setupWithNewModel() {
        self.todoViewModel = TodoViewModel(id: UUID().uuidString,
                                           text: "", deadline: nil,
                                           isDone: false,
                                           hexCode: nil,
                                           priority: .normal,
                                           dateCreated: Date(),
                                           dateChanged: nil)
    }
    func removeItem() {
        if let todoViewModel {
            delegate?.remove(with: todoViewModel).self
        }
    }
    func saveState()
    {
        self.todoViewModel?.text =  txtView.getText()
        self.todoViewModel?.deadline = settingsView.getDeadline()
        self.todoViewModel?.priority = TodoItem.Priority(rawValue: settingsView.getPriorityRawValue()) ?? .normal
        self.todoViewModel?.dateChanged = Date()
        self.todoViewModel?.hexCode = settingsView.getHexCode()
        if let todoViewModel {
            delegate?.save(with: todoViewModel).self
        }
    }
    
    // MARK: - Viewdidload
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
        configure()
        setupConstraints()
    }
    
    // MARK: - Configuration
    
    func configure() {
        
        self.view.backgroundColor = Colors.backPrimary.value
        setupNavigationBar()
        configureStackView()
        registerKeyboardNotifications()
        setDelegate()
    }
    
    func setDelegate() {
        self.scrollView.delegate = self
        self.removeView.delegate = self
        settingsView.delegate = self
    }
    
    func addGestureRecognizer() {
        self.view.addGestureRecognizer(tapGesture)
    }
    func removeGesture() {
        self.view.removeGestureRecognizer(tapGesture)
    }
    
    // MARK: - Setup NavBar
    
    func setupNavigationBar() {
        cancelButton.setTitle("Отменить", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        cancelButton.tintColor = Colors.colorBlue.value
        saveButton.titleLabel?.font = .systemFont(ofSize: Constants.navigationBarElementsFontSize)
        
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTodo), for: .touchUpInside)
        saveButton.isEnabled = false
        saveButton.tintColor = Colors.colorBlue.value
        saveButton.titleLabel?.font = .boldSystemFont(ofSize: Constants.navigationBarElementsFontSize)
        
        
        let priorityLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 1
            label.text = "Дело"
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
            label.textColor = Colors.labelPrimary.value
            label.font = .systemFont(ofSize: Constants.navigationBarElementsFontSize, weight: .semibold)
            
            return label
        }()

        navigationItem.titleView = priorityLabel
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
    }
    
    
    // MARK: - Setup StackView
    
    func configureStackView() {
        
        stackView.layoutMargins = UIEdgeInsets(top: StackViewConfiguration.stackViewLayoutTopMargin,
                                               left: StackViewConfiguration.stackViewLayoutLeftMargin,
                                               bottom: StackViewConfiguration.stackViewLayoutBottomMargin,
                                               right: StackViewConfiguration.stactViewLayoutRightMargin)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        stackView.addArrangedSubview(txtView)
        stackView.addArrangedSubview(settingsView)
        stackView.addArrangedSubview(removeView)
    }
    
    // MARK: - Setup Constraints
    
    func setupConstraints() {
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        setupScrollViewConstraints()
        setupStackViewConstraints()
    }
    
    func setupScrollViewConstraints() {
        scrollConstraint =  [
            scrollView.bottomAnchor.constraint(equalTo: (view.bottomAnchor)),
        ]
        NSLayoutConstraint.activate(scrollConstraint)
        let constraints = [
            scrollView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: (view.leadingAnchor)),
            scrollView.trailingAnchor.constraint(equalTo: (view.trailingAnchor)),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func setupStackViewConstraints() {
        let constraints = [
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor,
                                           constant: Constraints.scrollViewTopAnchorConstraintConstant),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
}

// MARK: - Buttons

extension ViewController: IScrollDelegate {

    func userTappedRemove() {
        removeItem()
        self.dismiss(animated: true)
    }
    func userTapDate() {
        scrollView.addObserver(self,
                               forKeyPath: "contentSize",
                               options: .new, context: nil)
    }

    @objc private func saveTodo() {
        saveState()
        self.dismiss(animated: true)
    }

    @objc private func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Keyboard

extension ViewController {
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if let obj = object as? UIScrollView {
            if obj == self.scrollView && keyPath == "contentSize" {
                if scrollView.contentSize.height
                    + self.view.safeAreaInsets.bottom
                    + self.view.safeAreaInsets.top
                    > scrollView.visibleSize.height{

                    let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.height + self.view.safeAreaInsets.bottom)
                    scrollView.setContentOffset(bottomOffset, animated: true)
                }
                removeObsrvers()
            }
        }
    }

    private func removeObsrvers() {
        scrollView.removeObserver(self, forKeyPath: "contentSize")
    }
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIControl.keyboardWillShowNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        addGestureRecognizer()
        guard notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] is NSValue else { return }
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            scrollConstraint.first?.constant = -keyboardHeight
            self.view.layoutIfNeeded()
        }
    }

    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        txtView.resign()
        DispatchQueue.main.async {
            self.scrollConstraint.first?.constant = 0
            self.view.layoutIfNeeded()
        }
        self.view.layoutIfNeeded()
        removeGesture()
    }
}