function [audio, weighting, fileInfo, startSample, endSample] = downsampleAudioFromFiles(fileInfo,startTime,endTime,varargin)
% audio = getAudioFromFiles(fileInfo,startTime,endTime,exclusions)
% audio contains the audio data as a column vector
% weighting is the ratio of available audio to requested audio
% fileInfo contains metadata from the function wavFolderInfo
% startTime and endTime are matlab datenum,
% exclusions are an Nx2 vector of datenums. audio between (n,1) and (n,2)
% will be excluded.
% This function is part of the soundFolder package.
% See also: audioread, wavread, wavFolderInfo
if nargin < 4 || isempty(exclusions)
    exclusions = zeros(0,2);
end
% Default return values: TODO assign fileName
audio = [];
weighting = 0;
startSample = [];
endSample = [];
fileIndex = [];

fileInfo = findFilesInTimespan(fileInfo,startTime,endTime);
if isempty(fileInfo)
    return
end

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

requestedDuration = (endTime - startTime)*86400;
actualDuration = size(audio,1)/fileInfo(1).sampleRate;
weighting = actualDuration/requestedDuration;

function fileInfo = findFilesInTimespan(fileInfo,startTime,endTime)
    % Given some file metadata and a time of interest, return only the 
    % metadata that corresponds to the time of interest


    % Create an index of files that contain the timespan of interest
%     [~, firstFile] = histc(startTime,[fileInfo.startDate]');
%     [~, lastFile] =  histc(endTime,  [fileInfo.endDate]');
    firstFile = find(startTime > [fileInfo.startDate],1,'last');
    lastFile = find(endTime < [fileInfo.endDate],1,'first');
    
    % Corner case: start time is outside of any file times
    if isempty(firstFile) & ~isempty(lastFile)
    % This is a workaround and won't cover all cases
        firstFile = lastFile; 
    end 
    
    fileRequired = firstFile:lastFile;

    % The code below works reliably, but is slower than it needs to be
%     [fileName, fileStartTime, fileEndTime] = getFileNamesAndTimes(fileInfo);
%     fileRequired = zeros(1,length(fileName));
%     for i = 1:length(fileName);
%         fileRequired(i) = doTimespansOverlap(startTime,endTime,fileStartTime(i),fileEndTime(i));
%     end
%     fileRequired = find(fileRequired);% Convert from logical to integer indicies
    fileInfo = fileInfo(fileRequired);

function [fileNames, fileStartTimes, fileEndTimes] = getFileNamesAndTimes(fileInfo)
    fileNames = {fileInfo.fname};
    fileEndTimes = [fileInfo.endDate];
    [fileStartTimes sortIx] = sort([fileInfo.startDate]);
    fileNames = fileNames(sortIx);
    fileEndTimes = fileEndTimes(sortIx);

function [startSample endSample index] = getStartAndEndSamples(fileInfo, startTime, endTime)
    startSample = [];
    endSample = [];
    index = [];
    for i = 1:length(fileInfo);
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
    if startOffset * fileInfo.sampleRate <= 1;
        startSample = 1;
    else
        startSample =  floor(startOffset .* fileInfo.sampleRate);
    end

function endSample = getEndSample(fileInfo,endTime)
    endOffset = (fileInfo.endDate - endTime)*86400;
    if endOffset <= 0;
        endSample = fileInfo.numberOfSamples;
    else
        endSample = fileInfo.numberOfSamples - floor(endOffset .* fileInfo.sampleRate);
    end

function [includeStart, includeEnd] = getInclusionTimes(startTime,endTime,exclusions)
    numExclusions = size(exclusions,1);
    ix = zeros(1,numExclusions);
    for i = 1:numExclusions;
        ix(i) = doTimespansOverlap(startTime,endTime,exclusions(i,1),exclusions(i,2));
    end

    exclusions = exclusions(logical(ix),:);
%     basicTimeline([startTime endTime; exclusions])
   
    includeStart = [startTime; exclusions(:,2)];
    includeEnd = [exclusions(:,1); endTime];


    
    
