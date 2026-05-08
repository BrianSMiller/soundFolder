function [drift, driftPpm] = recorderClockDrift(fileInfo)
% recorderClockDrift  Detect clock drift in a long-term acoustic recorder.
%
% Compares the nominal duration of each wav file (numberOfSamples /
% sampleRate) against the duration implied by the file timestamps
% (endDate - startDate). A discrepancy indicates that the recorder clock
% ran at a slightly different rate than the nominal sample rate.
%
% Clock drift is a common problem in long-term recorders. A drift of even
% a few ppm accumulates to seconds or minutes over a year-long deployment,
% which can cause:
%   - Timing errors in detection timestamps
%   - Misalignment when cross-referencing with other time series
%   - Errors in localisation algorithms that assume accurate timing
%   - Apparent gaps or overlaps between files in wavFolderInfo
%
% Usage:
%   [drift, driftPpm] = recorderClockDrift(fileInfo)
%
% Input:
%   fileInfo    Struct array from wavFolderInfo. Each element must have
%               fields: numberOfSamples, sampleRate, startDate, endDate.
%
% Outputs:
%   drift       1 x nFiles vector of clock drift in seconds per file.
%               Positive = recorder clock ran fast (more samples than
%               expected for the timestamp interval).
%               Negative = recorder clock ran slow.
%   driftPpm    1 x nFiles vector of drift in parts per million (ppm).
%               Typical crystal oscillator drift is 1-100 ppm.
%               Values > 500 ppm likely indicate a timestamp error rather
%               than genuine clock drift.
%
% Example:
%   fileInfo = wavFolderInfo('S:\work\250Hz\Kerguelen2014\');
%   [drift, driftPpm] = recorderClockDrift(fileInfo);
%   figure;
%   plot([fileInfo.startDate], cumsum(drift));
%   datetick('x', 'mmm'); ylabel('Cumulative drift (s)');
%   title('Recorder clock drift — Kerguelen 2014');
%
% See also: wavFolderInfo, readWavHeader

arguments
    fileInfo (1,:) struct
end

% Duration implied by sample count and nominal sample rate
nominalDuration   = [fileInfo.numberOfSamples] ./ [fileInfo.sampleRate];

% Duration implied by file timestamps
timestampDuration = ([fileInfo.endDate] - [fileInfo.startDate]) * 86400;

% Drift: positive means clock ran fast (extra samples relative to timestamp)
drift    = nominalDuration - timestampDuration;

% Parts per million
driftPpm = (drift ./ nominalDuration) * 1e6;
