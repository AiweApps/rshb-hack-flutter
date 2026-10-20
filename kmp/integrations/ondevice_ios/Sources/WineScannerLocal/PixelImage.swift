import Foundation
import CoreGraphics
import ImageIO

public enum LocalScanError: Error {
    case invalidImage, invalidRegion, missingAsset(String), invalidAsset(String), invalidModelOutput, requestBudgetExceeded
}

/// EXIF-oriented, white-composited, top-left RGB bytes. No UIKit state or network.
public struct PixelImage {
    public let width: Int
    public let height: Int
    public let rgb: [UInt8]

    public init(width: Int, height: Int, rgb: [UInt8]) throws {
        try self.init(width: width, height: height, rgb: rgb, maximumPixels: 24_000_000)
    }

    /// Only the source-bound primary SSD's2x internal canvas uses the larger bound.
    init(width: Int, height: Int, rgb: [UInt8], maximumPixels: Int) throws {
        guard width > 0, height > 0, width <= maximumPixels / height,
              rgb.count == width * height * 3 else { throw LocalScanError.invalidImage }
        self.width = width; self.height = height; self.rgb = rgb
    }

    public init(data: Data) throws {
        guard !data.isEmpty, data.count <= 20 * 1024 * 1024,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let w = properties[kCGImagePropertyPixelWidth] as? Int,
              let h = properties[kCGImagePropertyPixelHeight] as? Int,
              w > 0, h > 0, w <= 24_000_000 / h,
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw LocalScanError.invalidImage
        }
        var rgba = [UInt8](repeating: 255, count: w * h * 4)
        let decoded = rgba.withUnsafeMutableBytes { storage -> Bool in
            guard let context = CGContext(data: storage.baseAddress, width: w, height: h,
                bitsPerComponent: 8, bytesPerRow: w * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            else { return false }
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: w, height: h))
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard decoded else { throw LocalScanError.invalidImage }
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        let sideways = (5...8).contains(orientation)
        let ow = sideways ? h : w, oh = sideways ? w : h
        var pixels = [UInt8](repeating: 255, count: ow * oh * 3)
        for y in 0..<h {
            for x in 0..<w {
                let dx: Int, dy: Int
                switch orientation {
                case 2: dx = w - 1 - x; dy = y
                case 3: dx = w - 1 - x; dy = h - 1 - y
                case 4: dx = x; dy = h - 1 - y
                case 5: dx = y; dy = x
                case 6: dx = h - 1 - y; dy = x
                case 7: dx = h - 1 - y; dy = w - 1 - x
                case 8: dx = y; dy = w - 1 - x
                default: dx = x; dy = y
                }
                let src = (y * w + x) * 4, dst = (dy * ow + dx) * 3
                pixels[dst] = rgba[src]; pixels[dst + 1] = rgba[src + 1]; pixels[dst + 2] = rgba[src + 2]
            }
        }
        try self.init(width: ow, height: oh, rgb: pixels)
    }

    public func cropped(_ box: [Double]) throws -> PixelImage {
        guard box.count == 4, box.allSatisfy({ $0.isFinite }),
              box[0] >= 0, box[1] >= 0, box[2] <= Double(width), box[3] <= Double(height),
              box[2] > box[0], box[3] > box[1] else { throw LocalScanError.invalidRegion }
        let x = Int(floor(box[0])), y = Int(floor(box[1]))
        let w = Int(ceil(box[2])) - x, h = Int(ceil(box[3])) - y
        var data = [UInt8](); data.reserveCapacity(w * h * 3)
        for row in y..<(y + h) {
            let start = (row * width + x) * 3
            data.append(contentsOf: rgb[start..<(start + w * 3)])
        }
        return try PixelImage(width: w, height: h, rgb: data)
    }

    public func rotatedCCW(_ angle: Int) throws -> PixelImage {
        guard angle == 90 || angle == 270 else { throw LocalScanError.invalidRegion }
        var out = [UInt8](repeating: 0, count: rgb.count)
        for y in 0..<height { for x in 0..<width {
            let dx = angle == 90 ? y : height - 1 - y
            let dy = angle == 90 ? width - 1 - x : x
            let from = (y * width + x) * 3, to = (dy * height + dx) * 3
            for c in 0..<3 { out[to + c] = rgb[from + c] }
        }}
        return try PixelImage(width: height, height: width, rgb: out)
    }

    public enum Resample { case bilinear, bicubic }

    /// Pillow's separable antialiased filters with22-bit coefficients and8-bit
    /// intermediate clipping. Encoder pad defaults to BICUBIC; SSD uses BILINEAR.
    public func resized(width outWidth: Int, height outHeight: Int, method: Resample) throws -> PixelImage {
        guard outWidth > 0, outHeight > 0 else { throw LocalScanError.invalidImage }
        func weights(_ input: Int, _ output: Int) -> [(Int, [Int64])] {
            let scale = Double(input) / Double(output), filterScale = max(1, scale)
            let support = (method == .bilinear ? 1.0 : 2.0) * filterScale
            return (0..<output).map { index in
                let center = (Double(index) + 0.5) * scale
                let lo = max(0, Int(center - support + 0.5))
                let hi = min(input, Int(center + support + 0.5))
                var values = (lo..<hi).map { pixel -> Double in
                    let x = abs((Double(pixel) - center + 0.5) / filterScale)
                    if method == .bilinear { return max(0, 1 - x) }
                    if x < 1 { return ((1.5 * x - 2.5) * x) * x + 1 }
                    if x < 2 { return ((-0.5 * x + 2.5) * x - 4) * x + 2 }
                    return 0
                }
                let total = values.reduce(0, +)
                if total != 0 { values = values.map { $0 / total } }
                return (lo, values.map { Int64($0 * 4_194_304 + ($0 < 0 ? -0.5 : 0.5)) })
            }
        }
        var intermediate = rgb
        if outWidth != width {
            let coefficients = weights(width, outWidth)
            intermediate = [UInt8](repeating: 0, count: outWidth * height * 3)
            for y in 0..<height { for x in 0..<outWidth {
                let (offset, coefficients) = coefficients[x]
                for c in 0..<3 {
                    var value: Int64 = 2_097_152
                    for k in coefficients.indices { value += Int64(rgb[(y * width + offset + k) * 3 + c]) * coefficients[k] }
                    intermediate[(y * outWidth + x) * 3 + c] = UInt8(clamping: value >> 22)
                }
            }}
        }
        var output = intermediate
        if outHeight != height {
            let coefficients = weights(height, outHeight)
            output = [UInt8](repeating: 0, count: outWidth * outHeight * 3)
            for y in 0..<outHeight {
                let (offset, coefficients) = coefficients[y]
                for x in 0..<outWidth { for c in 0..<3 {
                    var value: Int64 = 2_097_152
                    for k in coefficients.indices { value += Int64(intermediate[((offset + k) * outWidth + x) * 3 + c]) * coefficients[k] }
                    output[(y * outWidth + x) * 3 + c] = UInt8(clamping: value >> 22)
                }}
            }
        }
        return try PixelImage(width: outWidth, height: outHeight, rgb: output)
    }

    public func padded(side: Int, method: Resample, encoderCentering: Bool) throws -> (PixelImage, Int, Int, Double, Double) {
        let scale = Double(side) / Double(max(width, height))
        let w = max(1, Int((Double(width) * scale).rounded(.toNearestOrEven)))
        let h = max(1, Int((Double(height) * scale).rounded(.toNearestOrEven)))
        let x = encoderCentering ? Int((Double(side - w) / 2).rounded(.toNearestOrEven)) : (side - w) / 2
        let y = encoderCentering ? Int((Double(side - h) / 2).rounded(.toNearestOrEven)) : (side - h) / 2
        let resized = try resized(width: w, height: h, method: method)
        var out = [UInt8](repeating: 255, count: side * side * 3)
        for row in 0..<h {
            let destination = ((row + y) * side + x) * 3
            out.replaceSubrange(destination..<(destination + w * 3), with: resized.rgb[(row * w * 3)..<((row + 1) * w * 3)])
        }
        return (try PixelImage(width: side, height: side, rgb: out), x, y, Double(w) / Double(width), Double(h) / Double(height))
    }

    public func cgImage() throws -> CGImage {
        guard let provider = CGDataProvider(data: Data(rgb) as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 24,
                bytesPerRow: width * 3, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: [],
                provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        else { throw LocalScanError.invalidImage }
        return image
    }
}
