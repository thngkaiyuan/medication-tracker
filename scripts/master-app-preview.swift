#!/usr/bin/env swift

import AVFoundation
import CoreMedia
import Foundation

private let targetVideoBitrate = 10_500_000
private let targetAudioBitrate = 256_000
private let targetAudioSampleRate = 48_000

private func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("error: \(message)\n".utf8))
  exit(1)
}

guard CommandLine.arguments.count == 3 else {
  fail("usage: master-app-preview.swift INPUT_VIDEO OUTPUT_MP4")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard FileManager.default.fileExists(atPath: inputURL.path) else {
  fail("input video does not exist: \(inputURL.path)")
}
guard !FileManager.default.fileExists(atPath: outputURL.path) else {
  fail("output already exists: \(outputURL.path)")
}

let asset = AVURLAsset(url: inputURL)
guard let videoTrack = asset.tracks(withMediaType: .video).first else {
  fail("input has no video track")
}

let orientedBounds = CGRect(origin: .zero, size: videoTrack.naturalSize)
  .applying(videoTrack.preferredTransform)
  .standardized
let width = Int(abs(orientedBounds.width))
let height = Int(abs(orientedBounds.height))

do {
  let reader = try AVAssetReader(asset: asset)
  let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
  writer.shouldOptimizeForNetworkUse = true

  let videoOutput = AVAssetReaderTrackOutput(
    track: videoTrack,
    outputSettings: [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
  )
  videoOutput.alwaysCopiesSampleData = false
  guard reader.canAdd(videoOutput) else {
    fail("could not configure the video reader")
  }
  reader.add(videoOutput)

  let videoInput = AVAssetWriterInput(
    mediaType: .video,
    outputSettings: [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: targetVideoBitrate,
        AVVideoExpectedSourceFrameRateKey: 30,
        AVVideoMaxKeyFrameIntervalKey: 60,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
      ],
    ]
  )
  videoInput.expectsMediaDataInRealTime = false
  guard writer.canAdd(videoInput) else {
    fail("could not configure the H.264 writer")
  }
  writer.add(videoInput)

  var audioOutput: AVAssetReaderTrackOutput?
  var audioInput: AVAssetWriterInput?
  if let audioTrack = asset.tracks(withMediaType: .audio).first {
    let output = AVAssetReaderTrackOutput(
      track: audioTrack,
      outputSettings: [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: targetAudioSampleRate,
        AVNumberOfChannelsKey: 2,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsNonInterleaved: false,
      ]
    )
    output.alwaysCopiesSampleData = false

    let input = AVAssetWriterInput(
      mediaType: .audio,
      outputSettings: [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVSampleRateKey: targetAudioSampleRate,
        AVNumberOfChannelsKey: 2,
        AVEncoderBitRateKey: targetAudioBitrate,
      ]
    )
    input.expectsMediaDataInRealTime = false

    guard reader.canAdd(output), writer.canAdd(input) else {
      fail("could not configure the stereo AAC audio pipeline")
    }
    reader.add(output)
    writer.add(input)
    audioOutput = output
    audioInput = input
  }

  guard writer.startWriting() else {
    fail(writer.error?.localizedDescription ?? "could not start the writer")
  }
  guard reader.startReading() else {
    fail(reader.error?.localizedDescription ?? "could not start the reader")
  }
  writer.startSession(atSourceTime: .zero)

  let group = DispatchGroup()

  func copySamples(
    from output: AVAssetReaderOutput,
    to input: AVAssetWriterInput,
    queue: DispatchQueue
  ) {
    group.enter()
    input.requestMediaDataWhenReady(on: queue) {
      while input.isReadyForMoreMediaData {
        if let sample = output.copyNextSampleBuffer() {
          if !input.append(sample) {
            input.markAsFinished()
            group.leave()
            return
          }
        } else {
          input.markAsFinished()
          group.leave()
          return
        }
      }
    }
  }

  copySamples(
    from: videoOutput,
    to: videoInput,
    queue: DispatchQueue(label: "medtracker.preview.video")
  )
  if let audioOutput, let audioInput {
    copySamples(
      from: audioOutput,
      to: audioInput,
      queue: DispatchQueue(label: "medtracker.preview.audio")
    )
  }

  let semaphore = DispatchSemaphore(value: 0)
  group.notify(queue: DispatchQueue.global()) {
    writer.finishWriting {
      semaphore.signal()
    }
  }
  semaphore.wait()

  guard reader.status == .completed else {
    fail(reader.error?.localizedDescription ?? "media reading failed")
  }
  guard writer.status == .completed else {
    fail(writer.error?.localizedDescription ?? "media writing failed")
  }

  print(outputURL.path)
} catch {
  fail(error.localizedDescription)
}
