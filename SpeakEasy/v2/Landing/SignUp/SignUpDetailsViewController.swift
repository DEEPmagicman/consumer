import UIKit
import MHLoadingButton

class SignUpDetailsViewController: UIViewController {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var signUpBtn: LoadingButton!
    
    var email: String?
    var dob: String?
    var gender: String?
    var presenter = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickSignUpBtn(_ sender: Any) {
        confirmDetail()
    }
    
    func confirmDetail() {
        signUpBtn.showLoader(userInteraction: false)
        self.view.isUserInteractionEnabled = false
        
        var date = dob?.convertDateFormat(from: .MMMMDDYYYY, to: .YYYYMMDD, isUTC: false) ?? ""
        presenter.editUserProfileApi(
            fName: firstNameTextField.text ?? "",
            lName: lastNameTextField.text ?? "",
            nickName: "",
            email: email,
            dob: date,
            gender: gender
        ) { [weak self] isSuccess, errorMsg in
            
            guard let self = self else { return }
            
            self.signUpBtn.hideLoader()
            self.view.isUserInteractionEnabled = true
            
            if isSuccess {
                UserDefault.shared.user?.firstName = self.firstNameTextField.text ?? ""
                UserDefault.shared.user?.lastName = self.lastNameTextField.text ?? ""
                UserDefault.shared.user?.dateOfBirth = self.dob ?? ""
                UserDefault.shared.user?.email = self.email ?? ""
                UserDefault.shared.user?.gender = self.gender ?? ""
                
                Navigate.to.setProfilePicVc(self)
            } else {
                let message = errorMsg ?? Constant.String.somethingWrong
                Alert.showAlertSheet(style: .alert, title: message, message: "")
            }
        }
    }
}
