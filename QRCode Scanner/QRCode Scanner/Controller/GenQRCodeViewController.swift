import UIKit
import IQKeyboardManagerSwift

class GenQRCodeViewController: UIViewController {

    @IBOutlet weak var qrcodeImageView:UIImageView!
    @IBOutlet weak var urlTextField:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addCloseBtnOnKeyBoard()
    }
    
    func addCloseBtnOnKeyBoard() {
        let doneBtn = UIBarButtonItem(title: "關閉", style: .done, target: self, action: #selector(closeBtnAction))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneToolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolBar.barStyle = .default
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(doneBtn)
        doneToolBar.items = items
        doneToolBar.sizeToFit()
        self.urlTextField.inputAccessoryView = doneToolBar
    }
    @objc func closeBtnAction() {
        self.urlTextField.resignFirstResponder()
    }
    
    @IBAction func genQRCode(_ sender: Any) {
        let data = self.urlTextField.text?.data(using: .isoLatin1)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        qrcodeImageView.image = UIImage(ciImage: (filter?.outputImage)!)
    }
}
