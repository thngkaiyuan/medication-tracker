#!/usr/bin/env swift

import AVFoundation
import Foundation

private func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("error: \(message)\n".utf8))
  exit(1)
}

guard CommandLine.arguments.count == 2 else {
  fail("usage: inspect-app-preview.swift VIDEO")
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
let asset = AVURLAsset(url: url)
guard let video = asset.tracks(withMediaType: .video).first else {
  fail("video track is missing")
}

let bounds = CGRect(origin: .zero, size: video.naturalSize)
  .applying(video.preferredTransform)
  .standardized

var report: [String: Any] = [
  "durationSeconds": asset.duration.seconds,
  "fileBytes": (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0,
  "height": Int(abs(bounds.height)),
  "videoBitrate": Int(video.estimatedDataRate.rounded()),
  "videoFrameRate": Double(video.nominalFrameRate),
  "width": Int(abs(bounds.width)),
]

if let rawVideoDescription = video.formatDescriptions.first {
  let videoDescription = rawVideoDescription as! CMFormatDescription
  report["videoCodec"] = UTCreateStringForOSType(
    CMFormatDescriptionGetMediaSubType(videoDescription)
  ).takeRetainedValue() as String
}

if let audio = asset.tracks(withMediaType: .audio).first {
  report["audioBitrate"] = Int(audio.estimatedDataRate.rounded())
  if let rawAudioDescription = audio.formatDescriptions.first {
    let audioDescription = rawAudioDescription as! CMAudioFormatDescription
    guard let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(
      audioDescription
    ) else {
      fail("audio stream description is missing")
    }
    report["audioChannels"] = Int(basicDescription.pointee.mChannelsPerFrame)
    report["audioSampleRate"] = Int(basicDescription.pointee.mSampleRate.rounded())
    report["audioCodec"] = UTCreateStringForOSType(
      basicDescription.pointee.mFormatID
    ).takeRetainedValue() as String
  }
}

let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
print(String(decoding: data, as: UTF8.self))
