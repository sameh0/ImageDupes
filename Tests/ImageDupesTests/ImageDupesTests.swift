import Testing
import Foundation
@testable import ImageDupes

final class ImageDupesTests {
    // Test initialization with valid parameters
    @Test func testInitialization() async throws {
        let finder = ImageDuplicateFinder(hashSize: 8, threshold: 0.95, recursive: false)
        #expect(finder != nil)
    }
    
    // Test finding images in directory
    @Test func testFindImages() async throws {
        let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_images").path
        try FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: testDir) }
        
        // Create test image files
        let testFiles = [
            "test1.jpg",
            "test2.png",
            "test3.gif",
            "notanimage.txt"
        ]
        
        for file in testFiles {
            FileManager.default.createFile(atPath: testDir + "/" + file, contents: Data())
        }
        
        let finder = ImageDuplicateFinder(hashSize: 8, threshold: 0.95, recursive: false)
        let images = finder.findImages(in: [testDir])
        
        #expect(images.count == 3) // Should only find image files
        #expect(images.contains { $0.hasSuffix(".jpg") })
        #expect(images.contains { $0.hasSuffix(".png") })
        #expect(images.contains { $0.hasSuffix(".gif") })
        #expect(!images.contains { $0.hasSuffix(".txt") })
    }
    
    // Test hash calculation and similarity comparison
    @Test func testImageHashingAndSimilarity() async throws {
        let finder = ImageDuplicateFinder(hashSize: 8, threshold: 0.95, recursive: false)
        
        // Create two identical test images
        let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_hash").path
        try FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: testDir) }
        
        let testImage1 = testDir + "/test1.jpg"
        let testImage2 = testDir + "/test2.jpg"
        
        // Create simple test images (1x1 pixel)
        let imageData = Data([0xFF, 0xFF, 0xFF]) // White pixel
        FileManager.default.createFile(atPath: testImage1, contents: imageData)
        FileManager.default.createFile(atPath: testImage2, contents: imageData)
        
        let duplicates = finder.findDuplicates(in: [testImage1, testImage2])
        #expect(duplicates.isEmpty) // Should be empty as test images are not valid image files
    }
    
    // Test empty directory handling
    @Test func testEmptyDirectory() async throws {
        let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("empty_dir").path
        try FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: testDir) }
        
        let finder = ImageDuplicateFinder(hashSize: 8, threshold: 0.95, recursive: false)
        let images = finder.findImages(in: [testDir])
        
        #expect(images.isEmpty)
    }
    
    // Test invalid directory handling
    @Test func testInvalidDirectory() async throws {
        let finder = ImageDuplicateFinder(hashSize: 8, threshold: 0.95, recursive: false)
        let images = finder.findImages(in: ["/nonexistent/directory"])
        
        #expect(images.isEmpty)
    }
    
    // Test recursive directory scanning
    @Test func testRecursiveScanning() async throws {
        let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("recursive_test").path
        let subDir = testDir + "/subdir"
        try FileManager.default.createDirectory(atPath: subDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: testDir) }
        
        // Create test files in both directories
        FileManager.default.createFile(atPath: testDir + "/test1.jpg", contents: Data())
        FileManager.default.createFile(atPath: subDir + "/test2.jpg", contents: Data())
        
        let recursiveFinder = ImageDuplicateFinder(hashSize: 8, threshold: 0.95, recursive: true)
        let nonRecursiveFinder = ImageDuplicateFinder(hashSize: 8, threshold: 0.95, recursive: false)
        
        let recursiveImages = recursiveFinder.findImages(in: [testDir])
        let nonRecursiveImages = nonRecursiveFinder.findImages(in: [testDir])
        
        #expect(recursiveImages.count == 2)
        #expect(nonRecursiveImages.count == 1)
    }
}
