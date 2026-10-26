//
//  OnlineReleaseView.swift
//  Tunetag
//

import SwiftUI

/// Shows how an online release's tracks match the selected files, and applies the chosen fields.
struct OnlineReleaseView: View {

    var release: OnlineRelease
    var files: [FSFile]
    var onApply: () -> Void

    @AppStorage("OnlineLookup.Fields") var storedFields: String =
        LookupField.defaultFields.map(\.rawValue).sorted().joined(separator: ",")
    @State var detail: OnlineReleaseDetail?
    @State var matches: [LookupMatch] = []
    @State var isLoading: Bool = true
    @State var isApplying: Bool = false
    @State var showsApplyError: Bool = false

    var body: some View {
        List {
            Section {
                releaseHeader
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            if let detail {
                Section {
                    ForEach($matches) { $match in
                        LookupMatchRow(match: $match, tracks: detail.tracks)
                    }
                } header: {
                    ListSectionHeader(text: "OnlineLookup.Matches")
                } footer: {
                    Text("OnlineLookup.Matches.Footer")
                }
                .editorRowBackground()
                Section {
                    ForEach(LookupField.allCases.filter { $0.isAvailable(in: detail) }) { field in
                        Toggle(isOn: binding(for: field)) {
                            Text(field.name)
                        }
                    }
                } header: {
                    ListSectionHeader(text: "OnlineLookup.Fields")
                }
                .editorRowBackground()
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .controlSize(.large)
            } else if detail == nil {
                ContentUnavailableView("OnlineLookup.LoadFailed", systemImage: "wifi.exclamationmark")
            }
        }
        .editorListBackground()
        .disabled(isApplying)
        .navigationTitle(Text(verbatim: release.title))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if detail != nil {
                applyButton
                    .padding([.leading, .trailing, .bottom])
            }
        }
        .alert("TagEditor.SaveFailed.Message", isPresented: $showsApplyError) {
            Button("Shared.OK", role: .cancel) { }
        }
        .task {
            await load()
        }
    }

    var releaseHeader: some View {
        HStack(spacing: 16.0) {
            OnlineArtwork(url: (detail?.release ?? release).thumbnailURL)
                .frame(width: 96.0, height: 96.0)
            VStack(alignment: .leading, spacing: 4.0) {
                Text(verbatim: release.title)
                    .font(.headline)
                    .lineLimit(3)
                Text(verbatim: release.artist)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let subtitle {
                    Text(verbatim: subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8.0)
    }

    var subtitle: String? {
        let parts = [release.year, detail?.genre, release.source.name].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var applyButton: some View {
        Button {
            Task { await apply() }
        } label: {
            Group {
                if isApplying {
                    ProgressView()
                        .tint(.white)
                        .padding([.top, .bottom], 8.0)
                } else {
                    LargeButtonLabel(iconName: "checkmark", text: "OnlineLookup.Apply")
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .modifier(SaveButtonStyleModifier())
        .frame(minHeight: 56.0)
        .disabled(isApplying || selectedFields.isEmpty || !matches.contains { $0.trackID != nil })
    }

    var selectedFields: Set<LookupField> {
        let fields = Set(storedFields.split(separator: ",").compactMap { LookupField(rawValue: String($0)) })
        guard let detail else { return fields }
        return fields.filter { $0.isAvailable(in: detail) }
    }

    func binding(for field: LookupField) -> Binding<Bool> {
        Binding {
            storedFields.split(separator: ",").contains { $0 == field.rawValue }
        } set: { isOn in
            var fields = Set(storedFields.split(separator: ",").map(String.init))
            if isOn {
                fields.insert(field.rawValue)
            } else {
                fields.remove(field.rawValue)
            }
            storedFields = fields.sorted().joined(separator: ",")
        }
    }

    func load() async {
        guard detail == nil else { return }
        isLoading = true
        async let fileMatches = LookupMatch.read(files)
        do {
            let loaded = try await release.source.detail(for: release)
            matches = LookupMatch.matched(await fileMatches, to: loaded.tracks)
            detail = loaded
        } catch {
            _ = await fileMatches
        }
        isLoading = false
    }

    func apply() async {
        guard let detail else { return }
        isApplying = true
        UIApplication.shared.isIdleTimerDisabled = true
        let fields = selectedFields
        var albumArt: Data?
        if fields.contains(.albumArt), let url = detail.release.artworkURL {
            albumArt = try? await LookupSource.data(from: url)
        }
        let artwork = albumArt
        let tracks = Dictionary(uniqueKeysWithValues: detail.tracks.map { ($0.id, $0) })
        let pairs = matches.compactMap { match in
            match.trackID.flatMap { tracks[$0] }.map { (match.file, $0) }
        }
        let allApplied = await Task.detached(priority: .userInitiated) {
            pairs.map { file, track in
                detail.apply(track, fields: fields, albumArt: artwork, to: file)
            }
            .allSatisfy { $0 }
        }.value
        UIApplication.shared.isIdleTimerDisabled = false
        isApplying = false
        if allApplied {
            onApply()
        } else {
            showsApplyError = true
        }
    }
}

struct LookupMatchRow: View {

    @Binding var match: LookupMatch
    var tracks: [OnlineTrack]

    var body: some View {
        Menu {
            Picker("Tag.Track", selection: $match.trackID) {
                Text("BatchEdit.DontChange")
                    .tag(OnlineTrack.ID?.none)
                ForEach(tracks) { track in
                    Text(verbatim: label(for: track))
                        .tag(OnlineTrack.ID?.some(track.id))
                }
            }
        } label: {
            HStack(spacing: 12.0) {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(verbatim: match.file.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let track = selectedTrack {
                        Text(verbatim: label(for: track))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    } else {
                        Text("BatchEdit.DontChange")
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var selectedTrack: OnlineTrack? {
        tracks.first { $0.id == match.trackID }
    }

    var hasMultipleDiscs: Bool {
        tracks.contains { $0.disc != 1 }
    }

    func label(for track: OnlineTrack) -> String {
        let number = hasMultipleDiscs ? "\(track.disc)-\(track.number)" : "\(track.number)"
        return "\(number). \(track.title)"
    }
}
