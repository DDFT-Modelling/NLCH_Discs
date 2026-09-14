function tout = autosave(varargin)
% AUTOSAVE automatically saves data in the base workspace
% AUTOSAVE saves all of the variables in the base workspace every 10
% minutes, to the matlab.mat file.
% AUTOSAVE(PERIOD) will save data every PERIOD minutes to the matlab.mat file.
% AUTOSAVE(PERIOD,SAVEFILE) will save variables to the file whose name is
%  specified by SAVEFILE.
% AUTOSAVE(PERIOD,SAVEFILE,SAVEARGS) will pass the options in the cell
%  array as inputs to the SAVE function.
% AUTOSAVE STOP will disable autosaving.
% AUTOSAVE START will restart autosaving.
% AUTOSAVE DELETE will disable autosaving, delete the autosave file, and
%  remove the timer used to perform the saving.
%
% Examples:
%
%    % autosave with defaults
%
%    autosave
% 
%
%    % autosave every 3 minutes
%
%    autosave(3)
%
%
%    % autosave every 7 minutes, to data.mat
%
%    autosave(7,'data.mat')
%
%
%    % save variables whose names start with 'x' into 'test.mat'
%    % every 5 minutes.
%
%    autosave(5,'test.mat','x*')
% 

% defaults
period = 10;
filename = 'matlab.mat';
saveargs = {};

% check inputs
error(nargchk(0,3,nargin));

% handle STOP/START/DELETE
if nargin == 1 && ischar(varargin{1})
    switch  lower(varargin{1})
        case 'start'
            t = getappdata(0,'AutoSaveTimerHandle');
            if isempty(t)
                t = timerfind('Tag','AutoSaveTimer');
            end
            if isempty(t) || ~isvalid(t)
                t = autosave;
            end
            if strcmp(get(t,'Running'),'off')
                start(t);
            end
        case 'stop'
            t = getappdata(0,'AutoSaveTimerHandle');
            if isempty(t)
                t = timerfind('Tag','AutoSaveTimer');
            end
            if ~isempty(t) && isvalid(t)
                stop(t);
            end            
        case 'delete'
            t = autosave('stop');
            if isvalid(t)
                delete(t);
            end
            filename = getappdata(0,'AutoSaveFile');
            if ~isempty(filename) && exist(which(filename))
                delete(filename)
            end            
    end
    
    % return early
    if nargout
        tout = t;
    end
    return;
end


% assign inputs
switch nargin
    case 1
        period = varargin{1};
    case 2
        period = varargin{1};
        filename = varargin{2};
    case 3 
        period = varargin{1};
        filename = varargin{2};
        saveargs = varargin{3};
end

% check inputs. 
msg = checkPeriod(period); error(msg);
msg = checkFilename(filename); error(msg);
msg = checkSaveArgs(saveargs); error(msg);

% convert to seconds
periodSeconds = period * 60;

t = getappdata(0,'AutoSaveTimerHandle');

if isempty(t) || ~isvalid(t)
    % create timer object
    t = timer('TimerFcn',{@savedata,filename,saveargs},...
        'Period',periodSeconds,...
        'ExecutionMode','fixedRate',...
        'Tag','AutoSaveTimer');
    % save timer handle
    setappdata(0,'AutoSaveTimerHandle',t);
    setappdata(0,'AutoSaveFile',filename);
end

      
% start the timer
if strcmp(get(t,'Running'),'off')
    start(t);
end

if nargout
    tout = t;
end

%%%%%%%%%%%  save data  %%%%%%%%%%%

function savedata(h,ev,filename,saveargs)
%SAVEDATA saves data from the base workspace

% convert cell array to a single string
if iscellstr(saveargs)
    tmpsaveargs = '';
    for n = 1:length(saveargs)
        tmpsaveargs = [tmpsaveargs ' ' saveargs{n}];
    end
    saveargs = tmpsaveargs;
end

% create string to execute that will save the data
savestr = ['save ' filename ' ' saveargs];
evalin('base',savestr);



%%%%%%%%%%  check inputs  %%%%%%%%%%

function msg = checkPeriod(period)
msg = '';
if ~isnumeric(period) || numel(period) ~= 1
    msg = 'First input must be a numeric scalar.';
end

function msg = checkFilename(filename)
msg = '';
if ~ischar(filename) || size(filename,1) ~= 1
    msg = 'Second input must be a string array.';
end

function msg = checkSaveArgs(saveargs)
msg = '';
if isempty(saveargs)
    return
end
if ~ischar(saveargs) && ~iscellstr(saveargs)
    msg = 'Third input must be a string array or cell array of strings.';
end