//
//  TagSummaryCache.swift
//  Tunetag
//

import Foundation

/// Reads the List view's tag values in the background, a chunk at a time, so
/// large folders fill in progressively.
@MainActor
final class TagSummaryCache {

    private var summaries: [String: TagSummary] = [:]
    private var loadTask: Task<Void, Never>?
    var onUpdate: (() -> Void)?

    func summary(for file: FSFile) -> TagSummary? {
        summaries[file.path]
    }

    func value(for column: ListColumn, of file: FSFile) -> String {
        if column == .fileName {
            return file.name
        }
        return summaries[file.path]?.value(for: column) ?? ""
    }

    func load(_ files: [FSFile]) {
        loadTask?.cancel()
        let missing = files.filter { summaries[$0.path] == nil }
        guard !missing.isEmpty else { return }
        loadTask = Task { [weak self] in
            for start in stride(from: 0, to: missing.count, by: 24) {
                let chunk = Array(missing[start..<min(start + 24, missing.count)])
                let loaded = await Task.detached(priority: .utility) {
                    chunk.map { ($0.path, TagSummary(reading: $0)) }
                }.value
                guard !Task.isCancelled, let self else { return }
                for (path, summary) in loaded {
                    summaries[path] = summary
                }
                onUpdate?()
            }
        }
    }

    func invalidate(_ files: [FSFile], reloading visibleFiles: [FSFile]) {
        for file in files {
            summaries[file.path] = nil
        }
        load(visibleFiles)
    }
}
