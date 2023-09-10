//
//  BatchFileManager.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/08.
//

import Foundation

class BatchFileManager: ObservableObject {

    @Published var files: [FSFile] = []

    func addFile(_ file: FSFile) {
        if !files.contains(file) {
            debugPrint("Adding file to queue: \(file.path)")
            files.append(file)
        }
    }

    func addFiles(_ files: [FSFile]) {
        for file in files where !self.files.contains(file) {
            debugPrint("Adding file to queue: \(file.path)")
            self.files.append(file)
        }
    }
}
