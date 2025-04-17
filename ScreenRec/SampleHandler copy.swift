//
//  SampleHandler.swift
//  ScreenRec
//
//  Created by Thomas Dye on 11/01/2025.
//

import ReplayKit
import Network
import VideoToolbox



//class SampleHandler1: RPBroadcastSampleHandler {
//
//    // MARK: - Network Connection to Main App
//    private var connection: NWConnection?
//
//    // MARK: - VideoToolbox Compression
//    private var compressionSession: VTCompressionSession?
//    private let compressionQueue = DispatchQueue(label: "com.example.H264CompressionQueue")
//
//    // We’ll cache the SPS/PPS NAL units here (if we find them)
//    private var spsData: Data?
//    private var ppsData: Data?
//
//    // Synchronous encode buffer
//    private var lastEncodedData: Data?
//
//    // MARK: - Broadcast Lifecycle
//
//    /// Called when user starts the broadcast (via Control Center or your RPBroadcastActivityViewController).
//    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
//        print("broadcast started")
//        
//        // 1) Create/Configure compression session
//        createCompressionSession(width: 720, height: 1280)
//
//        // 2) Connect to the main app's local server on 127.0.0.1:12345
//        connection = NWConnection(host: "127.0.0.1", port: 12345, using: .tcp)
//        connection?.start(queue: .global(qos: .background))
//    }
//
//    /// Called when the broadcast finishes (user taps stop or extension is terminated).
//    override func broadcastFinished() {
//        print("broadcast finished")
//        
//        // Cleanup compression session
//        if let session = compressionSession {
//            VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: CMTime.invalid)
//            VTCompressionSessionInvalidate(session)
//        }
//        compressionSession = nil
//
//        // Cancel the network connection
//        connection?.cancel()
//    }
//
//    /// Called for each incoming video/audio sample from the entire device screen
//    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer,
//                                      with sampleBufferType: RPSampleBufferType) {
//        switch sampleBufferType {
//        case .video:
//            // Encode the video frame to H.264
//            guard let encodedData = encodeToH264(sampleBuffer) else { return }
//            
//            // Send to the main app via NWConnection
//            connection?.send(content: encodedData, completion: .contentProcessed({ error in
//                if let error = error {
//                    print("Send error:", error)
//                }
//            }))
//
//        case .audioApp, .audioMic:
//            // If you also want audio, you'd encode and send it here
//            break
//
//        @unknown default:
//            break
//        }
//    }
//
//    // MARK: - Create & Configure Compression Session
//
//    private func createCompressionSession(width: Int32, height: Int32) {
//        let status = VTCompressionSessionCreate(
//            allocator: kCFAllocatorDefault,
//            width: width,
//            height: height,
//            codecType: kCMVideoCodecType_H264, // or kCMVideoCodecType_HEVC
//            encoderSpecification: nil,
//            imageBufferAttributes: nil,
//            compressedDataAllocator: nil,
//            outputCallback: compressionOutputCallback,
//            refcon: Unmanaged.passUnretained(self).toOpaque(),
//            compressionSessionOut: &compressionSession
//        )
//        
//        guard status == noErr, let session = compressionSession else {
//            print("Error creating VTCompressionSession: \(status)")
//            return
//        }
//        
//        // Configure session properties
//        // 1) Real-time encoding
//        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
//        // 2) Disable B-frames
//        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
//        // 3) Profile level
//        let profileLevel = kVTProfileLevel_H264_Baseline_4_2 as CFString
//        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: profileLevel)
//        // 4) Bitrate
//        let bitRate: Int = 2_000_000  // ~2 Mbps
//        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: bitRate as CFTypeRef)
//
//        // Possibly set the entropy mode:
//        VTSessionSetProperty(session,
//                             key: kVTCompressionPropertyKey_H264EntropyMode,
//                             value: kVTH264EntropyMode_CABAC) // or kVTH264EntropyMode_CAVLC
//
//        // 5) Prepare for encoding
//        VTCompressionSessionPrepareToEncodeFrames(session)
//    }
//
//    /// VideoToolbox callback that fires when a frame is encoded.
//    private let compressionOutputCallback: VTCompressionOutputCallback = {
//        (outputCallbackRefCon, sourceFrameRefCon, status, infoFlags, sb) in
//
//        guard status == noErr else {
//            print("Compression failed with status = \(status)")
//            return
//        }
//        guard
//            let sampleBuffer = sb,
//            CMSampleBufferDataIsReady(sampleBuffer),
//            let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)
//        else {
//            return
//        }
//
//        // Convert `outputCallbackRefCon` back to SampleHandler
//        let selfRef = Unmanaged<SampleHandler>
//            .fromOpaque(outputCallbackRefCon!)
//            .takeUnretainedValue()
//
//        // Extract raw bytes
//        let length = CMBlockBufferGetDataLength(blockBuffer)
//        var data = Data(count: length)
//        data.withUnsafeMutableBytes { rawPtr in
//            if let baseAddress = rawPtr.baseAddress {
//                CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: baseAddress)
//            }
//        }
//
//        // Check if this sampleBuffer is a keyframe
//        let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [CFDictionary]
//        let isKeyframe = attachments?.first.map {
//            !CFDictionaryContainsKey($0, Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque())
//        } ?? false
//
//        // If it's a keyframe, let's check if we already have SPS/PPS cached.
//        // If not, we can try to parse them out from this data.
//        // Then, ALWAYS prepend them to ensure the main app sees SPS/PPS in every keyframe.
//        if isKeyframe {
//            // Attempt to parse out SPS/PPS if we don't have them yet
//            if selfRef.spsData == nil || selfRef.ppsData == nil {
//                selfRef.parseSPSandPPS(from: data)
//            }
//
//            // If we have valid SPS/PPS, prepend them to the front of this keyframe
//            if let sps = selfRef.spsData, let pps = selfRef.ppsData {
//                var combined = Data()
//                combined.append(sps) // e.g. "00 00 00 01 67 ..."
//                combined.append(pps) // e.g. "00 00 00 01 68 ..."
//                combined.append(data)
//                data = combined
//            }
//        }
//
//        // Store the final data for synchronous call (encodeToH264) usage
//        selfRef.lastEncodedData = data
//
//        // Also send asynchronously here (if you like)
//        selfRef.connection?.send(content: data, completion: .contentProcessed({ error in
//            if let error = error {
//                print("Send error:", error)
//            }
//        }))
//    }
//
//    // MARK: - Encoding a Single Frame (Synchronous Example)
//    private func encodeToH264(_ sampleBuffer: CMSampleBuffer) -> Data? {
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
//              let session = compressionSession else {
//            return nil
//        }
//
//        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//        let duration = CMSampleBufferGetDuration(sampleBuffer)
//        
//        let semaphore = DispatchSemaphore(value: 0)
//        lastEncodedData = nil
//        
//        compressionQueue.async {
//            let status = VTCompressionSessionEncodeFrame(
//                session,
//                imageBuffer: imageBuffer,
//                presentationTimeStamp: pts,
//                duration: duration,
//                frameProperties: nil,
//                sourceFrameRefcon: nil,
//                infoFlagsOut: nil
//            )
//            
//            if status != noErr {
//                print("VTCompressionSessionEncodeFrame error: \(status)")
//            }
//            
//            // Tiny delay to let callback run
//            usleep(10_000) // 10 ms
//            semaphore.signal()
//        }
//        
//        // Wait up to 100ms for the callback
//        _ = semaphore.wait(timeout: .now() + 0.1)
//        
//        return lastEncodedData
//    }
//
//    // MARK: - Helper: Extract SPS/PPS from a keyframe
//    /// This simplistic approach looks for the start-code "00 00 00 01" + NAL types 7 (SPS) and 8 (PPS).
//    /// If found, we store them in `spsData` and `ppsData`.
//    private func parseSPSandPPS(from frameData: Data) {
//        let startCode: [UInt8] = [0,0,0,1]
//        let spsType: UInt8 = 7
//        let ppsType: UInt8 = 8
//        
//        // We'll do a rough split by "00 00 00 01"
//        let nalUnits = splitNALUnits(frameData: frameData)
//
//        for nal in nalUnits {
//            guard nal.count > 0 else { continue }
//            let nalType = nal[0] & 0x1F
//            if nalType == spsType {
//                // Re-add the start code for a valid Annex-B chunk
//                var sps = Data(startCode)
//                sps.append(nal)
//                spsData = sps
//                print("Cached SPS (size: \(sps.count))")
//            } else if nalType == ppsType {
//                var pps = Data(startCode)
//                pps.append(nal)
//                ppsData = pps
//                print("Cached PPS (size: \(pps.count))")
//            }
//        }
//    }
//    
//    /// Splits a Data block by the Annex-B start code 00 00 00 01
//    private func splitNALUnits(frameData: Data) -> [Data] {
//        var nalUnits = [Data]()
//        let startCode: [UInt8] = [0,0,0,1]
//        
//        var searchRange = 0
//        while true {
//            // Find the next "00 00 00 01"
//            guard let range = frameData.range(of: Data(startCode),
//                                              options: [],
//                                              in: searchRange..<frameData.count) else {
//                // No more
//                break
//            }
//            
//            // The NAL starts right after that sequence
//            let nalStart = range.lowerBound + startCode.count
//            
//            // The previous chunk: from searchRange to range.lowerBound
//            if nalStart - startCode.count >= searchRange {
//                let chunk = frameData.subdata(in: searchRange..<range.lowerBound)
//                if !chunk.isEmpty {
//                    nalUnits.append(chunk)
//                }
//            }
//            
//            searchRange = nalStart
//        }
//        
//        // Last chunk if any
//        if searchRange < frameData.count {
//            let finalChunk = frameData.subdata(in: searchRange..<frameData.count)
//            if !finalChunk.isEmpty {
//                nalUnits.append(finalChunk)
//            }
//        }
//        
//        return nalUnits
//    }
//}
