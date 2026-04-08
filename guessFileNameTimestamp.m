function [timestamp, form, allTimestamps, allForms] = guessFileNameTimestamp(fileName)
% Guess the timestamp format embedded in a WAV filename.
%
% INPUTS
%   fileName   WAV filename, full path, or folder path. If a folder, the
%              first WAV file found is used.
%
% OUTPUTS
%   timestamp      Best-guess datenum (scalar), or [] if no match found.
%   form           Best-guess format string (char), or {} if no match.
%   allTimestamps  All matching datenums (vector), sorted most-specific first.
%   allForms       All matching format strings (cell), sorted most-specific first.
%
% When multiple formats match with different timestamps, results are sorted
% by format string length descending — longer formats are more specific and
% less likely to match a substring of a wider pattern (e.g. yyyymmdd_HHMMSS
% is preferred over yymmdd_HHMMSS).
%
% When multiple formats yield the same timestamp, only the most specific
% (longest) is returned as the best guess.
%
% Add new formats to the forms list below.
%
% See also: filenameToTimeStamp, wavFolderInfo

forms = {
    'yymmdd_HHMMSS';       % DCLDE 2015        e.g. CINMS18B_d06_120622_055731.d100.x.wav
    'yyyymmdd_HHMMSS';     % SORP Annot. Lib.  e.g. 20150115_170000.wav
    'yyyy-mm-dd_HH-MM-SS'; % AAD MAR           e.g. 200_2013-12-25_06-00-00.wav
    'yyyymmdd-HHMMSS';     %                   e.g. 20150102-140944.wav
    'yymmddHHMMSS';        % SoundTrap         e.g. 7387.230316070749.wav
    'yyyymmddTHHMMSS';     % Jasco AMAR G4     e.g. AMAR897.20210722T084721Z.wav
    };

% If a folder, use the first WAV file found
if isfolder(fileName) && exist(fileName, 'dir') == 7
    d = dir(fullfile(fileName, '*.wav'));
    if isempty(d)
        timestamp = []; form = {}; allTimestamps = []; allForms = {};
        return;
    end
    fileName = d(1).name;
end

% Try each format
allTimestamps = [];
allForms      = {};
for i = 1:numel(forms)
    try
        ts = filenameToTimeStamp(fileName, forms{i});
        allTimestamps(end+1) = ts;      %#ok<AGROW>
        allForms{end+1}      = forms{i}; %#ok<AGROW>
    catch
    end
end

if isempty(allTimestamps)
    timestamp = []; form = {};
    return;
end

% Sort by format length descending — longer = more specific
[~, ix] = sort(cellfun(@length, allForms), 'descend');
allTimestamps = allTimestamps(ix);
allForms      = allForms(ix);

% Deduplicate: if multiple formats give the same timestamp, keep only the
% most specific (first after sorting)
[~, keep] = unique(allTimestamps, 'stable');
allTimestamps = allTimestamps(keep);
allForms      = allForms(keep);

% Best guess is the first (most specific)
timestamp = allTimestamps(1);
form      = allForms{1};
