import UIKit
import AVFoundation
import SafariServices

class ViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet weak var cameraView:UIView!
    @IBOutlet weak var qrcodeURL:UILabel!
    
    var captureSession:AVCaptureSession?
    var captureVideoPreviewLayer:AVCaptureVideoPreviewLayer!
    var qrcodeString:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //判斷 AVCaptureSession 的接收器是否正在執行
        if(captureSession?.isRunning == false){
            captureSession?.startRunning()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        scanQRCode()
    }
    
    func scanQRCode(){
        captureSession = AVCaptureSession() //實例化一個 AVCaptureSession 物件
        
        //透過 AVCaptureDevice 來捕捉相機及其相關屬性
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        let videoInput:AVCaptureDeviceInput
        do{
           videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        }catch{
            print(error)
            return
        }
        
        //判斷是否可以將 videoInput 加入到 captureSession
        if(captureSession?.canAddInput(videoInput) ?? false){
            captureSession?.addInput(videoInput)
        }else{
            return
        }
        
        let metaDataOutput = AVCaptureMetadataOutput() //實例化一個 AVCaptureMetadataOutput 物件
        //透過 AVCaptureMetadataOutput 輸出資料
        //判斷是否可以將 metaDataOutput 輸出到 captureSession
        if(captureSession?.canAddOutput(metaDataOutput) ?? false){
            captureSession?.addOutput(metaDataOutput)
            metaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main) //執行處理 QRCode
            metaDataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417] //設定可以處理哪些類型的條碼
        }else{
            return
        }
        
        //用 AVCaptureVideoPreviewLayer 來呈現 AVCaptureSession 的資料
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        captureVideoPreviewLayer.videoGravity = .resizeAspectFill
        captureVideoPreviewLayer.frame = cameraView.layer.frame
        view.layer.addSublayer(captureVideoPreviewLayer)
        captureSession?.startRunning()
    }
    
    //使用 AVCaptureMetadataOutput 物件辨識 QRCode，AVCaptureMetadataOutputObjectsDelegate 裡的委派方法 metadataOutout 會被呼叫
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first{
            //AVMetadataMachineReadableCodeObject 是從 Output 擷取到 Barcode 的內容
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                return
            }
            //將讀取到的內容轉成字串
            guard let stringValue = readableObject.stringValue else {
                return
            }
            qrcodeURL.text = stringValue
            qrcodeString = stringValue
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(captureSession?.isRunning == true){
            captureSession?.stopRunning()
        }
    }

    @IBAction func QRCodeActionSheet(_ sender: Any) {
        self.alertFunction()
    }
    
    func alertFunction() {
        let alertController = UIAlertController(title: "請選取功能", message: "", preferredStyle: .actionSheet)
        let cleanURLAction = UIAlertAction(title: "清除 URL", style: .default) { (action) in
            self.qrcodeString.removeAll()
            self.qrcodeURL.text = ""
        }
        let openWebSiteAction = UIAlertAction(title: "開啟網頁", style: .default) { (action) in
            let url = URL(string:self.qrcodeString)
            let safariViewController = SFSafariViewController(url: url!)
            self.present(safariViewController,animated: true)
        }
        let openPhotoLibraryAction = UIAlertAction(title: "從照片讀取", style: .default) { (action) in
            let photoController = UIImagePickerController()
            photoController.delegate = self
            photoController.sourceType = .photoLibrary
            self.present(photoController,animated: true)
        }
        let cancelAction = UIAlertAction(title: "關閉", style: .cancel, handler: nil)
        alertController.addAction(cleanURLAction)
        alertController.addAction(openWebSiteAction)
        alertController.addAction(openPhotoLibraryAction)
        alertController.addAction(cancelAction)
        self.present(alertController,animated: true)
    }
    
    //讀取照片上的 QRCode
    //透過 CIDetector 來識別圖片上的 QRCode
    //CIDetectorTypeQRCode 可以檢測到 QRCode
    //CIDetectorAccuracy 用來設定檢測到的 QRCode 的精準度，CIDetectorAccuracyLow → 速度快精準度低，CIDetectorAccuracyHigh → 速度慢精準度高
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
              let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]),
              let ciImage = CIImage(image: pickedImage),
            let features = detector.features(in: ciImage) as? [CIQRCodeFeature] else {
            return
        }
        let qrcodeLink = features.reduce(""){ $0 + ($1.messageString ?? "")}
        qrcodeURL.text = qrcodeLink
        qrcodeString = qrcodeLink
        picker.dismiss(animated: true, completion: nil)
    }
}

//參考來源
//https://medium.com/%E5%BD%BC%E5%BE%97%E6%BD%98%E7%9A%84-swift-ios-app-%E9%96%8B%E7%99%BC%E6%95%99%E5%AE%A4/qrcode%E6%8E%83%E8%B5%B7%E4%BE%86-24e086df902c

//AVCaptureSession Apple 官方開發者文件
//https://developer.apple.com/documentation/avfoundation/avcapturesession
//UIImagePickerController.InfoKey Apple 官方開發者文件
//https://developer.apple.com/documentation/uikit/uiimagepickercontroller/infokey
//CIDetector Apple 官方開發者文件
//https://developer.apple.com/documentation/coreimage/cidetector
//CIQRCodeFeature Apple 官方開發者文件
//https://developer.apple.com/documentation/coreimage/ciqrcodefeature
