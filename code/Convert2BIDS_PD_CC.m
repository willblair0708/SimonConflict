%% Load Parkinson's Conflict task data into BIDS with command-line scripts
clear all; clc

eeglabpath='Y:\Programs\eeglab2020_0\';  
addpath(eeglabpath); eeglab;

rootpath='Y:\EEG_Data\CAVANAGH\PDDys\';  addpath(rootpath);
rawdatapath='Y:\EEG_Data\CAVANAGH\PDDys\EEG\Raw EEG Data\';   cd(rawdatapath);
savepath=[rootpath,'CC_BIDS\'];  

% We usually keep track of meta data using .xls files
[NUM,TXT,RAW]=xlsread([rootpath,'PDDys_4BIDS.xlsx']);

%% Set up BIDS structures

% Content for README file
% -----------------------
README = sprintf( [ 'Simon conflict task with cost of conflict reinforcement manipulation.   '...
                    '28 Parkinson patients and 28 matched controls.  '...
                    'Task adapted from here: 10.1038/ncomms6394.    ' ...
                    'Beh data first published here: 10.1016/j.cortex.2017.02.021.  '...
                    'EEG published here: 10.1016/j.neuropsychologia.2018.05.020.   '...
                    'PD came in twice separated by a week, either ON or OFF medication.  CTL only came in once.  '... 
                    'Task included in Matlab programming language.   '...
                    'Data collected circa 2015 in Cognitive Rhythms and Computation Lab at University of New Mexico.  '...
                    'Subjs also had an acceleromter taped to their most tremor affected hand.  X, Y, Z dimensions recorded throughout.  '...
                    'Check the .xls sheet under code folder for more meta data.   '...
                    'Triggers are complicated.  See CC_Triggers.mat under code folder.  '...
                    'Many analysis scripts are included; no idea how these hold up.   Many are old.  '...
                    '- James F Cavanagh 02/08/2021' ]);
CHANGES = []; % Keep as null for inclusion below.  Not in use now, but maybe later.

% channel location file
% ---------------------
chanlocs = [eeglabpath,'\plugins\dipfit\standard_BESA\standard-10-5-cap385.elp'];
                
% general information for dataset_description.json file
% -----------------------------------------------------
gInfo.Name = 'SimonConflict';   % NO SPACES!
gInfo.ReferencesAndLinks = { 'PMID: 29802866' };      
gInfo.Authors = {'James F Cavanagh' ; 'Arun Singh'; 'Kumar Narayanan'};

% Task information for xxxx-eeg.json file
% ---------------------------------------
tInfo.InstitutionName = 'University of New Mexico';
tInfo.InstitutionalDepartmentName = 'Psychology';
tInfo.PowerLineFrequency = 60;
tInfo.ManufacturersModelName = 'Brain Vision ActiChamp';
tInfo.EEGGround = 'AFz';
tInfo.EEGReference = 'CPz';
tInfo.EEGChannelCount = 64;
tInfo.VEOGChannelCount = 1;
tInfo.EKGChannelCount = 1;

% List of stimuli to be copied to the stimuli folder
% --------------------------------------------------
stimuli = {'Manually put in the folder'};


% event column description for xxx-events.json file (only one such file)
% ----------------------------------------------------------------------
eInfo = {'onset'         'latency';
         'value'         'type' };  

eInfoDesc.onset.Description = 'Event onset';
eInfoDesc.onset.Units = 'seconds';  % Trigger occurs this number of seconds into the file
eInfoDesc.value.Description = 'Trigger Code';  % What was the trigger

trialTypes = {  
    'S  1' 'Test Resp: left,correct';
    'S  2' 'Test Resp: right,correct';
    'S  3' 'Test Resp: left,incorrect';
    'S  4' 'Test Resp: right,incorrect' ;
    'S  5' 'Test No Response' ;
    'S  8' 'FB: +1';
    'S  9' 'FB: 0';
    'S 12' 'Test Stim: AB';
    'S 13' 'Test Stim: AC';
    'S 14' 'Test Stim: AD';
    'S 21' 'Test Stim: BA';
    'S 23' 'Test Stim: BC';
    'S 24' 'Test Stim: BD';
    'S 31' 'Test Stim: CA';
    'S 32' 'Test Stim: CB';
    'S 34' 'Test Stim: CD';
    'S 41' 'Test Stim: DA';
    'S 42' 'Test Stim: DB';
    'S 43' 'Test Stim: DC';
    'S101' 'Trn Resp: left,correct';
    'S102' 'Trn Resp: right,correct';
    'S103' 'Trn Resp: left,incorrect';
    'S104' 'Trn Resp: right,incorrect' ;
    'S105' 'Trn No Response' ;
    'S111' 'Trn Stim: yellow congru A';
    'S112' 'Trn Stim: yellow congru B';
    'S113' 'Trn Stim: yellow congru C';
    'S114' 'Trn Stim: yellow congru D';
    'S121' 'Trn Stim: yellow incongru A';
    'S122' 'Trn Stim: yellow incongru B';
    'S123' 'Trn Stim: yellow incongru C';
    'S124' 'Trn Stim: yellow incongru D';
    'S211' 'Trn Stim: blue congru A';
    'S212' 'Trn Stim: blue congru B';
    'S213' 'Trn Stim: blue congru C';
    'S214' 'Trn Stim: blue congru D';
    'S221' 'Trn Stim: blue incongru A';
    'S222' 'Trn Stim: blue incongru B';
    'S223' 'Trn Stim: blue incongru C';
    'S224' 'Trn Stim: blue incongru D';
    };
%%

% participant information for participants.tsv file (will pull from meta data .xls vars within the loading loop)
% -------------------------------------------------
pInfo = { 'participant_id'  'Original_ID'  'Group'  'sess1_Med'  'sess2_Med'   'sex'   'age' };  

% participant column description for participants.json file
% ---------------------------------------------------------
pInfoDesc.participant_id.Description = 'unique participant identifier';
pInfoDesc.Original_ID.Description = 'participant identifier from recording';
pInfoDesc.Group.Description = 'PD or CTL';
pInfoDesc.sess1_Med.Description = 'Meds in session 1';
pInfoDesc.sess2_Med.Description = 'Meds in session 2';
pInfoDesc.sex.Description = 'sex of the participant';
pInfoDesc.age.Description = 'age of the participant';

      
Filz=dir([rawdatapath,'*_1_CC.eeg']);
for si=1:length(Filz)
    
    filename=Filz(si).name;
    subno=str2num(Filz(si).name(1:end-9));

    if subno<850  % PD
        data(si).file{1} = filename;
        data(si).file{2} = strcat(Filz(si).name(1:end-9),'_2_CC.eeg');
        data(si).session = [1,2];
        data(si).run = [1,1];
        data(si).notes = 'PD';
    else    % CTL
        data(si).file{1} = filename;
        data(si).session = 1;
        data(si).run = 1;  
        data(si).notes = 'CTL';
    end

    numidx=find(NUM(:,1)==subno);
    pInfo{si+1,2}=subno;  
    pInfo{si+1,3}=TXT{numidx+1,2}; % group         % +1 b/c of header    % MAKE SURE THESE ARE CELL BRACKETS FOR TXT
    pInfo{si+1,4}=TXT{numidx+1,3}; % sess1_Med     % +1 b/c of header
    if     strmatch(TXT{numidx+1,3},'ON'),  s2='OFF';
    elseif strmatch(TXT{numidx+1,3},'OFF'), s2='ON'; 
    elseif strmatch(TXT{numidx+1,3},'n/a'), s2='no s2'; 
    end
    pInfo{si+1,5}=s2;              % sess2_Med     % +1 b/c of header
    pInfo{si+1,6}=TXT{numidx+1,7}; % sex           % +1 b/c of header
    pInfo{si+1,7}=NUM(numidx,8);   % age

end


%% call to the export function
% ---------------------------
clc; fclose('all');
targetFolder =  savepath;   % Defined above
bids_export(data, ...
    'targetdir', targetFolder, ...
    'taskName', gInfo.Name,...
    'trialtype', trialTypes, ...
    'gInfo', gInfo, ...
    'pInfo', pInfo, ...
    'pInfoDesc', pInfoDesc, ...
    'eInfo', eInfo, ...
    'eInfoDesc', eInfoDesc, ...
    'README', README, ...
    'CHANGES', CHANGES, ...
    'chanlookup', chanlocs, ...
    'tInfo', tInfo, ...
    'copydata', 0);    

  % Changes to bids_export.m
  % JFC edited lines 927-933:  EEGcoord system probs
  % JFC edited line 631:  EEG = pop_loadcnt(fileIn, 'dataformat', 'int32', 'keystroke', 'on');  
