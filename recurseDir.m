function results = recurseDir(folder,wildcard)
% This script will crawl the audio archive and get the timestamps of all
% files 

% Ensure that the folder ends with an appropriate '\' or '/'
if ~strcmp(folder(end),filesep)
    folder(end+1) = filesep;
end

% Find all the subdirectories
subfolders = dir(folder);
subfolders = subfolders([subfolders.isdir]);

% Exclude '.', '..', and '.svn' 
excl = isdotdir(subfolders) | issvndir(subfolders);
subfolders(excl) = [];

% Get the files in this directory. If there are files, append the full path
results = dir([folder wildcard]);
for i = 1:length(results);
    results(i).name = [folder results(i).name];
end

% Recursively get the files for all the subdirectories
for i = 1:length(subfolders);
    results = [results; recurseDir([folder subfolders(i).name],wildcard)];
end



%% ------------------------------------------------------------------------
function tf = issvndir(d)
% True for ".svn" directories.
% d is a structure returned by "dir"
%

is_dir = [d.isdir]';

is_svn = strcmp({d.name}, '.svn')';
%is_svn = false; % uncomment to disable ".svn" filtering 

tf = (is_dir & is_svn);

%---------------------------- end of subfunction --------------------------

%% ------------------------------------------------------------------------
function tf = isdotdir(d)
% True for "." and ".." directories.
% d is a structure returned by "dir"
%

is_dir = [d.isdir]';

is_dot = strcmp({d.name}, '.')';
is_dotdot = strcmp({d.name}, '..')';

tf = (is_dir & (is_dot | is_dotdot) );

%---------------------------- end of subfunction --------------------------

%% ------------------------------------------------------------------------
function tf = evaluate(d, expr)
% True for item where evaluated expression is correct or return a non empty
% cell.
% d is a structure returned by "dir"
%

% Get fields that can be used
name = {d.name}'; %#ok<NASGU>
date = {d.date}'; %#ok<NASGU>
datenum = [d.datenum]'; %#ok<NASGU>
bytes = [d.bytes]'; %#ok<NASGU>
isdir = [d.isdir]'; %#ok<NASGU>

tf = eval(expr);

% Convert cell outputs returned by "strfind" or "regexp" filters to a
% logical.
if iscell(tf)
  tf = not( cellfun(@isempty, tf) );
end

%---------------------------- end of subfunction --------------------------