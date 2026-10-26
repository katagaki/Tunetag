//
//  OnlineLookupView.swift
//  Tunetag
//

import PreludeLookup
import SwiftUI

/// Finds the album that the selected files belong to, by recognizing their audio or by searching for their names.
struct OnlineLookupView: View {

    @Environment(\.dismiss) var dismiss

    var files: [FSFile]
    var onApply: () -> Void

    @State var artist: String
    @State var album: String
    @State var path: [OnlineRelease] = []
    @State var results: [OnlineRelease] = []
    @State var identifiers: [String: Set<String>] = [:]
    @State var isIdentifying: Bool = true
    @State var isSearching: Bool = false
    @State var showsSearchError: Bool = false
    @FocusState var isAlbumFocused: Bool

    init(files: [FSFile], artist: String, album: String, onApply: @escaping () -> Void) {
        self.files = files
        self.onApply = onApply
        _artist = State(initialValue: artist)
        _album = State(initialValue: album)
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if isIdentifying || isSearching {
                    Section {
                        VStack(spacing: 12.0) {
                            ProgressView()
                                .controlSize(.large)
                            if isIdentifying {
                                Text("OnlineLookup.Identifying")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .listRowBackground(Color.clear)
                } else if results.isEmpty {
                    Section {
                        ContentUnavailableView.search
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(results) { release in
                            NavigationLink(value: release) {
                                OnlineReleaseRow(release: release)
                            }
                        }
                    } header: {
                        ListSectionHeader(text: "OnlineLookup.Results")
                    }
                    .editorRowBackground()
                }
                if !isIdentifying {
                    searchSection
                }
            }
            .editorListBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("OnlineLookup.Title")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: OnlineRelease.self) { release in
                OnlineReleaseView(release: release, files: files, identifiers: identifiers) {
                    onApply()
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close) {
                            dismiss()
                        }
                    } else {
                        Button("Shared.Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("OnlineLookup.SearchFailed", isPresented: $showsSearchError) {
                Button("Shared.OK", role: .cancel) { }
            }
            .task {
                await identify()
            }
        }
    }

    var searchSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 2.0) {
                TagFieldLabel(title: "Tag.Artist")
                    .accessibilityHidden(true)
                TextField("", text: $artist)
                    .tagFieldBox()
                    .submitLabel(.next)
                    .onSubmit { isAlbumFocused = true }
                    .accessibilityLabel(Text("Tag.Artist"))
            }
            VStack(alignment: .leading, spacing: 2.0) {
                TagFieldLabel(title: "Tag.Album")
                    .accessibilityHidden(true)
                TextField("", text: $album)
                    .tagFieldBox()
                    .focused($isAlbumFocused)
                    .submitLabel(.search)
                    .onSubmit { Task { await search() } }
                    .accessibilityLabel(Text("Tag.Album"))
            }
            Button("OnlineLookup.Search", systemImage: "magnifyingglass") {
                Task { await search() }
            }
            .disabled(!canSearch || isSearching)
        } header: {
            ListSectionHeader(text: "OnlineLookup.SearchByName")
        }
        .autocorrectionDisabled()
        .editorRowBackground()
    }

    var canSearch: Bool {
        !trimmedArtist.isEmpty || !trimmedAlbum.isEmpty
    }

    var trimmedArtist: String {
        artist.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedAlbum: String {
        album.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Recognizes the files and opens their album straight away if one clearly fits.
    func identify() async {
        guard isIdentifying else { return }
        let result = await AutomaticLookup.lookUp(filesAt: files.map(\.path),
                                                  artist: trimmedArtist, album: trimmedAlbum)
        results = result.releases
        identifiers = result.identifiers
        withAnimation {
            isIdentifying = false
        }
        if let bestMatch = result.bestMatch {
            path = [bestMatch]
        }
    }

    func search() async {
        guard canSearch, !isSearching else { return }
        isAlbumFocused = false
        isSearching = true
        results = []
        do {
            results = try await AutomaticLookup.search(artist: trimmedArtist, album: trimmedAlbum)
        } catch {
            showsSearchError = true
        }
        isSearching = false
    }
}

struct OnlineReleaseRow: View {

    var release: OnlineRelease

    var body: some View {
        HStack(spacing: 12.0) {
            OnlineArtwork(url: release.thumbnailURL)
                .frame(width: 56.0, height: 56.0)
            VStack(alignment: .leading, spacing: 2.0) {
                Text(verbatim: release.title)
                    .font(.body)
                    .lineLimit(2)
                Text(verbatim: release.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(verbatim: subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    var subtitle: String {
        var parts: [String] = []
        if let year = release.year {
            parts.append(year)
        }
        if let trackCount = release.trackCount {
            parts.append(String(localized: "OnlineLookup.TrackCount \(trackCount)"))
        }
        parts.append(contentsOf: release.details)
        parts.append(release.source.name)
        return parts.joined(separator: " · ")
    }
}

/// Album art loaded from an online source, with the generic album art while it loads or if it's missing.
struct OnlineArtwork: View {

    var url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image("Album.Generic")
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6.0))
        .overlay {
            RoundedRectangle(cornerRadius: 6.0)
                .stroke(.primary.opacity(0.1), lineWidth: 0.5)
        }
        .accessibilityHidden(true)
    }
}
