//
//  ViewController.swift
//  Player
//
//  Created by sqluo on 2017/1/5.
//  Copyright © 2017年 sqluo. All rights reserved.
//

import UIKit

import AVFoundation




class ViewController: UIViewController {

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem!)
    }
    
    var player = AVPlayer()
    
    
    @IBOutlet weak var progressLabel: UILabel!          //左播放进度时间
    @IBOutlet weak var allTimeLabel: UILabel!           //右总时间
    @IBOutlet weak var downProgress: UIProgressView!    //下载进度条
    @IBOutlet weak var mySlider: UISlider!              //播放进度
    @IBOutlet weak var playBtn: UIButton!               //开始，暂停
    @IBOutlet weak var stopBtn: UIButton!               //停止
    
    
    var isPlay = false //记录是否在播放
    
    var timeObserver: Any! //播放时间的监听
    
    var musicDuration: Float64 = 1 //单曲的总时长
    
    
    var isSliderEdit = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.playBtn.isEnabled = false
        self.stopBtn.isEnabled = false
        
        self.mySlider.value = 0.0
        
        mySlider.addTarget(self, action: #selector(self.sliderDidchange(send:)), for: .valueChanged)
        mySlider.addTarget(self, action: #selector(self.sliderTouch(send:)), for: .touchUpInside)
        mySlider.addTarget(self, action: #selector(self.sliderTouchOut(send:)), for: .touchUpOutside)
        
        
        let str = "http://so1.111ttt.com:8282/2016/5/12m/09/205091241367.m4a?tflag=1483602561&pin=e20208de53e46de803bf3e020595c65d&ip=103.77.56.145#.mp3"
        let url = URL(string: str)
        
        let item = AVPlayerItem(url: url!)
        
        
        player = AVPlayer(playerItem: item)
        
  
        //监听该文件是否能播放
        self.player.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        //监听音乐的缓冲进度
        self.player.currentItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playFinished(send:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem!)
        
        
        
    }
    
    func playFinished(send: NotificationCenter){
        
        print("播放完成")
        self.removeObserver()
        
    }
    
    func sliderTouchOut(send: UISlider){
        
        self.player.pause()
        
        let time = Double(send.value) * CMTimeGetSeconds(self.player.currentItem!.duration)
        
        if isPlay {
            self.player.play()
            self.player.seek(to: CMTime(seconds: time, preferredTimescale: 1))
        }else{
            
            self.player.play()
            self.player.seek(to: CMTime(seconds: time, preferredTimescale: 1))
            isPlay = true
            
        }
        self.addTimeObserver()
        self.isSliderEdit = false
        
    }
    
    var isDidSet = false
    var setTime: Float64 = 0
    
    func sliderTouch(send: UISlider){
        print("aaa")
        
        self.isDidSet = true
        
        
        self.player.pause()
        
        let time = Double(send.value) * CMTimeGetSeconds(self.player.currentItem!.duration)
        
        self.setTime = time
        
        if isPlay {
            self.player.play()
            self.player.seek(to: CMTime(seconds: time, preferredTimescale: 1))
        }else{
            
            self.player.play()
            self.player.seek(to: CMTime(seconds: time, preferredTimescale: 1))
            isPlay = true
            
        }
        self.addTimeObserver()
        self.isSliderEdit = false
    }
    
    func sliderDidchange(send: UISlider){
        
        self.isSliderEdit = true
        
        if self.timeObserver != nil{
            self.player.removeTimeObserver(self.timeObserver)
            self.timeObserver = nil
        }

        let time = Double(send.value) * self.musicDuration
        
        
        progressLabel.text = time.formatting()

        
    }
    
    
    //开始，暂停点击
    @IBAction func playAct(_ sender: UIButton) {
        
        
        
        if isPlay {
            
            self.player.pause()
            self.isPlay = false
        }else{
            
            self.player.play()
            self.isPlay = true
            
            self.addTimeObserver()
  
        }

    }
    
    func addTimeObserver(){
        if self.timeObserver == nil {
            self.timeObserver = self.player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: CMTimeScale(1)), queue: DispatchQueue.main, using: { (cmTime: CMTime) in
 
                
                if self.musicDuration != 0 && self.isSliderEdit == false{
                    
                    let time = CMTimeGetSeconds(cmTime)
 
                    print("time:\(time)")
                    //更新进度条，以及时间显示 ...
                    
                    self.progressLabel.text = time.formatting()
                    
                    let scale = time / self.musicDuration
                    
//                    self.mySlider.setValue(Float(scale), animated: false)
                    
                    self.mySlider.value = Float(scale)
                    
                }
                
            })
        }
    }
    
    
    //停止点击
    @IBAction func stopAct(_ sender: UIButton) {
        
    }
    
   
    
    
    //切换歌曲
    func nextMusic(url: String){
        
        let item = AVPlayerItem(url: URL(string: url)!)
        player.replaceCurrentItem(with: item)
        
    }
    
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let key = keyPath{
            
            switch key {
            case "status":
                
                switch self.player.status {
                case .unknown:
                    print("未知状态")
                case .readyToPlay:
                    print("准备播放")
                    
                    self.playBtn.isEnabled = true
    
                case .failed:
                    print("加载失败")
                }
            case "loadedTimeRanges":
                
                if let timeRanges = self.player.currentItem?.loadedTimeRanges{
                    //本次缓冲的时间范围
                    let timeRange: CMTimeRange = timeRanges.first!.timeRangeValue
                    
                    //缓冲总长度
                    let totalLoadTime = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration)
                    
                    print("缓冲总长度:\(totalLoadTime)")
                    //音乐的总时间
                    
                    let duration = CMTimeGetSeconds(self.player.currentItem!.duration)
                    print("音乐总时长:\(duration)")
                    
                    self.musicDuration = duration
                    
                    //计算缓冲百分比例
                    let scale = totalLoadTime / duration
                    
                    print("缓冲百分比例:\(scale)")
                    
                    //更新进度条 ...
                    self.downProgress.setProgress(Float(scale), animated: true)
                    //设置总时长
                    self.allTimeLabel.text = duration.formatting()
                }
                
                
                
            default:
                break
            }
   
            
        }
   
    }
    

    
    //当音乐播放完成，或者切换下一首歌曲时，请务必记得移除观察者，否则会crash。操作如下：
    //移除观察者
    func removeObserver(){
        self.player.currentItem?.removeObserver(self, forKeyPath: "status")
        self.player.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        
        if self.timeObserver != nil {
            self.player.removeTimeObserver(self.timeObserver)
            self.timeObserver = nil
        }
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
 
    
    
    
    
    
    
    
    
    

}


extension Double{
    
    //时间秒转分
    public func formatting()->String{
        
        let currentTime = Int(self)
        let minutes = currentTime / 60
        let seconds = currentTime - minutes * 60
        
        return NSString(format: "%02d:%02d", minutes,seconds) as String
        
    }
    
}
