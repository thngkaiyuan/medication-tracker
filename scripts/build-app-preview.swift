#!/usr/bin/env swift

import AVFoundation
import AppKit
import QuartzCore

private let renderSize = CGSize(width: 886, height: 1_920)

private struct Timeline {
  let duration: Double
  let countdownStart: Double
  let countdownEnd: Double
  let logStart: Double
  let logEnd: Double
  let historyStart: Double
  let historyEnd: Double
  let notificationStart: Double
  let notificationEnd: Double
  let privacyStart: Double
  let privacyEnd: Double
  let backupStart: Double
  let backupEnd: Double
  let closingStart: Double
}

private func makeTimeline(for narrationDuration: Double) -> Timeline {
  let audioOffset = 0.15
  let isFirstTake = narrationDuration < 27.3
  let countdownStart = audioOffset + (isFirstTake ? 6.10 : 6.38)
  let countdownEnd = audioOffset + (isFirstTake ? 8.68 : 8.80)
  let logStart = audioOffset + (isFirstTake ? 8.92 : 9.06)
  let logEnd = audioOffset + (isFirstTake ? 10.90 : 10.46)
  let historyStart = audioOffset + (isFirstTake ? 11.20 : 10.76)
  let historyEnd = audioOffset + (isFirstTake ? 13.78 : 13.26)
  let notificationStart = audioOffset + (isFirstTake ? 14.44 : 13.92)
  let notificationEnd = audioOffset + (isFirstTake ? 17.28 : 16.98)
  let privacyStart = audioOffset + (isFirstTake ? 17.70 : 17.44)
  let privacyEnd = audioOffset + (isFirstTake ? 19.96 : 19.86)
  let backupStart = audioOffset + (isFirstTake ? 20.18 : 20.04)
  let backupEnd = audioOffset + (isFirstTake ? 23.26 : 22.98)
  let closingStart = audioOffset + (isFirstTake ? 23.50 : 23.86)
  let duration = audioOffset + narrationDuration + 0.25

  return Timeline(
    duration: duration,
    countdownStart: countdownStart,
    countdownEnd: countdownEnd,
    logStart: logStart,
    logEnd: logEnd,
    historyStart: historyStart,
    historyEnd: historyEnd,
    notificationStart: notificationStart,
    notificationEnd: notificationEnd,
    privacyStart: privacyStart,
    privacyEnd: privacyEnd,
    backupStart: backupStart,
    backupEnd: backupEnd,
    closingStart: closingStart
  )
}

private func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("error: \(message)\n".utf8))
  exit(1)
}

private func transformedVideoSize(for track: AVAssetTrack) -> CGSize {
  let bounds = CGRect(origin: .zero, size: track.naturalSize)
    .applying(track.preferredTransform)
    .standardized
  return CGSize(width: abs(bounds.width), height: abs(bounds.height))
}

private func transform(
  for track: AVAssetTrack,
  sourceSize: CGSize,
  renderSize: CGSize
) -> CGAffineTransform {
  let orientedBounds = CGRect(origin: .zero, size: track.naturalSize)
    .applying(track.preferredTransform)
    .standardized
  let scale = max(renderSize.width / sourceSize.width, renderSize.height / sourceSize.height)
  let scaledSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
  let offset = CGPoint(
    x: (renderSize.width - scaledSize.width) / 2,
    y: (renderSize.height - scaledSize.height) / 2
  )

  return track.preferredTransform
    .concatenating(CGAffineTransform(
      translationX: -orientedBounds.minX,
      y: -orientedBounds.minY
    ))
    .concatenating(CGAffineTransform(scaleX: scale, y: scale))
    .concatenating(CGAffineTransform(translationX: offset.x, y: offset.y))
}

guard CommandLine.arguments.count >= 3 else {
  fail("usage: build-app-preview.swift INPUT_VIDEO OUTPUT_MP4 [NARRATION_AUDIO] [NOTIFICATION_IMAGE]")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let narrationURL = CommandLine.arguments.count >= 4
  ? URL(fileURLWithPath: CommandLine.arguments[3])
  : nil
let notificationImageURL = CommandLine.arguments.count >= 5
  ? URL(fileURLWithPath: CommandLine.arguments[4])
  : nil

guard FileManager.default.fileExists(atPath: inputURL.path) else {
  fail("input video does not exist: \(inputURL.path)")
}
guard !FileManager.default.fileExists(atPath: outputURL.path) else {
  fail("output already exists: \(outputURL.path)")
}
if let narrationURL, !FileManager.default.fileExists(atPath: narrationURL.path) {
  fail("narration audio does not exist: \(narrationURL.path)")
}
if let notificationImageURL,
  !FileManager.default.fileExists(atPath: notificationImageURL.path)
{
  fail("notification image does not exist: \(notificationImageURL.path)")
}

let inputAsset = AVURLAsset(url: inputURL)
guard let sourceVideoTrack = inputAsset.tracks(withMediaType: .video).first else {
  fail("input has no video track")
}
guard inputAsset.duration.seconds >= 68 else {
  fail("input is too short for the configured preview range")
}

let narrationAsset = narrationURL.map(AVURLAsset.init(url:))
let narrationDurationSeconds = narrationAsset?.duration.seconds ?? 27.0106
private let previewTimeline = makeTimeline(for: narrationDurationSeconds)
let previewDuration = CMTime(seconds: previewTimeline.duration, preferredTimescale: 600)

let composition = AVMutableComposition()
guard let compositionVideoTrack = composition.addMutableTrack(
  withMediaType: .video,
  preferredTrackID: kCMPersistentTrackID_Invalid
) else {
  fail("could not create composition video track")
}

do {
  var cursor = CMTime.zero

  func appendClip(sourceStart: Double, sourceDuration: Double, outputEnd: Double) throws {
    let sourceRange = CMTimeRange(
      start: CMTime(seconds: sourceStart, preferredTimescale: 600),
      duration: CMTime(seconds: sourceDuration, preferredTimescale: 600)
    )
    let desiredEnd = CMTime(seconds: outputEnd, preferredTimescale: 600)
    let desiredDuration = CMTimeSubtract(desiredEnd, cursor)
    guard CMTimeCompare(desiredDuration, .zero) > 0 else {
      fail("preview timeline contains a non-positive clip")
    }
    try compositionVideoTrack.insertTimeRange(sourceRange, of: sourceVideoTrack, at: cursor)
    compositionVideoTrack.scaleTimeRange(
      CMTimeRange(start: cursor, duration: sourceRange.duration),
      toDuration: desiredDuration
    )
    cursor = desiredEnd
  }

  // Establish the uncluttered, all-ready home screen while the introduction plays.
  try appendClip(
    sourceStart: 27.55,
    sourceDuration: 1.75,
    outputEnd: previewTimeline.countdownStart
  )

  // Match “see when the wait limits you entered clear” with a visible 3, 2, 1,
  // ready transition and no modal obscuring the medication cards.
  let countdownReady = previewTimeline.countdownEnd - 0.55
  try appendClip(sourceStart: 23.50, sourceDuration: 2.70, outputEnd: countdownReady)
  try appendClip(sourceStart: 27.55, sourceDuration: 0.40, outputEnd: previewTimeline.countdownEnd)
  try appendClip(sourceStart: 27.55, sourceDuration: 0.40, outputEnd: previewTimeline.logStart)

  // Open the action sheet, hold it just long enough to read, and land the dose
  // tap near the spoken word “tap.”
  let logDialogReady = previewTimeline.logStart + 0.34
  let logTap = previewTimeline.logEnd - 0.38
  try appendClip(sourceStart: 29.45, sourceDuration: 0.85, outputEnd: logDialogReady)
  try appendClip(sourceStart: 30.30, sourceDuration: 2.50, outputEnd: logTap)
  try appendClip(sourceStart: 32.80, sourceDuration: 0.85, outputEnd: previewTimeline.logEnd)

  // Let the newly orange medication register, then show the View Records path
  // and newest-first history while the narration discusses reviewing history.
  try appendClip(sourceStart: 33.65, sourceDuration: 0.85, outputEnd: previewTimeline.historyStart)
  let historyArrives = previewTimeline.historyStart + 0.90
  try appendClip(sourceStart: 35.35, sourceDuration: 3.35, outputEnd: historyArrives)
  try appendClip(sourceStart: 38.70, sourceDuration: 1.00, outputEnd: previewTimeline.historyEnd)

  // Hold history through the narration pause. The notification still is layered
  // above this footage for the exact “Ready notifications…” sentence.
  try appendClip(
    sourceStart: 39.00,
    sourceDuration: 0.80,
    outputEnd: previewTimeline.notificationStart
  )
  try appendClip(
    sourceStart: 39.20,
    sourceDuration: 1.00,
    outputEnd: previewTimeline.notificationEnd
  )

  // Move cleanly to Privacy & About for “your data stays on your device.”
  try appendClip(sourceStart: 47.55, sourceDuration: 0.45, outputEnd: previewTimeline.privacyStart)
  try appendClip(sourceStart: 48.00, sourceDuration: 4.80, outputEnd: previewTimeline.privacyEnd)

  // Show the menu labels, then the native share sheet, for portable backups.
  try appendClip(sourceStart: 55.75, sourceDuration: 0.40, outputEnd: previewTimeline.backupStart)
  let shareArrives = previewTimeline.backupStart + 1.45
  try appendClip(sourceStart: 56.15, sourceDuration: 3.20, outputEnd: shareArrives)
  try appendClip(sourceStart: 59.35, sourceDuration: 2.20, outputEnd: previewTimeline.backupEnd)
  try appendClip(sourceStart: 60.10, sourceDuration: 1.00, outputEnd: previewTimeline.closingStart)

  // Finish on the core green-orange-green home state, never on a dialog.
  try appendClip(sourceStart: 65.35, sourceDuration: 2.20, outputEnd: previewTimeline.duration)
} catch {
  fail("could not insert source footage: \(error.localizedDescription)")
}

if let narrationAsset {
  if let narrationTrack = narrationAsset.tracks(withMediaType: .audio).first,
    let compositionAudioTrack = composition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid
    )
  {
    let narrationStart = CMTime(seconds: 0.15, preferredTimescale: 600)
    let maximumDuration = CMTimeSubtract(previewDuration, narrationStart)
    let narrationDuration = CMTimeMinimum(narrationAsset.duration, maximumDuration)
    do {
      try compositionAudioTrack.insertTimeRange(
        CMTimeRange(start: .zero, duration: narrationDuration),
        of: narrationTrack,
        at: narrationStart
      )
    } catch {
      fail("could not insert narration: \(error.localizedDescription)")
    }
  } else {
    fail("narration file has no audio track")
  }
}

let videoInstruction = AVMutableVideoCompositionInstruction()
videoInstruction.timeRange = CMTimeRange(start: .zero, duration: previewDuration)

let layerInstruction = AVMutableVideoCompositionLayerInstruction(
  assetTrack: compositionVideoTrack
)
let sourceSize = transformedVideoSize(for: sourceVideoTrack)
layerInstruction.setTransform(
  transform(for: sourceVideoTrack, sourceSize: sourceSize, renderSize: renderSize),
  at: .zero
)
layerInstruction.setOpacityRamp(
  fromStartOpacity: 0,
  toEndOpacity: 1,
  timeRange: CMTimeRange(
    start: .zero,
    duration: CMTime(seconds: 0.35, preferredTimescale: 600)
  )
)
layerInstruction.setOpacityRamp(
  fromStartOpacity: 1,
  toEndOpacity: 0,
  timeRange: CMTimeRange(
    start: CMTimeSubtract(
      previewDuration,
      CMTime(seconds: 0.25, preferredTimescale: 600)
    ),
    duration: CMTime(seconds: 0.25, preferredTimescale: 600)
  )
)
videoInstruction.layerInstructions = [layerInstruction]

let videoComposition = AVMutableVideoComposition()
videoComposition.instructions = [videoInstruction]
videoComposition.renderSize = renderSize
videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
videoComposition.renderScale = 1

if let notificationImageURL {
  guard let image = NSImage(contentsOf: notificationImageURL),
    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
  else {
    fail("could not decode notification image")
  }

  let parentLayer = CALayer()
  parentLayer.frame = CGRect(origin: .zero, size: renderSize)

  let videoLayer = CALayer()
  videoLayer.frame = parentLayer.frame
  parentLayer.addSublayer(videoLayer)

  let notificationLayer = CALayer()
  notificationLayer.frame = parentLayer.frame
  notificationLayer.contents = cgImage
  notificationLayer.contentsGravity = .resizeAspectFill
  notificationLayer.opacity = 0

  let notificationDuration = previewTimeline.notificationEnd - previewTimeline.notificationStart
  let fadeDuration = 0.06
  let opacity = CAKeyframeAnimation(keyPath: "opacity")
  opacity.beginTime = AVCoreAnimationBeginTimeAtZero + previewTimeline.notificationStart
  opacity.duration = notificationDuration
  opacity.values = [0, 1, 1, 0]
  opacity.keyTimes = [
    0,
    NSNumber(value: fadeDuration / notificationDuration),
    NSNumber(value: 1 - (fadeDuration / notificationDuration)),
    1,
  ]
  opacity.isRemovedOnCompletion = false
  opacity.fillMode = .forwards
  notificationLayer.add(opacity, forKey: "notification-opacity")
  parentLayer.addSublayer(notificationLayer)

  videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
    postProcessingAsVideoLayer: videoLayer,
    in: parentLayer
  )
}

guard let exporter = AVAssetExportSession(
  asset: composition,
  presetName: AVAssetExportPresetHighestQuality
) else {
  fail("could not create export session")
}
guard exporter.supportedFileTypes.contains(.mp4) else {
  fail("MP4 export is unavailable")
}

exporter.outputURL = outputURL
exporter.outputFileType = .mp4
exporter.shouldOptimizeForNetworkUse = true
exporter.videoComposition = videoComposition

let semaphore = DispatchSemaphore(value: 0)
exporter.exportAsynchronously {
  semaphore.signal()
}
semaphore.wait()

guard exporter.status == .completed else {
  fail(exporter.error?.localizedDescription ?? "export failed with status \(exporter.status.rawValue)")
}

print(outputURL.path)
