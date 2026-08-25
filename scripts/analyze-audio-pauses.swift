#!/usr/bin/env swift

import AVFoundation
import Foundation

private func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("error: \(message)\n".utf8))
  exit(1)
}

guard CommandLine.arguments.count == 2 else {
  fail("usage: analyze-audio-pauses.swift AUDIO_FILE")
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])

do {
  let asset = AVURLAsset(url: url)
  guard let track = asset.tracks(withMediaType: .audio).first else {
    fail("audio track is missing")
  }
  let reader = try AVAssetReader(asset: asset)
  let output = AVAssetReaderTrackOutput(
    track: track,
    outputSettings: [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVLinearPCMBitDepthKey: 32,
      AVLinearPCMIsFloatKey: true,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ]
  )
  guard reader.canAdd(output) else {
    fail("could not configure the audio decoder")
  }
  reader.add(output)
  guard reader.startReading() else {
    fail(reader.error?.localizedDescription ?? "could not start audio decoding")
  }

  var sampleRate = 0.0
  var channelCount = 0
  var windowFrames = 0
  var windows: [Double] = []
  var windowEnergy = 0.0
  var windowSampleCount = 0

  while let sampleBuffer = output.copyNextSampleBuffer() {
    if sampleRate == 0,
      let description = CMSampleBufferGetFormatDescription(sampleBuffer),
      let stream = CMAudioFormatDescriptionGetStreamBasicDescription(description)
    {
      sampleRate = stream.pointee.mSampleRate
      channelCount = Int(stream.pointee.mChannelsPerFrame)
      windowFrames = max(1, Int(sampleRate * 0.02))
    }
    guard sampleRate > 0, channelCount > 0, windowFrames > 0 else {
      fail("decoded audio format is unavailable")
    }
    guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
      continue
    }

    let byteCount = CMBlockBufferGetDataLength(dataBuffer)
    var bytes = [UInt8](repeating: 0, count: byteCount)
    let copyStatus = bytes.withUnsafeMutableBytes { destination in
      CMBlockBufferCopyDataBytes(
        dataBuffer,
        atOffset: 0,
        dataLength: byteCount,
        destination: destination.baseAddress!
      )
    }
    guard copyStatus == kCMBlockBufferNoErr else {
      fail("could not read decoded audio samples")
    }

    bytes.withUnsafeBytes { rawBuffer in
      let samples = rawBuffer.bindMemory(to: Float.self)
      let frameCount = samples.count / channelCount
      for frame in 0..<frameCount {
        var value = 0.0
        for channel in 0..<channelCount {
          value += Double(samples[(frame * channelCount) + channel])
        }
        value /= Double(channelCount)
        windowEnergy += value * value
        windowSampleCount += 1

        if windowSampleCount == windowFrames {
          let rms = sqrt(windowEnergy / Double(windowSampleCount))
          windows.append(20 * log10(max(rms, 0.000_001)))
          windowEnergy = 0
          windowSampleCount = 0
        }
      }
    }
  }

  guard reader.status == .completed else {
    fail(reader.error?.localizedDescription ?? "audio decoding failed")
  }

  if windowSampleCount > 0 {
    let rms = sqrt(windowEnergy / Double(windowSampleCount))
    windows.append(20 * log10(max(rms, 0.000_001)))
  }

  let windowDuration = Double(windowFrames) / sampleRate
  let silenceThresholdDB = -42.0
  let minimumSilenceSeconds = 0.12
  var silentRanges: [[String: Double]] = []
  var silentStart: Int?

  for (index, level) in windows.enumerated() {
    if level < silenceThresholdDB {
      if silentStart == nil { silentStart = index }
    } else if let start = silentStart {
      let duration = Double(index - start) * windowDuration
      if duration >= minimumSilenceSeconds {
        silentRanges.append([
          "start": Double(start) * windowDuration,
          "end": Double(index) * windowDuration,
          "duration": duration,
        ])
      }
      silentStart = nil
    }
  }

  if let start = silentStart {
    let duration = Double(windows.count - start) * windowDuration
    if duration >= minimumSilenceSeconds {
      silentRanges.append([
        "start": Double(start) * windowDuration,
        "end": Double(windows.count) * windowDuration,
        "duration": duration,
      ])
    }
  }

  let report: [String: Any] = [
    "durationSeconds": asset.duration.seconds,
    "sampleRate": sampleRate,
    "silenceThresholdDB": silenceThresholdDB,
    "silentRanges": silentRanges,
  ]
  let data = try JSONSerialization.data(
    withJSONObject: report,
    options: [.prettyPrinted, .sortedKeys]
  )
  print(String(decoding: data, as: UTF8.self))
} catch {
  fail(error.localizedDescription)
}
