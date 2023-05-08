function metadata = readWavHeader(fileName,timeStampFormat)
% function header = readWavHeader(fileName,timeStampFormat) This function
% returns metadata from a wav audio file. It makes use of the matlab
% function audioread (formerly wavread) to get the sampleRate, number of
% channels, number of samples, and bit-depth. This function also scans the
% wav filename for a timestamp to determine the starting date and time of
% the file as is common in programs such as PAMGuard, Ishmael, Raven, etc.
% FILENAME - The full path and filename to the wav file
% TIMESTAMPFORMAT - A string compatible with Matlab DATESTR FORMATOUT, 
% for example, 'yyyy-mm-dd_HH-MM-SS'
% This function is part of the soundFolder package.
% See also: wavFolderInfo, audioread, readTimeStamp
if nargin < 2
    % Default timestamp format for PAMGUard
    timeStampFormat = 'yyyymmdd_HHMMSS';

    % Default timestamp format for AAD moored acoustic recorder
    timeStampFormat = 'yyyy-mm-dd_HH-MM-SS';
end

% warning('MATLAB:audiovideo:wavread:functionToBeRemoved','off')
% [wavSize, sampleRate, bits, opts] = wavread(fileName,'size');
%% Metadata from wav header
info = audioinfo(fileName);
wavSize = [info.TotalSamples info.NumChannels];
sampleRate = info.SampleRate;
bits = info.BitsPerSample;

metadata.numberOfChannels = wavSize(2);         % Number of Channels
metadata.bitsPerSample = bits;      % Bits per Sample 
metadata.sampleRate = sampleRate;   % sample rate of this RawFile
metadata.gain = 1;                  % gain (1 = no change)
metadata.fname = fileName;          % wav file name
metadata.numberOfSamples = wavSize(1);

%% Metadata from filename
metadata.startDate = filenameToTimeStamp(fileName,timeStampFormat);
metadata.duration = metadata.numberOfSamples ./ metadata.sampleRate; % In seconds
metadata.endDate = metadata.startDate + metadata.duration/86400; % Matlab datenum

  