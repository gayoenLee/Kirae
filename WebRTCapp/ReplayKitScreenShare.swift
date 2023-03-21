//
//  ReplayKitScreenShare.swift
//  WebRTCapp
//
//  Created by 이은호 on 2021/08/29.
//  Copyright © 2021 Sergio Paniego Blanco. All rights reserved.
//

import ReplayKit
import UIKit
import WebRTC
import VideoToolbox

class ReplayKitScreenShare{
    
    @available(iOS 11.0, *)
    static func start( fromVideoSource videoSource: RTCVideoSource, capturer: RTCVideoCapturer) {
        RPScreenRecorder.shared().startCapture(handler: { (sampleBuffer, sampleBufferType, error) in
            if error != nil {
                           print("Capture error: ", error as Any)
                           return
                       }
                       switch sampleBufferType {
                       case .video:
                           self.processScreenShare(sampleBuffer, videoSource: videoSource, capturer: capturer)
                           break
                       default:
                           break
                       }
        }) { (error) in
            let errroMsg = error != nil ? "\("Screen capture error: \(error as Any)")" : "Screen capture started."
            print(errroMsg)
        }
    }
    
    static func processScreenShare(_ cmSampleBuffer: CMSampleBuffer, videoSource: RTCVideoSource, capturer: RTCVideoCapturer) {
        
        //sample buffer를 image로 변환
        var cgImage : CGImage?
        guard let pixelBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(cmSampleBuffer) else {
              return
        }
        
        let rtcpixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)

        var videoFrame:RTCVideoFrame?;
        let timestamp = NSDate().timeIntervalSince1970 * 1000
        videoFrame = RTCVideoFrame.init(buffer: rtcpixelBuffer, rotation: RTCVideoRotation._0, timeStampNs: Int64(timestamp))
        videoSource.adaptOutputFormat(toWidth: videoFrame!.width, height: videoFrame!.height, fps: 30)
        
        //이게 비디오를 보여주는 것.
        videoSource.capturer(capturer, didCapture: videoFrame!)
        print("shareDeviceScreen \(videoFrame!.width) x \(videoFrame!.height)")
    }
    
    @available(iOS 11.0, *)
    static func stop() {
        RPScreenRecorder.shared().stopCapture { (error) in
            let errroMsg = error != nil ? "\("Screen capture error: \(error as Any)")" : "Screen capture  stopped."
            print(errroMsg)
        }
    }
}
