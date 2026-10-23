function timeStamp = filenameToTimeStamp(fileName,timeStampFormat)
%timeStamp = readTimeStamp(fileName,timeStampFormat)
% This function scans the wav filename for a timestamp to determine the
% starting date and time of the file. Embedding timestamps in the filename
% is a common feature of bioacoustics software such as PAMGuard, Ishmael,
% Raven, etc.
% FILENAME - A string containing the name to the wav file (e.g. output from DIR)
% TIMESTAMPFORMAT - A string compatible with Matlab DATESTR FORMATOUT, 
% for example, 'yyyy-mm-dd_HH-MM-SS'
% This function is part of the soundFolder package.
% See also: wavFolderInfo, audioread, readTimeStamp
if nargin==0
    test
    return
end

% Match against the file name only. Folder names can hold digits that look
% like a timestamp (e.g. Dep_01_yellowblack_05112023_113900\20231105_103259.wav),
% which would otherwise give two matches and a wrong or two-element result.
% Both separators are handled, so Windows paths parse on any platform.
fileName = regexprep(fileName, '^.*[\\/]', '');

% Swap the year, month, etc for individual digits
expression = regexprep(timeStampFormat,'dd','\\d\\d');
if contains(timeStampFormat,'yyyy') 
    expression = regexprep(expression,'yyyy','\\d\\d\\d\\d');  
else % if not 4 digit year assume 2-digit
    expression = regexprep(expression,'yy','\\d\\d');
end
expression = regexprep(expression,'mm','\\d\\d');
expression = regexprep(expression,'HH','\\d\\d');
expression = regexprep(expression,'MM','\\d\\d');
expression = regexprep(expression,'SS','\\d\\d');
expression = regexprep(expression,'fff','\\d\\d\\d');

% Now match the string
str = regexp(fileName,expression,'match');
if iscell(str{1})
    str = cellfun(@char,str,'UniformOutput',false)';
end

if isempty(str)
    % No date could be extracted from filename    
    timeStamp = datenum([0 1 1 0 0 0]);
    error('File start timestamp could not be read from header.');
else
    timeStampFormat = strrep(timeStampFormat,'\','');
    timeStamp = datenum(str,timeStampFormat);
end  

function test
fname = 'CINMS18B_d06_120622_055731.d100.x.wav';
form = 'yymmdd_HHMMSS';
print(fname,form);

fname = '20150115_170000.wav';
form = 'yyyymmdd_HHMMSS';
print(fname,form);

fname = '200_2013-12-25_06-00-00.wav';
form = 'yyyy-mm-dd_HH-MM-SS';
print(fname,form);


fname = '11_2018-02-02_07-00-00.wav';
form = 'yyyy-mm-dd_HH-MM-SS';
print(fname,form);

fname = '20150102-140944.wav';
form = 'yyyymmdd-HHMMSS';
print(fname,form);

fname = '7387.230116190739.wav';
form = 'yymmddHHMMSS';
print(fname,form);

% Folder name that also looks like a timestamp: only the file name counts
fname = 'W:\Tags\November 2023\Dep_01_yellowblack_05112023_113900\20231105_103259.wav';
form = 'yyyymmdd_HHMMSS';
print(fname,form);
assert(abs(filenameToTimeStamp(fname,form) - datenum(2023,11,5,10,32,59)) < 1e-9, ...
    'Timestamp should come from the file name, not the folder name');


function print(fname,form)
fprintf('%38s:\t %s\t %s\n',...
    fname, datestr(filenameToTimeStamp(fname,form)), form);