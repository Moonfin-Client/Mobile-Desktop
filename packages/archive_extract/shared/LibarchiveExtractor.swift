import Foundation

class LibarchiveExtractor {
    static func extract7z(archivePath: String, destinationPath: String) throws -> [String] {
        var filesPtr: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
        var fileCount: Int32 = 0
        var errorPtr: UnsafeMutablePointer<CChar>?

        let rc = extract_7z_archive(
            archivePath,
            destinationPath,
            &filesPtr,
            &fileCount,
            &errorPtr
        )

        if rc != 0 {
            let message: String
            if let errorPtr = errorPtr {
                message = String(cString: errorPtr)
                free(errorPtr)
            } else {
                message = "Unknown extraction error"
            }
            throw NSError(domain: "ArchiveExtract", code: Int(rc),
                          userInfo: [NSLocalizedDescriptionKey: message])
        }

        var files: [String] = []
        if let filesPtr = filesPtr {
            for i in 0..<Int(fileCount) {
                if let cStr = filesPtr[i] {
                    files.append(String(cString: cStr))
                }
            }
            free_extracted_files(filesPtr, fileCount)
        }

        return files
    }
}
