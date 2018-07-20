//
//  VideoPreviewViewController.swift
//  AVFoundationTest
//
//  Created by Vicki Larkin on 27/06/2018.
//  Copyright © 2018 Vicki Hardy. All rights reserved.
//



import UIKit
import AVKit
import AVFoundation



class VideoPreviewViewController: UIViewController {

    //var player = AVPlayer()
    var playerLayer: AVPlayerLayer!
    var playerItem: AVPlayerItem?
    var fileLocation: URL?
    var asset: AVAsset!
    var reader: AVAssetReader!
    // AVQueuePlayer rather than AVPlayer so the video will replay
    var player = AVQueuePlayer()
    var looper: AVPlayerLooper?
    
    // Key- value observing context
    var playerItemContext = 0

    let assetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    @IBOutlet weak var videoView: UIView!    
    @IBOutlet weak var myTextView: UITextView!
    
    var isVideoPlaying = false


    override func viewDidLoad() {
        super.viewDidLoad()
        prepareToPlay()
        createAssetReader()
        
        self.player.play()

    }
    
    // MARK: Create AVAssetReader
    func createAssetReader() {
        reader = try! AVAssetReader(asset: asset)
        let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
        
        reader.add(readerOutput)
        let nominalFrameRate = String(format: "Frame Rate: %.2ffps", Double(videoTrack.nominalFrameRate))
        let naturalSize = videoTrack.naturalSize
        let height = Double(naturalSize.height)
        let width = Double(naturalSize.width)
        let resolution = String(format: "Resolution: %.0fx%.0f", width, height)
        let videoBitrate = String(format: "Bitrate: %.0fbps", videoTrack.estimatedDataRate)
        let dataLength = videoTrack.totalSampleDataLength
        let dataLengthKilo = Double(dataLength) / 1024
        let dataLengthMega = String(format: "Video Size: %.2fmb", dataLengthKilo / 1024)
        reader.startReading()
        myTextView.text = "\(nominalFrameRate)\n\(resolution)\n\(videoBitrate)\n\(dataLengthMega)"
    
    }
    
    
    // Mark: Create AVPlayer
    func prepareToPlay() {
        
        //print(fileLocation?.path)
        
        asset = AVAsset(url: fileLocation!)

        playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)

        // register as an observer of the player item's status property
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        
        //player = AVQueuePlayer(playerItem: playerItem)
        looper = AVPlayerLooper(player: player, templateItem: playerItem!)
        
        playerLayer = AVPlayerLayer(player: player)
        videoView.layer.addSublayer(playerLayer)
        playerLayer.frame = self.videoView.bounds
        
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            // Switch over status value
            switch status {
            case .readyToPlay:
                print("ready to play")
            // Player item is ready to play.
            case .failed:
                handleErrorWithMessage(player.currentItem!.error!.localizedDescription, error:player.currentItem!.error)
            // Player item failed. See error.
            case .unknown:
                print("not ready yet")
                // Player item is not yet ready.
            }
        }
    }
    
    func handleErrorWithMessage(_ message: String?, error: Error? = nil) {
        print("Error occured with message: \(message), error: \(error).")
    }


    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }



    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }



    func showAlert(title:String, message:String, dismiss:Bool) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if dismiss {
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
            }))
        } else {
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }

        self.present(controller, animated: true, completion: nil)
    }




    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

