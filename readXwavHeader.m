function header = readXwavHeader(fileName)
m = 0;
fid = fopen(fileName,'r');
fseek(fid,22,'bof');
header.numberOfChannels = fread(fid,1,'uint16');         % Number of Channels

fseek(fid,34,'bof');

header.bitsPerSample = fread(fid,1,'uint16');       % # of Bits per Sample : 8bit = 8, 16bit = 16, etc
if header.bitsPerSample == 16
   header.dataBlockType = 'int16';
elseif header.bitsPerSample == 32
    header.dataBlockType = 'int32';
else
    disp_msg('bitsPerSample = ')
    disp_msg(bitsPerSample)
    disp_msg('not supported')
    return
end

fseek(fid,80,'bof');

header.numberOfRawFiles = fread(fid,1,'uint16');     % Number of RawFiles in XWAV file (80 bytes from bof)

fseek(fid,100,'bof');
for r = 1:header.numberOfRawFiles             % loop over the number of raw files in this xwav file
    m = m + 1;                                % count total number of raw files
    header.rawFileId(m) = r;                           % raw file id / number in this xwav file
    year(m) = fread(fid,1,'uchar');           % Year
    month(m) = fread(fid,1,'uchar');          % Month
    day(m) = fread(fid,1,'uchar');            % Day
    hour(m) = fread(fid,1,'uchar');           % Hour
    minute(m) = fread(fid,1,'uchar');         % Minute
    secs(m) = fread(fid,1,'uchar');           % Seconds
    ticks(m) = fread(fid,1,'uint16');         % Milliseconds
    header.byteLoc(m) = fread(fid,1,'uint32');      % Byte location in xwav file of RawFile start
    header.byteLength(m) = fread(fid,1,'uint32');   % Byte length of RawFile in xwav file
    header.writeLength(m) = fread(fid,1,'uint32');  % # of blocks in RawFile length (default = 60000)
    header.sampleRate(m) = fread(fid,1,'uint32');   % sample rate of this RawFile
    header.gain(m) = fread(fid,1,'uint8');           % gain (1 = no change)
    header.padding = fread(fid,7,'uchar');           % Padding to make it 32 bytes...misc info can be added here
    header.fname(m,:) = fileName;        % xwav file name for this raw file header
%     dataSize = wavread(fileName,'size');
    info = audioinfo(fileName);
    dataSize = info.TotalSamples;
    header.numberOfSamples = dataSize(1);
    header.startDate(m) = datenum([year(m)+2000 month(m) day(m)...
        hour(m) minute(m) secs(m)+(ticks(m)/1000)]); % Matlab datenum
	header.duration(m) = header.numberOfSamples ./ header.sampleRate; % In seconds
    header.endDate(m) = header.startDate(m) + header.duration/86400; % Matlab datenum
        

end
fclose(fid);