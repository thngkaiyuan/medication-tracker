#!/usr/bin/env swift

import AppKit
import AVFoundation

private func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("error: \(message)\n".utf8))
  exit(1)
}

guard CommandLine.arguments.count >= 4 else {
  fail("usage: extract-video-frames.swift INPUT_VIDEO OUTPUT_PREFIX TIME_SECONDS...")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputPrefix = CommandLine.arguments[2]
let times = CommandLine.arguments.dropFirst(3).compactMap(Double.init)
guard times.count == CommandLine.arguments.count - 3 else {
  fail("every requested frame time must be a number")
}

let asset = AVURLAsset(url: inputURL)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

for (index, seconds) in times.enumerated() {
  do {
    let image = try generator.copyCGImage(
      at: CMTime(seconds: seconds, preferredTimescale: 600),
      actualTime: nil
    )
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
      fail("could not encode frame \(index + 1)")
    }
    let outputURL = URL(fileURLWithPath: "\(outputPrefix)-\(index + 1).png")
    try data.write(to: outputURL)
    print(outputURL.path)
  } catch {
    fail("could not extract frame \(index + 1): \(error.localizedDescription)")
  }
}
