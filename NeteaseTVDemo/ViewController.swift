//
//  ViewController.swift
//  NeteaseTVDemo
//
//  Created by ZhangDong on 2023/8/25.
//

import UIKit
import NeteaseRequest
import Kingfisher
import MarqueeLabel
class ViewController: UIViewController {
    
    var allModels: [CustomAudioModel] = [CustomAudioModel]()
    var lyrics: [String]?
    var lyricTuple: (times: [String], words: [String])?
    var current: Int = 0

    @IBOutlet weak var leftTimeLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var nameLabel: MarqueeLabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var coverImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(WKLyricTableViewCell.self, forCellReuseIdentifier: "cell")
        Task {
            wk_player.delegate = self
            wk_player.allOriginalModels = await loadData()
            try? wk_player.play(index: 0)
        }
//        wk_player.updateUIHandler = { dataSource, state, isPlaying, detailInfo in
//            guard let detail = detailInfo else { return }
//            let currentTime = wk_playerTool.formatTime(seconds: detail.current)
//            let durationTime = wk_playerTool.formatTime(seconds: detail.duration)
//            debugPrint("进度\(currentTime)")
//        }
        
    }
    
    
    func loadData() async -> [CustomAudioModel] {
        let songModels:[NRSongModel] = try! await fetchPlayListTrackAll(id: 2768213177)

        self.allModels.removeAll()
        for songModel in songModels {
            let model = CustomAudioModel()
            model.audioId = songModel.id
            model.isFree = 1
            model.freeTime = 0
            model.audioTitle = songModel.name
            model.audioPicUrl = songModel.al.picUrl
            self.allModels.append(model)
        }
        return self.allModels
    }
    

    @IBAction func backward(_ sender: Any) {
        wk_player.prepareForSeek(to: (Float(wk_player.currentModelState!.current + 15) / Float(wk_player.totalTime)))
        
    }
    
    @IBAction func forward(_ sender: Any) {
        wk_player.prepareForSeek(to: (Float(wk_player.currentModelState!.current + 15) / Float(wk_player.totalTime)))
    }
    
    @IBAction func previous(_ sender: Any) {
        do {
            try wk_player.playLast()
        } catch {
            debugPrint(error)
        }
    }
    @IBAction func playOrPause(_ sender: Any) {
        if wk_player.state == .paused {
            wk_player.resumePlayer()
        } else if  wk_player.state == .isPlaying {
            wk_player.pausePlayer()
        }
        
    }
    
    @IBAction func next(_ sender: Any) {
        do {
            try wk_player.playNext()
        } catch {
            debugPrint(error)
        }
    }
    
}

extension ViewController: WKPlayerDelegate {
    
    func configePlayer() {
        wk_player.function = [.cache]
    }
    
    func playDataSourceWillChange(now: WKPlayerDataSource?, new: WKPlayerDataSource?) {
        debugPrint("设置上一个数据源，说明要切换音频了，当前是\(String(describing: now?.wk_sourceName!))，即将播放的是\(String(describing: new?.wk_sourceName!))")
    }
    
    func playDataSourceDidChanged(last: WKPlayerDataSource?, now: WKPlayerDataSource) {
        debugPrint("设置新的数据源，说明已经切换音频了，原来是\(String(describing: last?.wk_sourceName!))，当前是\(now.wk_sourceName!)")
        
        if Thread.isMainThread {
            self.coverImageView.kf.setImage(with: URL(string: now.wk_audioPic ?? ""))
            self.nameLabel.text = now.wk_sourceName
        } else {
            DispatchQueue.main.async {
                self.coverImageView.kf.setImage(with: URL(string: now.wk_audioPic ?? ""),options: [.transition(.flipFromBottom(0.6))])
                self.nameLabel.text = now.wk_sourceName
                
            }
            Task {
                lyricTuple = parserLyric(lyric: try! await fetchLyric(id: now.wk_audioId!).lyric!)
                tableView.reloadData()
            }
            
        }
        
    }
    
    func didPlayToEnd(dataSource: WKPlayerDataSource, isTheEnd: Bool) {
        debugPrint("数据源\(dataSource.wk_sourceName!)已播放至结尾")
    }
    
    
    func noPermissionToPlayDataSource(dataSource: WKPlayerDataSource) {
        debugPrint("没有权限播放\(dataSource.wk_sourceName!)")
    }
    
    func didReadTotalTime(totalTime: UInt, formatTime: String) {
        debugPrint("已经读取到时长为duration = \(totalTime), format = \(formatTime)")
        DispatchQueue.main.async {
            self.rightLabel.text = formatTime
        }
    }
    
    
    func askForWWANLoadPermission(confirmed: @escaping () -> ()) {
//        let alert = UIAlertController.init(title: "网络环境确认", message: "当前非wifi环境，确定继续加载么", preferredStyle: .alert)
//        let confirmAction = UIAlertAction.init(title: "确定", style: .default) {_ in
//            confirmed()
//        }
//        alert.addAction(confirmAction)
//        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func stateDidChanged(_ state: WKPlayerState) {
        
    }
    
    func updateUI(dataSource: WKPlayerDataSource?, state: WKPlayerState, isPlaying: Bool, detailInfo: WKPlayerStateModel?) {
        
//        playBtn.isSelected = isPlaying
//
//        audioTitleLbl.text = dataSource?.wk_sourceName!
        guard let detail = detailInfo else { return }
        let currentTime = wk_playerTool.formatTime(seconds: detail.current)
//        let durationTime = wk_playerTool.formatTime(seconds: detail.duration)
//        audioDurationLbl.text = currentTime + "/" + durationTime
//        bufferProgress.progress = detail.buffer
//        audioProgressSlider.value = detail.progress
//        debugPrint("进度\(currentTime)")
        guard let times = lyricTuple?.times else { return }
        for (index, time) in times.enumerated() {
            let times = time.components(separatedBy: ":")
            if time.count > 0 {
                let lyricTime = (Float(times.first!) ?? 0.0) * 60 + (Float(times[1]) ?? 0.0)
                if (Float(detail.current) + 0.5) > lyricTime {
                    current = index
                } else {
                    break
                }
                    
            }
            
        }
        
        DispatchQueue.main.async { [self] in
            self.leftTimeLabel.text = currentTime
            self.progressView.progress = detail.progress
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: current, section: 0), at: .middle, animated: true)
        }
        
        
    }
    
    
    func dataSourceDidChange(lastOriginal: [WKPlayerDataSource]?, lastAvailable: [WKPlayerDataSource]?, nowOriginal: [WKPlayerDataSource]?, nowAvailable: [WKPlayerDataSource]?) {
        
        
        
    }
    
    func unifiedExceptionHandle(error: WKPlayerError) {
        debugPrint(error.errorDescription as Any)
        
        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: "Error", message: error.errorDescription, preferredStyle: .alert)
            let confirm = UIAlertAction.init(title: "ok", style: .default, handler: nil)
            alert.addAction(confirm)
    //        self.present(alert, animated: true)
            let keyWindow = UIApplication.shared.connectedScenes
                    .filter({$0.activationState == .foregroundActive})
                    .compactMap({$0 as? UIWindowScene})
                    .first?.windows
                    .filter({$0.isKeyWindow}).first
            keyWindow!.rootViewController?.present(alert, animated: true, completion: nil)
        }
        
        
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lyricTuple?.words.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! WKLyricTableViewCell
        cell.contentLabel!.text = lyricTuple?.words[indexPath.row] ?? ""
        if current == indexPath.row {
            cell.contentLabel?.textColor = UIColor.red
            cell.contentLabel?.font = .systemFont(ofSize: 48, weight: .black)
        } else {
            cell.contentLabel?.textColor = UIColor.label
            cell.contentLabel?.font = .systemFont(ofSize: 38)
        }
        return cell
    }
}

