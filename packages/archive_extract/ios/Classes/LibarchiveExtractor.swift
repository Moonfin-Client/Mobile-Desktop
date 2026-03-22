import Foundation
import LzmaSDK_ObjC

class LibarchiveExtractor {
    static func extract7z(archivePath: String, destinationPath: String) throws -> [String] {
        let reader = LzmaSDKObjCReader(fileURL: URL(fileURLWithPath: archivePath))
        try reader.open()

        var selectedItems: [LzmaSDKObjCItem] = []
        var extractedRelativePaths: [String] = []
        var iterationError: Error?

        let listed = reader.iterate { item, error in
            if let error = error {
                iterationError = error
                return false
            }
            if !item.isDirectory, let relativePath = sanitizedRelativePath(for: item) {
                selectedItems.append(item)
                extractedRelativePaths.append(relativePath)
            }
            return true
        }

        guard listed else {
            throw iterationError ?? reader.lastError ?? NSError(
                domain: "ArchiveExtract",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to enumerate archive items."]
            )
        }

        if !selectedItems.isEmpty {
            let extracted = reader.extract(selectedItems, toPath: destinationPath, withFullPaths: true)
            guard extracted else {
                throw reader.lastError ?? NSError(
                    domain: "ArchiveExtract",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to extract archive items."]
                )
            }
        }

        return extractedRelativePaths.map {
            (destinationPath as NSString).appendingPathComponent($0)
        }
    }

    private static func sanitizedRelativePath(for item: LzmaSDKObjCItem) -> String? {
        guard let fileName = item.fileName, !fileName.isEmpty else {
            return nil
        }

        let directory = (item.directoryPath ?? "").replacingOccurrences(of: "\\", with: "/")
        var components = directory
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
        components.append(fileName)

        for component in components {
            if component == "." || component == ".." || component.contains("/") || component.contains("\\") {
                return nil
            }
        }

        return components.joined(separator: "/")
    }
}
