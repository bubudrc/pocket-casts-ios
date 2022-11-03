import UIKit
import PocketCastsUtils
import PocketCastsServer
import AuthenticationServices

class ProfileIntroViewController: PCViewController, SyncSigninDelegate {
    weak var upgradeRootViewController: UIViewController?

    private var buttonFont: UIFont {
        UIFont.font(ofSize: 18, weight: .semibold, scalingWith: .body, maxSizeCategory: .extraExtraLarge)
    }

    @IBOutlet var errorLabel: ThemeableLabel! {
        didSet {
            errorLabel.style = .support05
            errorLabel.font = UIFont.font(with: .subheadline, maxSizeCategory: .extraExtraLarge)
            hideError()
        }
    }

    @IBOutlet var createAccountBtn: ThemeableRoundedButton! {
        didSet {
            createAccountBtn.setTitle(L10n.createAccount, for: .normal)
            createAccountBtn.titleLabel?.font = buttonFont
        }
    }

    @IBOutlet var authenticationProviders: UIStackView!
    @IBOutlet var signInBtn: ThemeableRoundedButton! {
        didSet {
            signInBtn.isHidden = FeatureFlag.signInWithApple
            signInBtn.setTitle(L10n.signIn, for: .normal)
            signInBtn.shouldFill = false
            signInBtn.titleLabel?.font = buttonFont
        }
    }

    @IBOutlet var passwordAuthOption: ThemeableUIButton! {
        didSet {
            passwordAuthOption.isHidden = !FeatureFlag.signInWithApple
            passwordAuthOption.setTitle(L10n.accountLogin, for: .normal)
            passwordAuthOption.titleLabel?.font = buttonFont
        }
    }

    @IBOutlet var profileIllustration: UIImageView! {
        didSet {
            profileIllustration.image = UIImage(named: AppTheme.setupNewAccountImageName())
        }
    }

    @IBOutlet var signOrCreateLabel: ThemeableLabel! {
        didSet {
            signOrCreateLabel.text = L10n.signInPrompt
            signOrCreateLabel.style = .primaryText01
            signOrCreateLabel.font = UIFont.font(with: .title2, weight: .bold, maxSizeCategory: .accessibilityMedium)
        }
    }

    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.text = L10n.signInMessage
            infoLabel.style = .primaryText02
            infoLabel.font = UIFont.font(ofSize: 18, weight: .medium, scalingWith: .body, maxSizeCategory: .accessibilityMedium)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.setupAccount
        showPocketCastsLogoInTitle()

        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(doneTapped))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton

        handleThemeChanged()
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        setupProviderLoginView()

        Analytics.track(.setupAccountShown)
    }

    override func handleThemeChanged() {
        profileIllustration.image = UIImage(named: AppTheme.setupNewAccountImageName())
    }

    @objc private func doneTapped() {
        closeWindow()
    }

    private func closeWindow(completion: (() -> Void)? = nil) {
        dismiss(animated: true, completion: completion)
        AnalyticsHelper.createAccountDismissed()
        Analytics.track(.setupAccountDismissed)
    }

    // MARK: - SyncSigninDelegate

    func signingProcessCompleted() {
        closeWindow {
            if let presentingController = self.upgradeRootViewController {
                let newSubscription = NewSubscription(isNewAccount: false, iap_identifier: "")
                presentingController.present(SJUIUtils.popupNavController(for: TermsViewController(newSubscription: newSubscription)), animated: true)
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }

    @IBAction func signInTapped() {
        hideError()

        let signinPage = SyncSigninViewController()
        signinPage.delegate = self

        navigationController?.pushViewController(signinPage, animated: true)

        AnalyticsHelper.createAccountSignIn()
        Analytics.track(.setupAccountButtonTapped, properties: ["button": "sign_in"])
    }

    @IBAction func createTapped() {
        let selectAccountVC = SelectAccountTypeViewController()
        navigationController?.pushViewController(selectAccountVC, animated: true)

        AnalyticsHelper.createAccountConfirmed()

        Analytics.track(.setupAccountButtonTapped, properties: ["button": "create_account"])
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait // since this controller is presented modally it needs to tell iOS it only goes portrait
    }
private extension ProfileIntroViewController {
    func showPocketCastsLogoInTitle() {
        let imageView = ThemeableImageView(frame: .zero)
        imageView.imageNameFunc = AppTheme.pcLogoSmallHorizontalImageName
        imageView.accessibilityLabel = title

        navigationItem.titleView = imageView
    }

    func hideError() {
        errorLabel.alpha = 0
        errorLabel.text = nil
    }

    func showError(_ error: Error? = nil) {
        if let error {
            FileLog.shared.addMessage("Failed to connect SSO account: \(error.localizedDescription)")
        }

        errorLabel.text = L10n.accountSsoFailed
        errorLabel.alpha = 1
    }
}

// MARK: - Apple Auth
extension ProfileIntroViewController {
    func setupProviderLoginView() {
        guard FeatureFlag.signInWithApple else { return }

        let authorizationButton = ASAuthorizationAppleIDButton(type: .continue, style: .whiteOutline)
        authorizationButton.cornerRadius = createAccountBtn.cornerRadius
        authorizationButton.addTarget(self, action: #selector(handleAppleAuthButtonPress), for: .touchUpInside)
        authorizationButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        authenticationProviders.insertArrangedSubview(authorizationButton, at: 0)
    }

    @objc
    func handleAppleAuthButtonPress() {
        errorLabel.isHidden = true
    private func handleAppleAuthButtonPress() {
        hideError()

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension ProfileIntroViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = view.window else { return UIApplication.shared.windows.first! }
        return window
    }
}

extension ProfileIntroViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            DispatchQueue.main.async {
                self.handleAppleIDCredential(appleIDCredential)
            }
        default:
            break
        }
    }

    func handleAppleIDCredential(_ appleIDCredential: ASAuthorizationAppleIDCredential) {
        let progressAlert = ShiftyLoadingAlert(title: L10n.syncAccountLogin)
        progressAlert.showAlert(self, hasProgress: false, completion: {
            Task {
                var success = false
                do {
                    try await AuthenticationHelper.validateLogin(appleIDCredential: appleIDCredential)
                    success = true
                } catch {
                    DispatchQueue.main.async {
                        self.showError(error)
                    }
                }

                DispatchQueue.main.async {
                    progressAlert.hideAlert(false)
                    if success {
                        self.signingProcessCompleted()
                    }
                }
            }
        })
    }
}
