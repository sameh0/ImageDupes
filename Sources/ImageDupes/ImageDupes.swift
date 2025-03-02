import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit
import ArgumentParser

// MARK: - Main Command Structure

@main
struct ImageDupes: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "imagedupes",
        abstract: "Find duplicate and similar images in directories",
        discussion: "A tool that uses perceptual hashing to find duplicate and visually similar images"
    )
    
    // Command line arguments
    @Argument(help: "Directories to scan for duplicate images")
    var directories: [String]
    
    @Option(name: .shortAndLong, help: "Similarity threshold (0-100, where 100 means identical). Default: 95")
    var threshold: Int = 95
    
    @Option(name: .shortAndLong, help: "Image hash size (higher values provide more accurate comparison but slower performance). Default: 8")
    var hashSize: Int = 8
    
    @Flag(name: .shortAndLong, help: "When set, only shows file paths without interactive prompts")
    var quiet: Bool = false
    
    @Flag(name: .shortAndLong, help: "Recursively scan directories")
    var recursive: Bool = false
    
    @Flag(name: .shortAndLong, help: "Enable interactive deletion mode")
    var delete: Bool = false
    
    @Flag(name: [.long, .customShort("n")], help: "Dry run - only show duplicates without deleting anything")
    var dry: Bool = false
    
    func run() throws {
        guard !directories.isEmpty else {
            throw ValidationError("At least one directory must be specified")
        }
        
        guard threshold >= 0 && threshold <= 100 else {
            throw ValidationError("Threshold must be between 0 and 100")
        }
        
        let imageFinder = ImageDuplicateFinder(
            hashSize: hashSize,
            threshold: Double(threshold) / 100.0,
            recursive: recursive
        )
        
        print("Scanning directories: \(directories.joined(separator: ", "))")
        
        // Find images in the specified directories
        let images = imageFinder.findImages(in: directories)
        print("Found \(images.count) images to analyze")
        
        // Calculate hashes and find duplicates
        let duplicateSets = imageFinder.findDuplicates(in: images)
        
        // Print results
        if duplicateSets.isEmpty {
            print("No duplicate images found.")
            return
        }
        
        print("\nFound \(duplicateSets.count) sets of similar or duplicate images:")
        
        // Process duplicate sets
        for (index, set) in duplicateSets.enumerated() {
            print("\nSet \(index + 1):")
            for (i, imagePath) in set.enumerated() {
                print("  [\(i + 1)] \(imagePath)")
            }
            
            if dry {
                // Dry run mode - just show duplicates, don't delete anything
                continue
            } else if delete && !quiet {
                // Interactive deletion
                handleDuplicateDeletion(set)
            } else if !delete {
                // Automatic deletion - keep the first image, delete the rest
                handleAutomaticDeletion(set)
            }
        }
        
        print("\nFinished processing \(images.count) images.")
    }
    
    private func handleDuplicateDeletion(_ duplicates: [String]) {
        print("\nWhich files would you like to delete? (Enter numbers separated by spaces, 's' to skip this set, or 'q' to quit)")
        
        guard let input = readLine()?.lowercased() else { return }
        
        if input == "q" {
            fatalError("Quitting...")
//            exit(0)
        }
        
        if input == "s" {
            print("Skipping this set...")
            return
        }
        
        let indices = input.split(separator: " ").compactMap { Int($0) }
        for index in indices {
            if index > 0 && index <= duplicates.count {
                let fileToDelete = duplicates[index - 1]
                do {
                    try FileManager.default.removeItem(atPath: fileToDelete)
                    print("Deleted: \(fileToDelete)")
                } catch {
                    print("Failed to delete \(fileToDelete): \(error.localizedDescription)")
                }
            } else {
                print("Invalid index: \(index)")
            }
        }
    }
    
    private func handleAutomaticDeletion(_ duplicates: [String]) {
        // Keep the first image, delete the rest
        print("\nAutomatically keeping: \(duplicates[0])")
        print("Deleting duplicates:")
        
        for i in 1..<duplicates.count {
            let fileToDelete = duplicates[i]
            do {
                try FileManager.default.removeItem(atPath: fileToDelete)
                print("  Deleted: \(fileToDelete)")
            } catch {
                print("  Failed to delete \(fileToDelete): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Image Duplicate Finder

class ImageDuplicateFinder {
    private let hashSize: Int
    private let threshold: Double
    private let recursive: Bool
    
    init(hashSize: Int, threshold: Double, recursive: Bool) {
        self.hashSize = hashSize
        self.threshold = threshold
        self.recursive = recursive
    }
    
    // Find all image files in the specified directories
    func findImages(in directories: [String]) -> [String] {
        let fileManager = FileManager.default
        var imageFiles: [String] = []
        
        let imageExtensions = [
            "jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "heif"
        ]
        
        for directory in directories {
            guard let directoryURL = URL(string: "file://\(directory)") else {
                print("Invalid directory path: \(directory)")
                continue
            }
            
            let enumerationOptions: FileManager.DirectoryEnumerationOptions = recursive ? [.skipsHiddenFiles] : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            
            guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isRegularFileKey], options: enumerationOptions) else {
                print("Unable to access directory: \(directory)")
                continue
            }
            
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                    if fileAttributes.isRegularFile == true {
                        let fileExtension = fileURL.pathExtension.lowercased()
                        if imageExtensions.contains(fileExtension) {
                            imageFiles.append(fileURL.path)
                        }
                    }
                } catch {
                    print("Error accessing file: \(fileURL.path) - \(error.localizedDescription)")
                }
            }
        }
        
        return imageFiles
    }
    
    // Find duplicate images based on perceptual hashing
    func findDuplicates(in imagePaths: [String]) -> [[String]] {
        var imageHashes: [String: UInt64] = [:]
        var processedCount = 0
        
        // Calculate hashes for all images
        for imagePath in imagePaths {
            autoreleasepool {
                if let hash = calculateImageHash(imagePath: imagePath) {
                    imageHashes[imagePath] = hash
                }
                
                processedCount += 1
                if processedCount % 100 == 0 {
                    print("Processed \(processedCount)/\(imagePaths.count) images...")
                }
            }
        }
        
        // Group similar images
        var similarGroups: [[String]] = []
        var processedPaths = Set<String>()
        
        for (path1, hash1) in imageHashes {
            if processedPaths.contains(path1) {
                continue
            }
            
            var similarImages: [String] = [path1]
            
            for (path2, hash2) in imageHashes {
                if path1 != path2 && !processedPaths.contains(path2) {
                    let similarity = calculateSimilarity(between: hash1, and: hash2)
                    if similarity >= threshold {
                        similarImages.append(path2)
                    }
                }
            }
            
            if similarImages.count > 1 {
                similarGroups.append(similarImages)
                for path in similarImages {
                    processedPaths.insert(path)
                }
            } else {
                processedPaths.insert(path1)
            }
        }
        
        return similarGroups
    }
    
    // Calculate perceptual hash for an image
    private func calculateImageHash(imagePath: String) -> UInt64? {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            print("Failed to load image: \(imagePath)")
            return nil
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Failed to convert to CGImage: \(imagePath)")
            return nil
        }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        
        // Resize to a small square
        let resizeFilter = CIFilter.lanczosScaleTransform()
        let size = CGFloat(hashSize)
        resizeFilter.inputImage = ciImage
        resizeFilter.scale = Float(size / max(ciImage.extent.width, ciImage.extent.height))
        guard let resizedImage = resizeFilter.outputImage else {
            print("Failed to resize image: \(imagePath)")
            return nil
        }
        
        // Convert to grayscale
        let grayFilter = CIFilter.colorControls()
        grayFilter.inputImage = resizedImage
        grayFilter.saturation = 0
        
        guard let grayscaleImage = grayFilter.outputImage,
              let outputCGImage = context.createCGImage(grayscaleImage, from: grayscaleImage.extent) else {
            print("Failed to convert to grayscale: \(imagePath)")
            return nil
        }
        
        // Calculate average pixel value
        guard let colorSpace = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2) else {
            print("Failed to create color space: \(imagePath)")
            return nil
        }
        
        guard let context = CGContext(data: nil,
                                     width: Int(size),
                                     height: Int(size),
                                     bitsPerComponent: 8,
                                     bytesPerRow: Int(size),
                                     space: colorSpace,
                                     bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            print("Failed to create context: \(imagePath)")
            return nil
        }
        
        context.draw(outputCGImage, in: CGRect(x: 0, y: 0, width: size, height: size))
        
        guard let buffer = context.data else {
            print("Failed to get pixel data: \(imagePath)")
            return nil
        }
        
        // Calculate average brightness
        let pixelBuffer = buffer.bindMemory(to: UInt8.self, capacity: Int(size * size))
        let pixelPointer = UnsafeBufferPointer(start: pixelBuffer, count: Int(size * size))
        let pixels = Array(pixelPointer)
        
        // Use UInt64 for the sum to prevent overflow
        let sum = pixels.reduce(UInt64(0), { $0 + UInt64($1) })
        let average = UInt8(sum / UInt64(pixels.count))

        // Create hash based on whether pixel is brighter than average
        var hash: UInt64 = 0
        for i in 0..<min(64, pixels.count) {
            if pixels[i] >= average {
                hash |= 1 << i
            }
        }
        
        return hash
    }
    
    // Calculate Hamming distance similarity between two hashes
    private func calculateSimilarity(between hash1: UInt64, and hash2: UInt64) -> Double {
        let hammingDistance = calculateHammingDistance(hash1, hash2)
        return 1.0 - (Double(hammingDistance) / 64.0)
    }
    
    // Calculate the Hamming distance between two hashes
    private func calculateHammingDistance(_ hash1: UInt64, _ hash2: UInt64) -> Int {
        var distance = 0
        var xor = hash1 ^ hash2
        
        // Count the number of 1s in the XOR result (which is the number of different bits)
        while xor != 0 {
            distance += 1
            xor &= xor - 1
        }
        
        return distance
    }
}
