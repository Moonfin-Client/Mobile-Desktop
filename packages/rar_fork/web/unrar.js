var fs = require("fs"),
    path = require("path"),
    RarEventMgr = require("./lib/RarEventMgr"),
    child_process = require("child_process");

function _registerEvents(i_oEvents) {
    RarEventMgr.on(RarEventMgr.TYPES.START, function() {
        if (i_oEvents.onStart) {
            i_oEvents.onStart();
        }
    });

    RarEventMgr.on(RarEventMgr.TYPES.PROGRESS, function(i_oProgressData) {
        if (i_oEvents.onProgress) {
            i_oEvents.onProgress(i_oProgressData);
        }
    });

    RarEventMgr.on(RarEventMgr.TYPES.EXTRACT, function(i_oFile) {
        if (i_oEvents.onExtract) {
            i_oEvents.onExtract(i_oFile);
        }
    });

    RarEventMgr.on(RarEventMgr.TYPES.FINISH, function(i_aFiles) {
        if (i_oEvents.onFinish) {
            i_oEvents.onFinish(i_aFiles);
        }
    });

    RarEventMgr.on(RarEventMgr.TYPES.INFO, function(i_sStr) {
        if (i_oEvents.onInfo) {
            i_oEvents.onInfo(i_sStr);
        }
    });

    RarEventMgr.on(RarEventMgr.TYPES.ERROR, function(i_sStr) {
        if (i_oEvents.onError) {
            i_oEvents.onError(i_sStr);
        }
    });
}

//==============================================================================
function storeFilesToDiskSync(i_aFiles, i_sOutputdir) {
    var l_aWrittenFiles;

    mkdirp.sync(i_sOutputdir);

    l_aWrittenFiles = i_aFiles.map(function(i_oFile) {
        storeFileToDiskSync(i_oFile, i_sOutputdir);
        return path.join(i_sOutputdir, i_oFile.filename);
    });

    return l_aWrittenFiles;
}

//==============================================================================
function storeFileToDiskSync(i_oFile) {
    var l_sDirname = path.dirname(i_oFile.filename),
        l_sFilename,
        l_oStats,
        l_oBuffer;

    console.log("File name: ", i_oFile.filename, " size: ", i_oFile.header.unpackedSize);
    console.log("Saving content of file ");

    l_sDirname = path.dirname(i_oFile.filename);
    l_sFilename = path.join(__dirname, path.basename(i_oFile.filename));
    l_oBuffer = new Buffer(i_oFile.fileData); // filedata is Uint8Array

    fs.writeFileSync(l_sFilename, l_oBuffer);
}

module.exports = {
    // file, [, outputdir [, options]]
    // if no output dir -> returns list of files
    // if outputdir -> returns list of filenames
    //==============================================================================
    unrarSync: function() {
        var unrar = require("./lib/Unrar"),
            l_sFile = arguments[0],
            l_sOutputDir,
            l_aUnrarredFiles,
            l_oBuffer,
            l_oOptions;

        // check if output dir specified
        if (typeof(arguments[1]) === "string") {
            l_sOutputDir = arguments[1];
            l_oOptions = arguments[2] || {};
        } else {
            l_oOptions = arguments[1] || {};
        }

        _registerEvents(l_oOptions);
        l_oBuffer = fs.readFileSync(l_sFile);
        l_aUnrarredFiles = unrar(l_oBuffer);

        if (l_sOutputDir) {
            l_aUnrarredFiles = storeFilesToDiskSync(l_aUnrarredFiles, l_sOutputDir);
        }

        return l_aUnrarredFiles;
    },

    // file, , outputdir[, options]], callback
    // if no output dir -> returns list of files
    // if outputdir -> returns list of filenames
    //==============================================================================
    unrar: function() {
        var l_sFile = arguments[0],
            l_sOutputDir = arguments[1],
            l_oOptions,
            l_oCallback,
            l_aUnrarredFiles = [],
            l_sError;

        // 0 -> file
        // 1 -> outputdir
        // 2 -> options OR callback
        // 3 -> Callback

        if (typeof(arguments[2]) === "function") {
            l_oOptions = {};
            l_oCallback = arguments[2];
        } else {
            l_oOptions = arguments[2] || {};
            l_oCallback = arguments[3];
        }

        if (!l_sFile || typeof(l_sFile) !== "string") {
            throw ("Unrar::Error, missing file argument.");
        }

        if (!l_sOutputDir || typeof(l_sOutputDir) !== "string") {
            throw ("Unrar::Error, missing output directory argument.");
        }

        if (!l_oCallback) {
            throw ("Unrar::Error, missing callback argument.");
        }

        childProcess = child_process.fork(path.join(__dirname, "js/UnrarSubprocess.js"), [l_sFile, l_sOutputDir]);

        childProcess.on('message', (m) => {
            if (m.event === "progress") {
                if (l_oOptions.onProgress) {
                    l_oOptions.onProgress(m.data);
                }
            } else if (m.event === "finish") {
                l_aUnrarredFiles = m.data;
                childProcess.kill();
            } else if (m.event === "error") {
                l_sError = m.data;
                childProcess.kill("SIGKILL");
            } else if (m.event === "abort") {
                l_sError = m.data;
                childProcess.kill("SIGKILL");
            }

        });

        childProcess.on('close', function() {
            l_oCallback(l_sError, l_aUnrarredFiles);
        });
    }
};
