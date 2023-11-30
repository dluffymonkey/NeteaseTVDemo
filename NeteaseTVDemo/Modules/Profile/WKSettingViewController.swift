
import UIKit
import NeteaseRequest
struct CellModel {
    let title: String
    var desp: String? = nil
    var contentVC: UIViewController? = nil
    var action: (() -> Void)? = nil
}

class WKSettingViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    let settings = ["默认音质", "热门评论", "服务地址"]
    var cellModels = [CellModel]()
    static func creat() -> WKSettingViewController {
        let vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(identifier: String(describing: self)) as! WKSettingViewController
        return vc
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        setupData()
    }
    
    func setupData() {
        cellModels.removeAll()
        let cancelAction = UIAlertAction(title: nil, style: .cancel)
        let quality = CellModel(title: "默认音质", desp: Settings.audioQuality.desp) { [weak self] in
            let alert = UIAlertController(title: "默认音质", message: "标准以上需要网易云音乐会员", preferredStyle: .actionSheet)
            for quality in NRSongLevel.allCases {
                let action = UIAlertAction(title: quality.desp, style: .default) { _ in
                    Settings.audioQuality = quality
                    self?.setupData()
                }
                alert.addAction(action)
            }
            alert.addAction(cancelAction)
            self?.present(alert, animated: true)
        }
        cellModels.append(quality)
        let comment = CellModel(title: "热门评论", desp: Settings.hotComment ? "开" : "关") { [weak self] in
            Settings.hotComment = !Settings.hotComment
            self?.setupData()
        }
        cellModels.append(comment)
        
        let service = CellModel(title: "服务设置", desp: Settings.service) { [weak self] in
            let vc = WKInputViewController.creat()
            vc.modalPresentationStyle = .blurOverFullScreen
            self?.present(vc, animated: true)
        }
        cellModels.append(service)
        
        tableView.reloadData()
    }
}




extension WKSettingViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
//        cell.accessoryType = .disclosureIndicator
        var content = cell.defaultContentConfiguration()
        content.text = settings[indexPath.row]
        content.secondaryText = cellModels[indexPath.row].desp
        cell.contentConfiguration = content
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        cellModels[indexPath.row].action?()
    }
}
