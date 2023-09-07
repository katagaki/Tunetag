//
//  FilesystemManager.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/07.
//

import Foundation

class FilesystemManager: ObservableObject {

    let manager = FileManager.default
    var documentsDirectory: String?

    init() {
        do {
            let documentsDirectoryURL = try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
            self.documentsDirectory = documentsDirectoryURL.absoluteString
            manager.createFile(atPath: "\(documentsDirectoryURL.path())Drop Your Files Here", contents: "".data(using: .utf8))
        } catch {
            debugPrint(error.localizedDescription)
            documentsDirectory = ""
        }
    }

    func files(in subPath: String = "") -> [any FilesystemObject] {
        debugPrint("Enumerating files in '\(subPath)' (blank if root).")
        do {
            if let documentsDirectory = documentsDirectory,
               let documentsDirectoryURL = URL(string: documentsDirectory) {
                if subPath == "" {
                    return try manager
                        .contentsOfDirectory(at: documentsDirectoryURL,
                                             includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                                             options: [.skipsHiddenFiles]).compactMap { url in
                            if url.hasDirectoryPath {
                                return FSDirectory(name: url.lastPathComponent,
                                                   path: url.path,
                                                   files: files(in: url.path(percentEncoded: true)))
                            } else {
                                if url.pathExtension.lowercased() == "mp3" {
                                    return FSFile(name: url.lastPathComponent,
                                                  path: url.path,
                                                  filetype: "")
                                }
                            }
                            return nil
                        }
                } else {
                    return try manager
                        .contentsOfDirectory(at: URL(string: subPath)!,
                                             includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                                             options: [.skipsHiddenFiles]).compactMap { url in
                            if url.hasDirectoryPath {
                                return FSDirectory(name: url.lastPathComponent,
                                                   path: url.path,
                                                   files: files(in: url.path(percentEncoded: true)))
                            } else {
                                if url.pathExtension.lowercased() == "mp3" {
                                    return FSFile(name: url.lastPathComponent,
                                                  path: url.path,
                                                  filetype: "")
                                }
                            }
                            return nil
                        }
                }
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return []
    }
}
