//
//  BatchEditInteractiveHelpView.swift
//  Tunetag
//
//  Created by シン・ジャスティン on 2023/09/30.
//

import AVKit
import Komponents
import SwiftUI

struct BatchEditInteractiveHelpView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @State var player: AVQueuePlayer?
    @State var playerLooper: AVPlayerLooper?
    @State var helpSectionIndex: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20.0) {
                    Text("BatchEdit.Help.GuidanceHint.Top")
                        .font(.title)
                        .bold()
                    Picker(selection: $helpSectionIndex, content: {
                        Text("BatchEdit.Help.InApp.Files")
                            .tag(0)
                        Text("BatchEdit.Help.InApp.Folders")
                            .tag(1)
                        Text("BatchEdit.Help.ExternalApps")
                            .tag(2)
                    }, label: { })
                    .pickerStyle(.segmented)
                    .onChange(of: helpSectionIndex, perform: { _ in
                        setPlayer()
                    })
                    Text("BatchEdit.Help.GuidanceHint.Bottom")
                        .font(.title)
                        .bold()
                    Divider()
                    switch helpSectionIndex {
                    case 0: Text("BatchEdit.Help.InApp.Files.Text")
                    case 1: Text("BatchEdit.Help.InApp.Folders.Text")
                    case 2: Text("BatchEdit.Help.ExternalApps.Text")
                    default: Color.clear
                    }
                    if let player = player {
                        VideoPlayer(player: player)
                            .aspectRatio(1.0, contentMode: .fit)
                            .disabled(true)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(20.0)
            }
            .toolbar {
                ToolbarItem {
                    CloseButton {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setPlayer()
            }
            .onChange(of: scenePhase, perform: { newValue in
                switch newValue {
                case .active:
                    if let player = player {
                        player.play()
                    }
                default: break
                }
            })
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("ViewTitle.BatchEditHelp")
        }
    }

    func setPlayer() {
        var resourceName: String = ""
        switch helpSectionIndex {
        case 0: resourceName = "BatchEdit.InAppFiles"
        case 1: resourceName = "BatchEdit.InAppFolders"
        case 2: resourceName = "BatchEdit.ExternalApps"
        default:
            player = nil
            return
        }
        let playerItem = AVPlayerItem(asset: AVAsset(url: Bundle.main.url(forResource: resourceName,
                                                                          withExtension: "mov")!))
        player = AVQueuePlayer(items: [playerItem])
        playerLooper = AVPlayerLooper(player: player!, templateItem: playerItem)
        player!.isMuted = true
        player!.audiovisualBackgroundPlaybackPolicy = .pauses
        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,
                                                             mode: .default, options: .mixWithOthers)
        player!.play()
    }
}
