//
//  ViewController.swift
//  taurine
//
//  Created by 23 Aaron on 28/02/2021.
//

import UIKit
import MachO.dyld

class ViewController: UIViewController, OlVerUI {
    
    var navi: OlVer?
    
    fileprivate var scrollAnimationClosures: [() -> Void] = []
    private var popClosure: DispatchWorkItem?
    
    @IBOutlet weak var view_bootstrap_navi: UIView!
    @IBOutlet weak var view_bootstrap_procurs: UIView!
    @IBOutlet weak var bootstra_navi: UISwitch!
    @IBOutlet weak var bootstrap_procurs: UISwitch!
    @IBOutlet weak var view_chon_anh: PanelButton!
    @IBOutlet weak var view_set_anh: SelectionButton!
    @IBOutlet weak var view_rootfs: UIView!
    @IBOutlet weak var view_tweak: UIView!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var text_view: UITextView!
    @IBOutlet weak var text_blur: UITextView!
    @IBOutlet weak var view_caidat: UIButton!
    @IBOutlet weak var sever: UILabel!
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var view_exit: UIButton!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var view_loading: UIView!
    @IBOutlet weak var setting: UIView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var backgroundOverlay: UIView!
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var jailbreakButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var vibrancyView: UIVisualEffectView!
    @IBOutlet weak var updateOdysseyView: UIVisualEffectView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var switchesView: PanelStackView!
    
    @IBOutlet weak var themeCopyrightButton: UIButton!
    
    @IBOutlet weak var enableTweaksSwitch: UISwitch!
    @IBOutlet weak var restoreRootfsSwitch: UISwitch!
    @IBOutlet weak var logSwitch: UISwitch!
    @IBOutlet weak var nonceSetter: TextButton!
    
    @IBOutlet weak var containerViewYConstraint: NSLayoutConstraint!
    
    private var themeImagePicker: ThemeImagePicker!
    private var activeColourDefault = ""
    private let colorPickerViewController = UIColorPickerViewController()
    
    private var currentView: (UIView & PanelView)?
    let namedevice = UIDevice.modelName
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This will reset user defaults, used it a lot for testing
        /*
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        */
        
        view_loading.alpha = 0
       // self.version.text = "Phiên bản: V1.0~a"
        self.version.text = "NaVi: V\(Bundle.main.infoDictionary!["CFBundleShortVersionString"] ?? "")"
        self.sever.text = "Sever: a15~bt19"
        self.view_set_anh.backgroundColor = UIColor.white
        self.view_chon_anh.backgroundColor = UIColor.white
        
        self.jailbreakButton.layer.cornerRadius = 12
        self.view_exit.layer.cornerRadius = 12
        self.view_tweak.layer.cornerRadius = 12
        self.view_rootfs.layer.cornerRadius = 12
        self.view_set_anh.layer.cornerRadius = 12
        self.view_chon_anh.layer.cornerRadius = 12
        self.nonceSetter.layer.cornerRadius = 12
        self.text_view.layer.cornerRadius = 12
        self.text_blur.layer.cornerRadius = 12
        self.view_loading.layer.cornerRadius = 12
        self.view_bootstrap_procurs.layer.cornerRadius = 12
        self.view_bootstrap_navi.layer.cornerRadius = 12
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterialDark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.text_blur.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.text_blur.addSubview(blurEffectView)
        
        sys_init()
        print_os_details()
        text_view.text = String(format: "[+] Thiết bị: \(namedevice) (%s)\n[+] Phiên bản: iOS %s (%s)\n[+] Model: %s\n[+] Page Size: %#llx\n[+] Ram Size: %.1f MB\n[+] Kernel Version: %s\n[+] Uptime: %d ngày ", g_exp.machine, g_exp.osproductversion, g_exp.osversion, g_exp.model, g_exp.pagesize, Double(g_exp.physmemsize) / 1024.0 / 1024.0, g_exp.kern_version, Int(getUptime()) / 86400)
        
        currentView = switchesView
        nonceSetter.delegate = NonceManager.shared
       
            jailbreakButton?.isEnabled = true
            jailbreakButton?.setTitle("Jailbreak", for: .normal)
        
        
        
        if #available(iOS 14.4, *) {
            jailbreakButton?.isEnabled = false
            jailbreakButton?.setTitle("Unsupported", for: .normal)
        }
        
        if isJailbroken() {
            jailbreakButton?.isEnabled = false
            jailbreakButton?.setTitle("Jailbroken", for: .normal)
        }
        
        if getSafeEntitlements().count < 3 {
            
            jailbreakButton.isEnabled = false
            jailbreakButton.setTitle("Sanity Check Failed", for: .normal)
        }
        
        let updateTapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(shouldOpenUpdateLink))
        updateOdysseyView.addGestureRecognizer(updateTapGestureRecogniser)
        
        AppVersionManager.shared.doesApplicationRequireUpdate { result in
            switch result {
            case .failure(let error):
                print(error)
                return
            
            case .success(let updateRequired):
                if (updateRequired) {
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.5) {
                            self.updateOdysseyView.isHidden = false
                        }
                    }
                }
            }
        }
       
        
        self.themeImagePicker = ThemeImagePicker(presentationController: self, delegate: self)
        colorPickerViewController.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: ThemesManager.themeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showColourPicker(_:)), name: ColourPickerCell.showColourPicker, object: nil)
        self.updateTheme()
    }
    
    @objc private func shouldOpenUpdateLink() {
        AppVersionManager.shared.launchBestUpdateApplication()
    }
    @objc func reload() {
        guard let log = LogStream.shared.outputString.copy() as? NSAttributedString else {
            return
        }
        ObjcTryCatch {
            self.text_view.attributedText = log
            self.text_view.font = UIFont.monospacedSystemFont(ofSize: 0, weight: .regular)
            if log.string.count > 1 {
                self.text_view.scrollRangeToVisible(NSRange(location: log.string.count - 1, length: 1))
            }
            self.text_view.setNeedsDisplay()
        }
    }
    
    @objc func updateTheme() {
        let custom = UserDefaults.standard.string(forKey: "theme") == "custom"
        let customColour = UserDefaults.standard.string(forKey: "theme") == "customColourTheme"
        let theme = ThemesManager.shared.currentTheme
        
        let bgImage: UIImage?
        if custom {
            guard let customImage = ThemesManager.shared.customImage else {
                photoLibrary(nil)
                return
            }
            bgImage = customImage
        } else {
            bgImage = ThemesManager.shared.currentTheme.backgroundImage
        }
        
        if let bgImage = bgImage {
            if custom {
                backgroundImage.image = bgImage
            } else {
                let aspectHeight = self.view.bounds.height
                let aspectWidth = self.view.bounds.width
                    
                let maxDimension = max(aspectHeight, aspectWidth)
                let isiPad = UIDevice.current.userInterfaceIdiom == .pad
                
                backgroundImage.image = ImageProcess.sizeImage(image: bgImage,
                                                               aspectHeight: isiPad ? maxDimension : aspectHeight,
                                                               aspectWidth: isiPad ? maxDimension : aspectWidth,
                                                                center: ThemesManager.shared.currentTheme.backgroundCenter)
            }
        } else {
            backgroundImage.image = nil
        }
        
        if custom || customColour {
            vibrancyView.isHidden = !ThemesManager.shared.customThemeBlur
        } else {
            vibrancyView.isHidden = !theme.enableBlur
        }
        
        backgroundOverlay.backgroundColor = theme.backgroundOverlay ?? UIColor.clear
        themeCopyrightButton.isHidden = theme.copyrightString.isEmpty
        
   //     jailbreakButton.setGradient(colors: theme.progressGradientColors, delta: theme.progressGradientDelta)
    }
    
    func updateinfo(_ title: String) {
        DispatchQueue.main.async {
            self.info.text = title
        }
    }
    
    func showAlert(_ title: String, _ message: String, sync: Bool, callback: (() -> Void)? = nil, yesNo: Bool = false, noButtonText: String? = nil) {
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: yesNo ? "Yes" : "OK", style: .default) { _ in
                if let callback = callback {
                    callback()
                }
                if sync {
                    sem.signal()
                }
            })
            if yesNo {
                alertController.addAction(UIAlertAction(title: noButtonText ?? "No", style: .default) { _ in
                    if sync {
                        sem.signal()
                    }
                })
            }
            (self.presentedViewController ?? self).present(alertController, animated: true, completion: nil)
        }
        if sync {
            sem.wait()
        }
    }
    @IBAction func exit_update(_ sender: Any) {
        self.updateOdysseyView.alpha = 0

    }

    
    @IBAction func jailbreak() {
        jailbreakButton?.isEnabled = false
        containerView.isUserInteractionEnabled = false
        self.view_caidat.isEnabled = false
        UIApplication.shared.isIdleTimerDisabled = true
        self.jailbreakButton.setTitle("Jailbreaking...", for: .normal)
        self.info.text = "Đang tải dữ liệu"
        self.view_loading.alpha = 1

        if self.logSwitch.isOn {
            UIView.animate(withDuration: 0.5) {
                self.containerView.alpha = 0.3
            }
            self.performSegue(withIdentifier: "logSegue", sender: self.jailbreakButton)
        } else {
            UIView.animate(withDuration: 0.5) {
                self.containerView.alpha = 0.5
            }
        }
     //   self.jailbreakButton.setTitle("Running Exploit.. 1/3", for: .normal)
      //  self.jailbreakButton.setProgress(0.33, animated: true)
        
        let enableTweaks = self.enableTweaksSwitch.isOn
        let restoreRootFs = self.restoreRootfsSwitch.isOn
        let procurs_bootstrap = self.bootstrap_procurs.isOn
        let navi_bootstrap = self.bootstra_navi.isOn
        let generator = NonceManager.shared.currentValue
        #if targetEnvironment(simulator)
        let simulateJailbreak = true
        #else
        let simulateJailbreak = false
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DispatchQueue.global(qos: .userInteractive).async {
                usleep(500 * 1000)
                
                if simulateJailbreak {
                    sleep(1)
                    DispatchQueue.main.async {
              //          self.jailbreakButton.setTitle("Jailbreaking.. 2/3", for: .normal)
                     //   self.jailbreakButton.setProgress(0.4, animated: true)
                    }
                    var outStream = StandardOutputStream.shared
                    var errStream = StandardErrorOutputStream.shared
                    print("Testing log", to: &outStream)
                    print("Testing stderr", to: &errStream)
                    
                    sleep(2)
                    DispatchQueue.main.async {
               //         self.jailbreakButton.setTitle("Jailbreaking.. 3/3", for: .normal)
                       // self.jailbreakButton.setProgress(0.8, animated: true)
                    }
                    print("Testing log2", to: &outStream)
                    print("Testing stderr2", to: &errStream)
                    
                    sleep(1)
                    DispatchQueue.main.async {
                        self.jailbreakButton.setTitle("Jailbroken", for: .normal)
                      //  self.jailbreakButton.setProgress(1.0, animated: true)
                    }
                    print("Testing log3", to: &outStream)
                    print("Testing stderr3", to: &errStream)
                    
                    self.showAlert("Test alert", "Testing an alert message", sync: true)
                    print("Alert done")
                    
                    return
                }
                
                if #available(iOS 14.4, *) {
                    fatalError("Unable to get kernel r/w")
                }
                
                var hasKernelRw = false
                var any_proc = UInt64(0)
                
                if #available(iOS 14, *){
                    self.updateinfo("Đang chạy khai thác")
                    print("Selecting cicuta_virosa for iOS 14.0 - 14.3")
                    if cicuta_virosa() == 0 {
                        any_proc = our_proc_kAddr
                        hasKernelRw = true
                    }
                }
                guard hasKernelRw else {
                    DispatchQueue.main.async {
                       // self.jailbreakButton.setTitle("Error: Exploit Failed", for: .normal)
                       // self.jailbreakButton.setProgress(0, animated: true)
                        self.updateinfo("Khai thác thất bại")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                 //   self.jailbreakButton.setTitle("Please Wait... 2/3", for: .normal)
                  //  self.jailbreakButton.setProgress(0.66, animated: true)
                }
                let navi = OlVer(ui: self,
                                      any_proc: any_proc,
                                      enable_tweaks: enableTweaks,
                                      restore_rootfs: restoreRootFs,
                                 procurs: procurs_bootstrap,
                                 navi_boot: navi_bootstrap,
                                      nonce: generator)
                self.navi = navi
                let err = navi.jailbreak()
                
                DispatchQueue.main.async {
                  //  self.jailbreakButton.setProgress(1.0, animated: true)
                    if err != .ERR_NOERR {
                        self.info.textColor = UIColor.red
                        self.updateinfo("\(String(describing: err))")
                        self.jailbreakButton.setTitle("Lỗi", for: .normal)
                        self.jailbreakButton.setTitleColor(UIColor.red, for: .normal)
                    }
                }
            }
        }
    }
    
    func popCurrentView(animated: Bool) {
        guard let currentView = currentView,
            !currentView.isRootView else {
            return
        }
        let scrollView: UIScrollView = self.scrollView
        if !animated {
            currentView.isHidden = true
            scrollView.contentSize = CGSize(width: currentView.parentView.frame.maxX, height: scrollView.contentSize.height)
        } else {
            scrollAnimationClosures.append {
                currentView.parentView.viewShown()
                currentView.isHidden = true
                scrollView.contentSize = CGSize(width: currentView.parentView.frame.maxX, height: scrollView.contentSize.height)
            }
        }
        self.currentView = currentView.parentView
        scrollView.scrollRectToVisible(currentView.parentView.frame, animated: animated)
        
        if !currentView.parentView.isRootView {
            self.resetPopTimer()
        }
    }
    
    func resetPopTimer() {
        self.popClosure?.cancel()
        let popClosure = DispatchWorkItem {
            self.popCurrentView(animated: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: popClosure)
        self.popClosure = popClosure
    }
    
    func cancelPopTimer() {
        self.popClosure?.cancel()
        self.popClosure = nil
    }
    @IBAction func mo_caidat(_ sender: Any) {
        UIView.animate(withDuration: 0.25){
            self.setting.alpha = 1
            self.jailbreakButton.alpha = 0
            self.view_caidat.alpha = 0
            self.sever.alpha = 0
            self.version.alpha = 0
            self.view_loading.alpha = 0
    }
    }
    @IBAction func thoat_caidat(_ sender: Any) {
        UIView.animate(withDuration: 0.25){
            self.setting.alpha = 0
            self.jailbreakButton.alpha = 1
            self.view_caidat.alpha = 1
            self.sever.alpha = 1
            self.version.alpha = 1
           // self.view_loading.alpha = 1
    }
    }
    
    @IBAction func showPanel(button: PanelButton) {
        let userInteractionEnabled = scrollView.isUserInteractionEnabled
        scrollView.isUserInteractionEnabled = false
        
        button.childPanel.isHidden = false
        self.currentView = button.childPanel
        
        scrollAnimationClosures.append {
            button.childPanel.viewShown()
            self.scrollView.isUserInteractionEnabled = userInteractionEnabled
        }
        
        scrollView.contentSize = CGSize(width: button.childPanel.frame.maxX, height: scrollView.contentSize.height)
        scrollView.scrollRectToVisible(button.childPanel.frame, animated: true)
        self.resetPopTimer()
    }
    
    @IBAction func themeInfo() {
        self.showAlert("Theme Copyright Info", ThemesManager.shared.currentTheme.copyrightString, sync: false)
    }
    
    @IBAction func openDiscord(){
        UIApplication.shared.open(URL(string: "https://taurine.app/discord")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func photoLibrary(_ sender: Any?) {
        self.view_chon_anh.backgroundColor = UIColor.white
        themeImagePicker.pickerController.sourceType = .photoLibrary
        themeImagePicker.presentationController.present(themeImagePicker.pickerController, animated: true)
        cancelPopTimer()
    }
    
    @objc public func showColourPicker(_ notification: NSNotification) {
        cancelPopTimer()
        if let dict = notification.userInfo as NSDictionary? {
            if let key = dict["default"] as? String {
                activeColourDefault = key
            } else {
                fatalError("Set a key for the colour picker")
            }
        }
        navigationController!.present(colorPickerViewController, animated: true)
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let animationClosures = scrollAnimationClosures
        scrollAnimationClosures = []
        for closure in animationClosures {
            closure()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.cancelPopTimer()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var popCount = 0
        guard var view = self.currentView else {
            return
        }
        while view.frame.minX != self.scrollView.contentOffset.x {
            guard view.frame.minX > self.scrollView.contentOffset.x else {
                fatalError("User dragged the other way???")
            }
            popCount += 1
            view = view.parentView
        }
        
        for _ in 0..<popCount {
            self.popCurrentView(animated: false)
        }
        
        self.resetPopTimer()
    }
}

extension ViewController {
    func bindToKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func unbindKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc
    func keyboardWillChange(notification: Notification) {
        /*guard let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
            let curFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
            let targetFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        self.view.layoutIfNeeded()
        let deltaY = (targetFrame.origin.y - curFrame.origin.y
        self.containerViewYConstraint.constant += deltaY
        UIView.animateKeyframes(withDuration: duration, delay: 0.00, options: UIView.KeyframeAnimationOptions(rawValue: curve), animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)*/
    }
}

extension ViewController: ThemeImagePickerDelegate {
    func didSelect(image: UIImage?) {
        resetPopTimer()
        guard let image = image,
              let data = image.pngData() else { return }
        do {
            try data.write(to: ThemesManager.customImageDirectory, options: .atomic)
            self.updateTheme()
        } catch {
            print("Confusion")
        }
    }
}

extension ViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        UserDefaults.standard.set(viewController.selectedColor, forKey: activeColourDefault)
        NotificationCenter.default.post(name: ThemesManager.themeChangeNotification, object: nil)
    }
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        resetPopTimer()
    }
}

func isJailbroken() -> Bool {
    var flags = UInt32()
    let CS_OPS_STATUS = UInt32(0)
    csops(getpid(), CS_OPS_STATUS, &flags, 0)
    if flags & Consts.shared.CS_PLATFORM_BINARY != 0 {
        return true
    }
    
    let imageCount = _dyld_image_count()
    for i in 0..<imageCount {
        if let cName = _dyld_get_image_name(i) {
            let name = String(cString: cName)
            if name == "/usr/lib/pspawn_payload-stg2.dylib" {
                return true
            }
        }
    }
    return false
}
