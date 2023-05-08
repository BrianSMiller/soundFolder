function soundFolderMoved(oldFolder, newFolder)
% Update the filenames of a soundfolder that has moved. Leave everything
% else in the soundFolder the same.
% 
% Example: A user has moved a soundFolder from the location 'C:\MySound\'
% to an external drive 'E:\MySound\'.
% 
% soundFolderUpdate('C:\MySound\','E:\MySound\');

% Make sure the folder actually has a trailing slash
if ~strcmp(newFolder(end),filesep)
    newFolder(end+1) = filesep;
end

cacheFolder = getSoundCacheFolder;
cacheFile = [cacheFolder matlab.lang.makeValidName(oldFolder) '.mat'];
newFile = [cacheFolder matlab.lang.makeValidName(newFolder) '.mat'];

load(cacheFile,'fileInfo');

for i = 1:length(fileInfo);
    fileInfo(i).fname = strrep(fileInfo(i).fname,cacheFile,newFile);
end

save(newFile,'fileInfo');
