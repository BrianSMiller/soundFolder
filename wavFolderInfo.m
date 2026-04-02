function fileInfo = wavFolderInfo(folder, timeStampFormat, refreshCache, suppressProgress, parallelThreshold)
% fileInfo = wavFolderInfo(folder, timeStampFormat)
%
% Build a soundFolder metadata struct from a folder of timestamped WAV files.
% The filename of each WAV file must contain a timestamp indicating its start
% time. wavFolderInfo is a core function of the soundFolder package.
%
% Results are cached to disk and in a persistent variable. Call with
% refreshCache=true to force a rebuild after adding or removing files.
%
% INPUTS
%   folder           Path to folder of WAV files
%   timeStampFormat  datestr-compatible format string, e.g. 'yyyy-mm-dd_HH-MM-SS'
%                    If omitted, guessFileNameTimestamp() is called on the first
%                    file to detect the format automatically. A warning is issued
%                    if the format is ambiguous; an error is thrown if no known
%                    format matches.
%   refreshCache     Force cache rebuild. Default: false.
%   suppressProgress Suppress per-file progress messages. Default: false.
%   parallelThreshold Use parfor above this many files. Default: 200.
%
% OUTPUT
%   fileInfo   Struct array with fields: fname, startDate, duration, sampleRate
%
% EXAMPLES
%   % Auto-detect timestamp format
%   sf = wavFolderInfo('D:\recordings\casey2019\wav\');
%
%   % Specify format explicitly (faster, unambiguous)
%   sf = wavFolderInfo('D:\recordings\casey2019\wav\', 'yyyy-mm-dd_HH-MM-SS');
%
%   % Force cache rebuild after adding files
%   sf = wavFolderInfo('D:\recordings\casey2019\wav\', [], true);
%
% See also: getAudioFromFiles, guessFileNameTimestamp, filenameToTimeStamp

if nargin < 5, parallelThreshold = 200; end
if nargin < 4, suppressProgress  = false; end
if nargin < 3, refreshCache      = false; end
if nargin < 2, timeStampFormat   = ''; end

customTimeStamp = ~isempty(timeStampFormat);

%% Cache setup
persistent lastFileInfo lastFolder

cacheFolder = getSoundCacheFolder;
if ~exist(cacheFolder, 'dir')
    [ok, msg] = mkdir(cacheFolder);
    if ~ok
        error('wavFolderInfo:cacheError', ...
            'Cannot create cache folder:\n  %s\n%s', cacheFolder, msg);
    end
end

% No arguments — list known folders in cache
if nargin == 0
    fprintf('Cache stored at %s:\n', cacheFolder);
    d = dir(fullfile(cacheFolder, '*.mat'));
    for k = 1:numel(d)
        fprintf('  %s\n', urldecode(d(k).name(1:end-4)));
    end
    return
end

%% Normalise path
if folder(end) ~= filesep
    folder(end+1) = filesep;
end

cacheFile = fullfile(cacheFolder, [urlencode(folder) '.mat']);

%% Return from cache if available and not stale
if ~refreshCache
    if strcmpi(folder, lastFolder) && ~isempty(lastFileInfo)
        fileInfo = lastFileInfo;
        return
    end
    if exist(cacheFile, 'file') == 2
        load(cacheFile, 'fileInfo');
        if ~isempty(fileInfo)
            lastFolder   = folder;
            lastFileInfo = fileInfo;
            return
        end
        % Cache exists but empty — fall through to rebuild
        warning('wavFolderInfo:emptyCache', ...
            'Cache for this folder is empty — rebuilding.\n  %s', folder);
    end
end

%% Find WAV files
fileNames = recurseDir(folder, '*.wav');

if isempty(fileNames)
    error('wavFolderInfo:noFiles', ...
        'No WAV files found in folder:\n  %s\nCheck the path and that WAV files exist.', folder);
end

%% Auto-detect timestamp format if not supplied
if ~customTimeStamp
    firstFile = fileNames(1).name;
    [~, fname] = fileparts(firstFile);
    [ts, detectedForms] = guessFileNameTimestamp(firstFile);

    if isempty(ts) || isempty(detectedForms)
        error('wavFolderInfo:unknownFormat', ...
            ['Could not determine timestamp format from filename:\n' ...
             '  %s\n' ...
             'Specify the format explicitly, e.g.:\n' ...
             '  wavFolderInfo(folder, ''yyyy-mm-dd_HH-MM-SS'')'], fname);
    end

    if iscell(detectedForms)
        % Multiple formats matched — warn and use first
        warning('wavFolderInfo:ambiguousFormat', ...
            ['Ambiguous timestamp format for:\n' ...
             '  %s\n' ...
             'Matched formats: %s\n' ...
             'Using ''%s''. Specify format explicitly to suppress this warning.'], ...
            fname, strjoin(detectedForms, ', '), detectedForms{1});
        timeStampFormat = detectedForms{1};
    else
        timeStampFormat = detectedForms;
        fprintf('wavFolderInfo: detected timestamp format ''%s'' from %s\n', ...
            timeStampFormat, fname);
    end
    customTimeStamp = true;
end

%% Read WAV headers
fprintf('Reading audio metadata for %d file(s) in:\n  %s\n', ...
    numel(fileNames), folder);

if numel(fileNames) > parallelThreshold
    parfor i = 1:numel(fileNames)
        fileInfo(i) = readWavHeader(fileNames(i).name, timeStampFormat); %#ok<PFBNS>
        if ~suppressProgress
            fprintf('  %d/%d: %s\n', i, numel(fileNames), fileNames(i).name);
        end
    end
else
    for i = 1:numel(fileNames)
        fileInfo(i) = readWavHeader(fileNames(i).name, timeStampFormat);
        if ~suppressProgress
            fprintf('  %d/%d: %s\n', i, numel(fileNames), fileNames(i).name);
        end
    end
end

%% Validate timestamps — catch files where format produced epoch (year 0)
epoch = datenum([0 1 1 0 0 0]);
badIdx = abs([fileInfo.startDate] - epoch) < 1;
if any(badIdx)
    badFiles = {fileNames(badIdx).name};
    warning('wavFolderInfo:badTimestamp', ...
        ['%d file(s) have timestamps at epoch (year 0) — format may be wrong:\n' ...
         '  First bad file: %s\n' ...
         '  Detected format: ''%s''\n' ...
         'Call wavFolderInfo(folder, ''your-format'', true) to rebuild with correct format.'], ...
        sum(badIdx), badFiles{1}, timeStampFormat);
end

%% Sort by start date and cache
[~, ix] = sort([fileInfo.startDate]);
fileInfo = fileInfo(ix);

save(cacheFile, 'fileInfo');
lastFolder   = folder;
lastFileInfo = fileInfo;
