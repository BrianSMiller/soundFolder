function [timestamp, form] = guessFileNameTimestamp(fileName)
% Convenience function to help identify the format of the timestamp
% embedded in wav files. Feel free to add new formats to the list of forms
% below. 
% fileName is the name of a wav file, or a folder of wav files. Timestamp
% is a datenum 
fnames = {'CINMS18B_d06_120622_055731.d100.x.wav'; % DCLDE 2015
        '20150115_170000.wav';                     % Annotated Library
        '200_2013-12-25_06-00-00.wav';             % AAD MAR
        '20150102-140944.wav';                     % 
        '7387.230316070749.wav';                   % SoundTrap
        'AMAR897.20210722T084721Z.wav';};          % Jasco AMAR G4 
forms = {'yymmdd_HHMMSS';   % DCLDE 2015
    'yyyymmdd_HHMMSS';      % SORP Annotated Library
    'yyyy-mm-dd_HH-MM-SS';  % AAD MAR
    'yyyymmdd-HHMMSS';
    'yymmddHHMMSS';          % SoundTrap
    'yyyymmddTHHMMSS';       % Jasco AMAR G4 
    };

% If a folder, just look at the first wav file
if exist(fileName,"dir")
    fileName = dir([fileName '*.wav']);
    fileName = fileName(1).name;
end

form = {};
timestamp = [];
count= 1;
for i = 1:length(forms)
    try
        timestamp(count) = filenameToTimeStamp(fileName,forms{i});
        form{count} = forms{i};
        count = count + 1;
    catch
    end
end

if length(timestamp) > 1 % Multiple matching formats
    if all(diff(timestamp))==0 % All yield same result
        timestamp = timestamp(1);
        form = form{1};
    end
end
if length(form)==1
    form=char(form);
end