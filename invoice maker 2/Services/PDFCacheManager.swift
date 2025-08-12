//
//  PDFCacheManager.swift
//  invoice maker 2
//
//  PDF cache management with LRU eviction and size limits
//

import Foundation
import PDFKit
import SwiftUI

// MARK: - Cache Entry
private struct CacheEntry {
    let pdf: PDFDocument
    let size: Int
    let accessDate: Date
    
    init(pdf: PDFDocument, size: Int) {
        self.pdf = pdf
        self.size = size
        self.accessDate = Date()
    }
    
    func accessed() -> CacheEntry {
        return CacheEntry(pdf: pdf, size: size)
    }
}

// MARK: - PDF Cache Manager
class PDFCacheManager: ObservableObject {
    static let shared = PDFCacheManager()
    
    // Configuration
    private let maxCacheSize: Int = 50_000_000 // 50MB
    private let maxCacheCount: Int = 20
    private let minEvictionCount: Int = 5 // Evict at least 5 items when limit reached
    
    // Cache storage
    private var cache: [UUID: CacheEntry] = [:]
    private let cacheQueue = DispatchQueue(label: "com.invoicemaker.pdfcache", attributes: .concurrent)
    
    // Metrics
    @Published private(set) var currentCacheSize: Int = 0
    @Published private(set) var cacheHitRate: Double = 0.0
    private var hits: Int = 0
    private var misses: Int = 0
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Retrieve a PDF from cache
    func get(_ id: UUID) -> PDFDocument? {
        return cacheQueue.sync {
            if let entry = cache[id] {
                // Update access date and hit statistics
                cache[id] = entry.accessed()
                hits += 1
                updateHitRate()
                return entry.pdf
            } else {
                misses += 1
                updateHitRate()
                return nil
            }
        }
    }
    
    /// Store a PDF in cache
    func set(_ id: UUID, pdf: PDFDocument) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Estimate PDF size (rough calculation based on page count and content)
            let estimatedSize = self.estimatePDFSize(pdf)
            
            // Check if we need to evict before adding
            if self.shouldEvict(forNewSize: estimatedSize) {
                self.evictLRU()
            }
            
            // Add to cache
            let entry = CacheEntry(pdf: pdf, size: estimatedSize)
            self.cache[id] = entry
            self.currentCacheSize += estimatedSize
            
            // Notify observers on main thread
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    /// Remove a specific PDF from cache
    func remove(_ id: UUID) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            if let entry = self.cache.removeValue(forKey: id) {
                self.currentCacheSize -= entry.size
                
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    /// Clear entire cache
    func clearCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.cache.removeAll()
            self.currentCacheSize = 0
            self.hits = 0
            self.misses = 0
            self.cacheHitRate = 0.0
            
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    /// Get cache statistics
    func getCacheStats() -> (size: String, count: Int, hitRate: String) {
        return cacheQueue.sync {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .binary
            let sizeString = formatter.string(fromByteCount: Int64(currentCacheSize))
            let hitRateString = String(format: "%.1f%%", cacheHitRate * 100)
            return (sizeString, cache.count, hitRateString)
        }
    }
    
    // MARK: - Private Methods
    
    private func estimatePDFSize(_ pdf: PDFDocument) -> Int {
        // Basic estimation: ~50KB per page as baseline
        let pageCount = pdf.pageCount
        var estimatedSize = pageCount * 50_000
        
        // Adjust for content complexity (check first page)
        if let firstPage = pdf.page(at: 0) {
            let bounds = firstPage.bounds(for: .mediaBox)
            let area = bounds.width * bounds.height
            
            // Larger pages typically have more content
            if area > 800 * 1100 { // Larger than letter size
                estimatedSize = Int(Double(estimatedSize) * 1.5)
            }
        }
        
        return estimatedSize
    }
    
    private func shouldEvict(forNewSize newSize: Int) -> Bool {
        return (currentCacheSize + newSize > maxCacheSize) || (cache.count >= maxCacheCount)
    }
    
    private func evictLRU() {
        // Sort entries by access date
        let sortedEntries = cache.sorted { $0.value.accessDate < $1.value.accessDate }
        
        // Determine how many to evict
        var entriesToEvict = minEvictionCount
        var sizeEvicted = 0
        
        // Evict until we have enough space
        for (key, entry) in sortedEntries {
            if entriesToEvict <= 0 && sizeEvicted >= maxCacheSize / 4 {
                break // Evicted enough
            }
            
            cache.removeValue(forKey: key)
            currentCacheSize -= entry.size
            sizeEvicted += entry.size
            entriesToEvict -= 1
        }
    }
    
    private func updateHitRate() {
        let total = hits + misses
        cacheHitRate = total > 0 ? Double(hits) / Double(total) : 0.0
    }
}

// MARK: - SwiftUI Environment
struct PDFCacheManagerKey: EnvironmentKey {
    static let defaultValue = PDFCacheManager.shared
}

extension EnvironmentValues {
    var pdfCacheManager: PDFCacheManager {
        get { self[PDFCacheManagerKey.self] }
        set { self[PDFCacheManagerKey.self] = newValue }
    }
}