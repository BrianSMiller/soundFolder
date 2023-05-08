function cacheFolder = getSoundCacheFolder
% cacheFolder = getSoundCacheFolder
% This function is part of the soundFolder package. 
% soundFolder functions like wavFolderInfo.m can take a long time to complete if 
% there are thousands of wav files in the folder. To load these more
% quickly, soundFolder will attempt to cache the metadata from
% soundFolders. This function determines the location of the the
% soundFolder cache. 
%
% Presently two possible locations for the cache are possible: 
% Location 1 is a subfolder called cache located in the same folder as this
%   function, getSoundCacheFolder.m.
% Location 2 is the a subfolder called cache in the working directory,
%   pwd.
% Alternatively, one can edit this file so that it returns a user-specified
%   location e.g.: 
%     cacheFolder = 'C:\analysis\soundFolder\cache\';
%     return;
%

% Uncomment the two lines below and edit to specify your own location.
% cacheFolder = 'C:\analysis\soundFolder\cache\';
% return;

% User has not specified a folder 
subFolder = [filesep 'cache' filesep];
[path file ext] = fileparts(which('wavFolderInfo'));
cacheFolder = [path subFolder];


% Create default cache folder if it doesn't exist
if exist(cacheFolder,'dir')~=7 
    
    status = mkdir(cacheFolder);
     
    if status~=1 % Could not create default cache folder so use working folder
    
        warning(sprintf('Could not create soundFolder cache at %s',cacheFolder));
        cacheFolder = [pwd subFolder];
        status = mkdir(cacheFolder);

        if status ~= 1 % Could not write to working folder, so return an error
            error('ERROR: Please edit getSoundCacheFolder.m so that the cache is a folder that you can write to');
        end
            
    end
end

