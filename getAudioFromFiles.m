function [audio, weighting, fileInfo, startSample, endSample] = getAudioFromFiles(fileInfo,startTime,endTime,exclusions,channel,newRate)
% [audio, weighting, fileInfo, startSample, endSample] = getAudioFromFiles(fileInfo,startTime,endTime,exclusions,channel,newRate)
%
% Reads audio data from a set of files spanning a requested time range,
% with optional single-channel extraction and resampling.
%
% INPUTS (required):
%   fileInfo   - metadata struct from wavFolderInfo
%   startTime  - start of requested audio (MATLAB datenum)
%   endTime    - end of requested audio (MATLAB datenum)
%
% INPUTS (optional):
%   exclusions - Nx2 array of datenums; audio between exclusions(n,1) and
%                exclusions(n,2) will be excluded. Default: none.
%   channel    - channel index to extract (1-indexed integer). 
%                Default: [] (return all channels).
%   newRate    - target sample rate in Hz for resampling.
%                Default: [] (no resampling; return at original sample rate).
%
% OUTPUTS:
%   audio       - audio data matrix (samples x channels), or column vector
%                 if a single channel is selected
%   weighting   - ratio of available audio to requested audio duration
%   fileInfo    - updated fileInfo struct (sample rate updated if resampled)
%   startSample - sample indices used for reading (per file segment)
%   endSample   - sample indices used for reading (per file segment)
%
% This function is part of the soundFolder package.
% See also: audioread, wavFolderInfo, resample

if nargin < 4 || isempty(exclusions)
    exclusions = zeros(0,2);
end
if nargin < 5 || isempty(channel)
    channel = [];       % default: return all channels
end
if nargin < 6 || isempty(newRate)
    newRate = [];       % default: no resampling
end

% Default return values: TODO assign fileName
audio = [];
weighting = 0;
startSample = [];
endSample = [];
fileIndex = [];

% --- Find files that overlap the requested time span ---
fileInfo = findFilesInTimespan(fileInfo,startTime,endTime);
if isempty(fileInfo)
    return
end

% --- Compute inclusion windows (accounting for exclusions) ---
[includeStartTime, includeEndTime] = getInclusionTimes(startTime, endTime, exclusions);
for i = 1:length(includeStartTime)
    [ss, es, ix] = getStartAndEndSamples(fileInfo, includeStartTime(i), includeEndTime(i));
    startSample = [startSample ss];
    endSample = [endSample es];
    fileIndex = [fileIndex ix];
end

maxChannels = max([fileInfo.numberOfChannels]);

% This bit works for wav files. Different code required for ARP-BIN files
% or CMST logger data.
for i = 1:length(fileIndex)
    f = fileInfo(fileIndex(i)).fname;
    wav = audioread(f,[startSample(i) endSample(i)]);
    missingChannels = maxChannels - size(wav,2);
    wav = [wav zeros(size(wav,1),missingChannels)];
    audio = [audio; wav];
end

% --- Compute weighting (ratio of retrieved to requested duration) ---
requestedDuration = (endTime - startTime)*86400;
actualDuration = size(audio,1)/fileInfo(1).sampleRate;
weighting = actualDuration/requestedDuration;

if isempty(audio)
    return
end

% --- Optional: extract single channel ---
if ~isempty(channel)
    audio = audio(:, channel);
end

% --- Optional: resample ---
if ~isempty(newRate) && newRate ~= fileInfo(1).sampleRate
    q     = fileInfo(1).sampleRate / newRate;
    audio = resample(audio, 1, q);
    for i = 1:length(fileInfo)
        fileInfo(i).sampleRate = newRate;
    end
end

% =========================================================================
% Local functions
% =========================================================================

function fileInfo = findFilesInTimespan(fileInfo,startTime,endTime)
    % Given some file metadata and a time of interest, return only the 
    % metadata that corresponds to the time of interest

    firstFile = find(startTime >= [fileInfo.startDate],1,'last');
    lastFile = find(endTime <= [fileInfo.endDate],1,'first');
    
    % Corner case: start time is outside of any file times
    if isempty(firstFile) && ~isempty(lastFile)
    % This is a workaround and won't cover all cases
        firstFile = lastFile; 
    end 
    
    % Corner case: endTime is after all file end times
    if ~isempty(firstFile) && isempty(lastFile)
        lastFile = firstFile;
    end

    fileRequired = firstFile:lastFile;
    fileInfo = fileInfo(fileRequired);

function [fileNames, fileStartTimes, fileEndTimes] = getFileNamesAndTimes(fileInfo)
    fileNames = {fileInfo.fname};
    fileEndTimes = [fileInfo.endDate];
    [fileStartTimes, sortIx] = sort([fileInfo.startDate]);
    fileNames = fileNames(sortIx);
    fileEndTimes = fileEndTimes(sortIx);

function [startSample, endSample, index] = getStartAndEndSamples(fileInfo, startTime, endTime)
    startSample = [];
    endSample = [];
    index = [];
    for i = 1:length(fileInfo)
        startSample(i) = getStartSample(fileInfo(i), startTime);
        endSample(i) = getEndSample(fileInfo(i), endTime);
        index(i) =  i;
    end

    % Special case when the start or end of the file is excluded
    remove = find(startSample > endSample);
    startSample(remove) = [];
    endSample(remove) = [];
    index(remove) = [];
    
function startSample = getStartSample(fileInfo, startTime) 
    startOffset = (startTime - fileInfo.startDate)*86400; % Duration in seconds
    if startOffset * fileInfo.sampleRate <= 1
        startSample = 1;
    else
        startSample =  floor(startOffset .* fileInfo.sampleRate);
    end

function endSample = getEndSample(fileInfo,endTime)
    endOffset = (fileInfo.endDate - endTime)*86400;
    if endOffset <= 0
        endSample = fileInfo.numberOfSamples;
    else
        endSample = fileInfo.numberOfSamples - floor(endOffset .* fileInfo.sampleRate);
    end

function [includeStart, includeEnd] = getInclusionTimes(startTime,endTime,exclusions)
    numExclusions = size(exclusions,1);
    ix = zeros(1,numExclusions);
    for i = 1:numExclusions
        ix(i) = doTimespansOverlap(startTime,endTime,exclusions(i,1),exclusions(i,2));
    end

    exclusions = exclusions(logical(ix),:);
%     basicTimeline([startTime endTime; exclusions])
   
    includeStart = [startTime; exclusions(:,2)];
    includeEnd = [exclusions(:,1); endTime];


    
    
