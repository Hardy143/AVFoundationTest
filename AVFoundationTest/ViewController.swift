//
//  ViewController.swift
//  AVFoundationTest
//
//  Created by Vicki Larkin on 27/06/2018.
//  Copyright © 2018 Vicki Hardy. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO
import AssetsLibrary

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    
    // AVFoundation video recording properties
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoCaptureDevice: AVCaptureDevice?
    var videoDataOutput = AVCaptureVideoDataOutput()
    var audioDataOutput = AVCaptureAudioDataOutput()
    var videoDataOutputQueue: DispatchQueue?
    var outputFileLocation: URL?
    
    // avassetwriter
    var isRecording = false
    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var audioWriterInput: AVAssetWriterInput!
    var sessionAtSourceTime: CMTime?
    var outputUrl: URL?
    var videoWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    // avassetreader
    var assetReader: AVAssetReader!
    
    lazy var lastSampleTime: CMTime = kCMTimeZero

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initialiseCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }
    
    
    @IBAction func recordButtonTouched(_ sender: Any) {
        
        if !isRecording {
            start()
            recordButton.setTitle("Recording", for: .normal)
        } else {
            stop()
            recordButton.setTitle("Record", for: .normal)
         }
        
    }
    
    // MARK: Set up the camera
    func initialiseCamera() {

        // size of the output video will be 720x1280
        captureSession.sessionPreset = .hd1280x720
        
        // set up camera
        videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        
        
        if videoCaptureDevice != nil {
            do {
                // add the input from the device
                try captureSession.addInput(AVCaptureDeviceInput(device: videoCaptureDevice!))
                // set up the microphone
                if let audioInput = AVCaptureDevice.default(for: AVMediaType.audio) {
                    try captureSession.addInput(AVCaptureDeviceInput(device: audioInput))
                }
                
                try videoCaptureDevice?.lockForConfiguration()
                videoCaptureDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 30)
                videoCaptureDevice?.activeVideoMaxFrameDuration = CMTimeMake(1, 30)
                videoCaptureDevice?.unlockForConfiguration()
                
                // define output data
                videoDataOutputQueue = DispatchQueue(label: "sessionQueue")
                
                // define video output
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                ]
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                
                

                
                if captureSession.canAddOutput(videoDataOutput) {
                    videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
                    captureSession.addOutput(videoDataOutput)
                }
                
                // define audio output
                if captureSession.canAddOutput(audioDataOutput) {
                    audioDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
                    captureSession.addOutput(audioDataOutput)
                }
                
                captureSession.commitConfiguration()
        
                
                // create preview layer to see what you're recording
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                previewLayer?.connection?.videoOrientation = .portrait
                previewView.layer.addSublayer(previewLayer!)
                
                
                
                // add output to video file
                //captureSession.addOutput(movieFileOutput)

                // start the session
                captureSession.startRunning()
                
            } catch {
                print(error)
            }
        }
    }
    
    func setUpWriter() {
        
        do {
            outputFileLocation = videoFileLocation()
            videoWriter = try AVAssetWriter(outputURL: outputFileLocation!, fileType: AVFileType.mov)
            
            // add video input
            videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                AVVideoCodecKey : AVVideoCodecType.h264,
                AVVideoWidthKey : 720,
                AVVideoHeightKey : 1280,
                AVVideoCompressionPropertiesKey : [
                    AVVideoAverageBitRateKey : 2300000,
                    ],
                ])
                        
            videoWriterInput.expectsMediaDataInRealTime = true
            
            if videoWriter.canAdd(videoWriterInput) {
                videoWriter.add(videoWriterInput)
                print("video input added")
            } else {
                print("no input added")
            }
            
            // add audio input
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)

            audioWriterInput.expectsMediaDataInRealTime = true

            if videoWriter.canAdd(audioWriterInput!) {
                videoWriter.add(audioWriterInput!)
                print("audio input added")
            }
            

            videoWriter.startWriting()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        

    }
    
    func canWrite() -> Bool {
        return isRecording && videoWriter != nil && videoWriter?.status == .writing
    }

    
     //video file location method
    func videoFileLocation() -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputUrl = URL(fileURLWithPath: documentsPath.appendingPathComponent("videoFile")).appendingPathExtension("mov")
        do {
        if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
            try FileManager.default.removeItem(at: videoOutputUrl)
            print("file removed")
        }
        } catch {
            print(error)
        }
        
        return videoOutputUrl
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let writable = canWrite()
        
        if writable,
            sessionAtSourceTime == nil {
            // start writing
            sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
            //print("Writing")
        }
        
        if output == videoDataOutput {
            connection.videoOrientation = .portrait
            
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        
        if writable,
            output == videoDataOutput,
            (videoWriterInput.isReadyForMoreMediaData) {
            // write video buffer
            videoWriterInput.append(sampleBuffer)
            //print("video buffering")
        } else if writable,
            output == audioDataOutput,
            (audioWriterInput.isReadyForMoreMediaData) {
            // write audio buffer
            audioWriterInput?.append(sampleBuffer)
            //print("audio buffering")
        }
        
    }

    // MARK: Start recording
    func start() {
        guard !isRecording else { return }
        isRecording = true
        sessionAtSourceTime = nil
        setUpWriter()
        print(isRecording)
        print(videoWriter)
        if videoWriter.status == .writing {
            print("status writing")
        } else if videoWriter.status == .failed {
            print("status failed")
        } else if videoWriter.status == .cancelled {
            print("status cancelled")
        } else if videoWriter.status == .unknown {
            print("status unknown")
        } else {
            print("status completed")
        }
        
    }
    
    // MARK: Stop recording
    func stop() {
        guard isRecording else { return }
        isRecording = false
        videoWriterInput.markAsFinished()
        print("marked as finished")
        videoWriter.finishWriting { [weak self] in
            self?.sessionAtSourceTime = nil
        }
        //print("finished writing \(self.outputFileLocation)")
        captureSession.stopRunning()
        performSegue(withIdentifier: "videoPreview", sender: nil)
    }
    
//    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
//        print("Finished recording: \(outputFileURL)")
//
//        outputFileLocation = outputFileURL
//        performSegue(withIdentifier: "videoPreview", sender: nil)
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is VideoPreviewViewController {
            let preview = segue.destination as? VideoPreviewViewController
            preview?.fileLocation = self.outputFileLocation
        }
    }


}

