//
//  Backup.swift
//  Ascent ADHD
//
//  A JSON document type for exporting/importing the whole store via the system file picker,
//  plus a Settings section that drives it. Replaces the Android Storage-Access-Framework flow.
//

import SwiftUI
import UniformTypeIdentifiers

// A plain-JSON document used with .fileExporter / .fileImporter.
struct JSONBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var text: String

    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(data: data, encoding: .utf8) ?? ""
        } else { text = "" }
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

// Reusable Settings section: Export + Restore.
struct BackupSection: View {
    @EnvironmentObject var store: AppStore
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportDoc = JSONBackupDocument(text: "{}")
    @State private var resultMessage: String? = nil

    private var backupFilename: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return "ascent-backup-\(f.string(from: Date()))"
    }

    var body: some View {
        Section {
            Button {
                exportDoc = JSONBackupDocument(text: store.exportJSON())
                showExporter = true
            } label: {
                Label("Export a backup", systemImage: "square.and.arrow.up")
            }
            Button {
                showImporter = true
            } label: {
                Label("Restore from a backup", systemImage: "square.and.arrow.down")
            }
            if let msg = resultMessage {
                Text(msg).font(AscentFont.labelSmall).foregroundColor(TextMuted)
            }
        } header: {
            Text("Backup & restore")
        } footer: {
            Text("A backup captures everything: schedule, lists, goals, reflections, rewards, and progress. Restoring replaces all current data.")
        }
        .fileExporter(isPresented: $showExporter, document: exportDoc,
                      contentType: .json, defaultFilename: backupFilename) { result in
            switch result {
            case .success: resultMessage = "Backup saved."
            case .failure: resultMessage = "Couldn't save the backup."
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
                if let text = try? String(contentsOf: url, encoding: .utf8), store.importJSON(text) {
                    resultMessage = "Backup restored."
                } else {
                    resultMessage = "Couldn't read that file."
                }
            case .failure:
                resultMessage = "Couldn't open that file."
            }
        }
    }
}
