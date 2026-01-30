import SwiftUI
import CoreData

struct TitleEditorView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let disk: Disk
    let titleToEdit: Title?

    // Fetch all shows for the combo box
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        animation: .default
    )
    private var shows: FetchedResults<Show>


    // Identity
    @State private var showName: String = ""
    @State private var episodeTitle: String = ""

    // Metadata
    @State private var season: String = "01"
    @State private var episode: String = "01"
    @State private var year: String = "2000"
    @State private var genre: String = ""
    @State private var mediaType: String = "TV Show"

    // Track
    @State private var titleNumber: Int = 1
    @State private var isVAM: Bool = false

    // UI + validation
    @State private var errorMessage: String? = nil

    private let mediaTypes = ["TV Show", "Movie"]
    private let appleGenres = [
        "Action", "Adventure", "Animation", "Biography", "Blues", "Comedy", "Crime", "Documentary",
        "Drama", "Family", "Fantasy", "Film Noir", "History", "Horror", "Music", "Musical",
        "Mystery", "Romance", "Sci-Fi", "Short", "Sport", "Thriller", "War", "Western"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(titleToEdit == nil ? "New Title" : "Edit Title")
                .font(.title2)

            if let msg = errorMessage, !msg.isEmpty {
                Text(msg).foregroundColor(.red)
            }

            GroupBox("Identity") {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("Show Name") {
                        HStack(spacing: 8) {
                            TextField("", text: $showName)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 500, alignment: .leading)

                            Menu {
                                ForEach(showNames, id: \.self) { s in
                                    Button(s) { showName = s }
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .imageScale(.small)
                                    .padding(.horizontal, 6)
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }
                        .frame(width: 560, alignment: .leading)
                    }


                    LabeledContent("Episode Title") {
                        TextField("", text: $episodeTitle)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 560)
                    }
                }
                .padding(.vertical, 6)
            }

            GroupBox("Metadata") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 18) {
                        LabeledContent("Season") {
                            TextField("", text: $season)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)
                        }

                        LabeledContent("Episode") {
                            TextField("", text: $episode)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)
                        }

                        LabeledContent("Year") {
                            TextField("", text: $year)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                        }

                        Spacer()
                    }

                    HStack(spacing: 18) {
                        LabeledContent("Genre") {
                            Picker("", selection: $genre) {
                                Text("").tag("")
                                ForEach(appleGenres, id: \.self) { g in
                                    Text(g).tag(g)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 260, alignment: .leading)
                        }

                        LabeledContent("Media Type") {
                            Picker("", selection: $mediaType) {
                                ForEach(mediaTypes, id: \.self) { m in
                                    Text(m).tag(m)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 220, alignment: .leading)
                        }

                        Spacer()
                    }
                }
                .padding(.vertical, 6)
            }

            GroupBox("Track") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        Text("Track Number")
                            .frame(width: 120, alignment: .leading)

                        TextField("", value: $titleNumber, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)

                        Stepper("", value: $titleNumber, in: 1...maxTitlesSafe)
                            .labelsHidden()

                        Spacer()
                    }

                    TrackGrid(
                        maxTitles: maxTitlesSafe,
                        used: usedTracks,
                        selected: titleNumber,
                        onSelect: { n in titleNumber = n }
                    )
                }
                .padding(.vertical, 6)
            }

            Toggle("Value Added Material (VAM)", isOn: $isVAM)

            HStack {
                Button("Cancel") { dismiss() }

                Spacer()

                Button("Save") {
                    guard validate() else { return }
                    save(updateExisting: titleToEdit != nil)
                    if errorMessage == nil { dismiss() }
                }
                .keyboardShortcut(.defaultAction)

                Button("Add New") {
                    guard validate() else { return }
                    save(updateExisting: titleToEdit != nil)
                    if errorMessage == nil { clearForNextEntry() }
                }
                .disabled(isDiskFull && titleToEdit == nil)
            }
        }
        .padding(28)
        .frame(minWidth: 980, minHeight: 620)
        .onAppear {
            if let existing = titleToEdit {
                showName = existing.show?.name ?? (existing.showName ?? "")
                episodeTitle = existing.episodeTitle ?? ""
                season = existing.seasonNumber ?? "01"
                episode = existing.episodeNumber ?? "01"
                year = existing.year ?? "2000"
                genre = existing.genre ?? ""
                mediaType = existing.mediaType ?? "TV Show"
                titleNumber = Int(existing.titleNumber)
                isVAM = existing.isVAM
            } else {
                if let ds = disk.show?.name, !ds.isEmpty {
                    showName = ds
                }
                titleNumber = nextAvailable(after: 0) ?? 1
            }

            if let ds = disk.show?.name, !ds.isEmpty {
                showName = ds
            }

            if let sy = disk.show?.startYear?.trimmingCharacters(in: .whitespacesAndNewlines),
               !sy.isEmpty,
               year == "2000" {
                year = sy
            }

            if let dg = disk.defaultGenre?.trimmingCharacters(in: .whitespacesAndNewlines),
               !dg.isEmpty,
               genre.isEmpty {
                genre = dg
            }
        }
    }

    // MARK: - Derived data

    private var showNames: [String] {
        shows.compactMap { $0.name }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted()
    }

    private var maxTitlesSafe: Int {
        max(1, Int(disk.maxTitles))
    }

    private var diskTitles: [Title] {
        let set = (disk.titles as? Set<Title>) ?? []
        return set.sorted { $0.titleNumber < $1.titleNumber }
    }

    private var usedTracks: Set<Int> {
        Set(diskTitles.map { Int($0.titleNumber) })
    }

    private var isDiskFull: Bool {
        usedTracks.count >= maxTitlesSafe
    }

    // MARK: - Validation

    private func validate() -> Bool {
        errorMessage = nil

        if titleNumber < 1 || titleNumber > maxTitlesSafe {
            errorMessage = "Track number must be between 1 and \(maxTitlesSafe)."
            return false
        }

        if !validateTrackUnique() { return false }

        let trimmedShow = showName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedShow.isEmpty {
            errorMessage = "Show Name cannot be empty."
            return false
        }

        return true
    }

    private func validateTrackUnique() -> Bool {
        let existing = diskTitles.first { Int($0.titleNumber) == titleNumber }

        if let existing, let editing = titleToEdit, existing.objectID == editing.objectID {
            return true
        }

        if existing != nil {
            errorMessage = "Track \(titleNumber) is already used on this disk."
            return false
        }

        return true
    }

    // MARK: - Save

    private func save(updateExisting: Bool) {
        errorMessage = nil

        let ctx = context
        guard let diskInContext = try? ctx.existingObject(with: disk.objectID) as? Disk else {
            errorMessage = "Internal error: could not resolve disk in current context."
            return
        }

        let t: Title
        if updateExisting, let existing = titleToEdit {
            if existing.managedObjectContext === ctx {
                t = existing
            } else if let resolved = try? ctx.existingObject(with: existing.objectID) as? Title {
                t = resolved
            } else {
                errorMessage = "Internal error: could not resolve title to edit."
                return
            }
        } else {
            t = Title(context: ctx)
            t.id = UUID()
        }

        t.disk = diskInContext

        let trimmedShow = showName.trimmingCharacters(in: .whitespacesAndNewlines)
        t.showName = trimmedShow

        if !trimmedShow.isEmpty {
            let req = NSFetchRequest<Show>(entityName: "Show")
            req.fetchLimit = 1
            req.predicate = NSPredicate(format: "name =[c] %@", trimmedShow)

            if let s = (try? ctx.fetch(req))?.first {
                t.show = s
            } else {
                let s = Show(context: ctx)
                s.id = UUID()
                s.name = trimmedShow
                s.startYear = ""
                t.show = s
            }
        } else {
            t.show = nil
        }

        t.episodeTitle = episodeTitle
        t.seasonNumber = season
        t.episodeNumber = episode
        t.year = year
        t.genre = genre
        t.mediaType = mediaType
        t.titleNumber = Int16(titleNumber)
        t.isVAM = isVAM

        for case let obj as Title in ctx.insertedObjects where obj.disk == nil {
            ctx.delete(obj)
        }

        do {
            try ctx.save()
        } catch {
            ctx.rollback()
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    private func clearForNextEntry() {
        episodeTitle = ""
        isVAM = false
        titleNumber = nextAvailable(after: titleNumber) ?? titleNumber
    }

    private func nextAvailable(after current: Int) -> Int? {
        let used = usedTracks
        if used.count >= maxTitlesSafe { return nil }

        if current < maxTitlesSafe {
            for n in (current + 1)...maxTitlesSafe where !used.contains(n) { return n }
        }

        for n in 1...maxTitlesSafe where !used.contains(n) { return n }
        return nil
    }
}

// MARK: - Track grid

private struct TrackGrid: View {
    let maxTitles: Int
    let used: Set<Int>
    let selected: Int
    let onSelect: (Int) -> Void

    private let columns = Array(repeating: GridItem(.fixed(44), spacing: 10), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(1...maxTitles, id: \.self) { n in
                Button { onSelect(n) } label: {
                    Text("\(n)")
                        .frame(width: 44, height: 34)
                }
                .buttonStyle(.borderedProminent)
                .tint(tint(for: n))
                .disabled(used.contains(n) && n != selected)
            }
        }
        .padding(.top, 2)
    }

    private func tint(for n: Int) -> Color {
        if n == selected { return .blue }
        if used.contains(n) { return Color.gray.opacity(0.55) }
        return Color.gray.opacity(0.20)
    }
}
