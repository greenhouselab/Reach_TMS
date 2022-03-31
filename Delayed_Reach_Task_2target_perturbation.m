
% This script produces a delayed Reaching Task, records tablet data (querried per trial), 
% triggers TMS at specified timepionts, and records multiple EMG channels simultaenously. 
% Task parameters can be altered for specific user needs. 

% Contact Isaac @ igomez7@uoregon.edu for assistance. 


function Reach_IG_v05_051021
%(responding_hand, responding_muscle, MVC, ylims)
% adapted from reach_speech_FB_makeTGTs.m and fbReach_game.m

Screen_Sync_Test = 1;


%% task parameters
% Experiment blocks
parameters.practice_trial_num = 20; % default is 20
parameters.pre_perturbation_trial_num = 60; % default is 60
parameters.perturbation_trial_num = 90; % default is 90
parameters.washout_trial_num = 90; % default is 90
parameters.post_perturbation_trial_num = 30; % default is 30
parameters.washoutWithFeedback_trial_num = 6; % default is 6
% Trial numbers
total_trials = parameters.practice_trial_num + ...
    parameters.pre_perturbation_trial_num + ...
    parameters.perturbation_trial_num + ...
    parameters.washout_trial_num + ...
    parameters.post_perturbation_trial_num + ...
    parameters.washoutWithFeedback_trial_num;
parameters.test_trial_num = parameters.pre_perturbation_trial_num + ...
    parameters.perturbation_trial_num + ... 
    parameters.washout_trial_num + ...
    parameters.post_perturbation_trial_num;
before_rotation_trial_num = parameters.practice_trial_num + ...
    parameters.pre_perturbation_trial_num;
before_post_rotation_trial_num = before_rotation_trial_num + parameters.perturbation_trial_num + parameters.washout_trial_num;


% TMS trial numbers
parameters.no_TMS_trial_num = round((total_trials/5),0); % none during practice
parameters.bas_TMS_trial_num = round(((total_trials/5)*2),0); % 2/5 of trials 
parameters.del_TMS_trial_num = round(((total_trials/5)*2),0); % 2/5 of trials
% Catch trials
parameters.catch_trial_num = round((total_trials/10),0);
% Event parameters
parameters.cue_onset = [1 1.5]; % for jitter
parameters.cue_duration = .9;
parameters.delay_duration = .9;
parameters.target_duration = .8;
parameters.delay_pulse_times = .82; % pulse was coming 20 ms too early?
parameters.ITI_pulse_times = .2;

% EMG and photodiode
parameters.reference_line = .025; % in mV
parameters.EMG_plot_Ylims = [-.1 .1; -.1 .1; -.1 .1; -.1 .1; -.1 .1]; % in mV %%MF
parameters.xlims=[0 3];% in mV
parameters.sampling_rate=5000;
parameters.sweep_duration=4;
parameters.save_per_sweep=1;
num_channels = 5; 
diode_chan = 9;
diode=1;

% Rotation parameters (stepwise introduction of perturbation)
parameters.rotation_step_1 = before_rotation_trial_num +1;
parameters.rotation_step_2 = before_rotation_trial_num + 2;
parameters.rotation_step_3 = before_rotation_trial_num + 3;
parameters.rotation_step_4 = before_rotation_trial_num + 4;
parameters.rotation_step_5 = before_rotation_trial_num + 5;
parameters.rotation_step_6 = before_rotation_trial_num + 6;
parameters.rotation_step_7 = before_rotation_trial_num + 7;
parameters.rotation_step_8 = before_rotation_trial_num + 8;
parameters.rotation_step_9 = before_rotation_trial_num + 9;
parameters.rotation_step_10 = before_rotation_trial_num + 10;
parameters.rotation_step_11 = before_rotation_trial_num + parameters.perturbation_trial_num +1;
% Stepwise release of rotation
parameters.rotation_step_12 = before_post_rotation_trial_num;
parameters.rotation_step_13 = before_post_rotation_trial_num + 1;
parameters.rotation_step_14 = before_post_rotation_trial_num + 2;
parameters.rotation_step_15 = before_post_rotation_trial_num + 3;
parameters.rotation_step_16 = before_post_rotation_trial_num + 4;
parameters.rotation_step_17 = before_post_rotation_trial_num + 5;
parameters.rotation_step_18 = before_post_rotation_trial_num + parameters.post_perturbation_trial_num;
% parameters.rotation_angle = 20; % in deg (see rotatexy function)
parameters.gain = 1; % not sure what does (see rotatexy function)



%% Calculate DC offset
offset=setOffset(num_channels, diode);
subject.offset = offset;
%% Input
practice = input('Practice (1) or run (0) or debug (2): ');

switch practice
    case 0
        TMS = 1;%if not a practice trial, TMS is on, change back to 1 for experiment
        save_data = 1; % save data
        subject.ID = input('Enter subject ID #: ');%input numerical value
        time = clock;% 6 element date and time vector
        subject.time = time;
        subject.date = date;%current date string
        subject.handedness = input('Enter subject handedness (l or r): ', 's');
        subject.sex = input('Enter subject sex (m or f): ', 's');
        subject.date_of_birth = input('Enter subject date of birth: ','s');
        subject.RMT = input('Subject Resting Motor Threshold:');
        parameters.rotation_direction = input('Enter rotation direction (n for negative or p positive): ', 's');
        % store parameters in subject struct
        subject.parameters = parameters;
        
        
    case 1
        TMS = 0;%If practice trial, TMS is off
        save_data = 0; % do not save data
        subject.ID = input('Enter subject ID #: ');
%         total_trials = parameters.practice_trial_num;
    case 2
        TMS = 1;%if not a practice trial, TMS is on, change back to 1 for experiment
        save_data = 0; % do not save data
        
end

%% define abort keys
% esc=KbName('ESCAPE');% 41 in this case
% abort_keys = {'ESCAPE'};%make cell
% keypressed = 0;
% displayed_key = 0;
% WaitSecs(1);%wait 1 second
%% setup figure for EMG recording
f1 = figure(1);
EMGfigure(num_channels,parameters.EMG_plot_Ylims,parameters.reference_line,diode,f1,[],parameters.xlims, 1)
WaitSecs(1);
%% Set up serial ports
delete(instrfindall); % remove old serial port objects
if TMS
    myMS = magstim('COM3');
    myMS.connect();
    myMS.arm();
    myMS.setAmplitudeA(58)
    WaitSecs(5);
end
%% creat trials table
trials = table();

% trial phases
trials.phase(1:parameters.practice_trial_num, 1) = {'practice'};
start_test = height(trials) + 1;
trials.phase(height(trials) + 1:height(trials) + parameters.pre_perturbation_trial_num, 1) = {'pre_perturbation'};
trials.phase(height(trials) + 1:height(trials) + parameters.perturbation_trial_num, 1) = {'perturbation'};
trials.phase(height(trials) + 1:height(trials) + parameters.washout_trial_num, 1) = {'washout_noFB'};
trials.phase(height(trials) + 1:height(trials) + parameters.post_perturbation_trial_num, 1) = {'post_perturbation'};
trials.phase(height(trials) + 1:height(trials) + parameters.washoutWithFeedback_trial_num, 1) = {'washout_w/FB'};
% trial numbers
trials.trial_num(:,1) = 1:height(trials);
if TMS
    trials.TMS(start_test:start_test + parameters.bas_TMS_trial_num) = {'bas'};
    trials.TMS(start_test + parameters.bas_TMS_trial_num:start_test + parameters.bas_TMS_trial_num + parameters.del_TMS_trial_num) = {'del'};
end
% Go or Catch Trials
trials.go_or_catch(1:total_trials-parameters.catch_trial_num,1) = {'go'};
trials.go_or_catch(total_trials-parameters.catch_trial_num+1:total_trials,1) = {'catch'};
temp_table = trials(start_test:start_test + parameters.test_trial_num - 1,2:4);
temp_table.trial_num = randperm(parameters.test_trial_num)';
temp_table = sortrows(temp_table,'trial_num');
trials(start_test:start_test + parameters.test_trial_num -1,2:4) = temp_table(:,1:3);
% Target Location
%     trials.target_coordinates{1} = [];
trials.target_num(1:total_trials,1) = randi(2,[total_trials,1]);
% for washout with Feedack trials (equal number to each target & no 'catch'
trials.target_num(total_trials-parameters.washoutWithFeedback_trial_num:total_trials-(parameters.washoutWithFeedback_trial_num/2),1) = 1; % first 3 trials
trials.target_num(total_trials-(parameters.washoutWithFeedback_trial_num/2)+1:total_trials,1) = 2;  % last 3 trials of washoutWithFeedback
trials.go_or_catch(total_trials-parameters.washoutWithFeedback_trial_num+1:total_trials,1) = {'go'}; %no catch trials
    
trials.target_angle(1:total_trials,1) = zeros;
% Gradual Rotation (2 deg per trial until full rotation)
trials.rotation(1:total_trials,1) = zeros;
trials.rotation(parameters.rotation_step_1:parameters.rotation_step_2,1) = 2;
trials.rotation(parameters.rotation_step_2:parameters.rotation_step_3,1) = 4;
trials.rotation(parameters.rotation_step_3:parameters.rotation_step_4,1) = 6;
trials.rotation(parameters.rotation_step_4:parameters.rotation_step_5,1) = 8;
trials.rotation(parameters.rotation_step_5:parameters.rotation_step_6,1) = 10;
trials.rotation(parameters.rotation_step_6:parameters.rotation_step_7,1) = 12;
trials.rotation(parameters.rotation_step_7:parameters.rotation_step_8,1) = 14;
trials.rotation(parameters.rotation_step_8:parameters.rotation_step_9,1) = 16;
trials.rotation(parameters.rotation_step_9:parameters.rotation_step_10,1) = 18;
trials.rotation(parameters.rotation_step_10:parameters.rotation_step_11,1) = 20;
% Release of Rotation
trials.rotation(parameters.rotation_step_12:parameters.rotation_step_13,1) = 10;
trials.rotation(parameters.rotation_step_13:parameters.rotation_step_14,1) = 8;
trials.rotation(parameters.rotation_step_14:parameters.rotation_step_15,1) = 6;
trials.rotation(parameters.rotation_step_15:parameters.rotation_step_16,1) = 4;
trials.rotation(parameters.rotation_step_16:parameters.rotation_step_17,1) = 2;
trials.rotation(parameters.rotation_step_17:parameters.rotation_step_18,1) = 0;
% Overwrite washout block to have zero rotation
trials.rotation(strcmp(trials.phase,'washout_noFB')) = 0;

% Target num
for i = 1:total_trials
    if trials.target_num(i) == 1
        trials.target_angle(i) = -45;
    elseif trials.target_num(i) == 2
        trials.target_angle(i) = 45;
    end
end
trials.target_distance(1:total_trials,1) = 542; % in pixels (15cm)

%   EMG channels
trials.ch1{1} = [];
trials.ch2{1} = [];
trials.ch3{1} = [];
trials.ch4{1} = [];
trials.ch5{1} = [];
trials.photodiode{1} = [];
% tablet data
trials.tabXpos{1} = [];
trials.tabYpos{1} = [];
%     trials.tabTimeStamp{1} = [];
% record trial events
trials.prep_cue_onset(height(trials)) = zeros;
trials.go_cue_onset(height(trials)) = zeros;
trials.too_soon(height(trials)) = zeros; % if cursor leaves home b4 go cue (Hyosub says to add 100ms of RT buffer)
trials.movement_time(height(trials)) = zeros; % from go cue to max reach distance
trials.hit_or_miss(height(trials)) = zeros;
trials.maxReachPoint{1} = [];

%% Set up Tabelt data variable
pktData = [];
KbName('UnifyKeyNames');
spaceKeyID = KbName('space');
%% set up screen
Screen('Preference', 'SkipSyncTests', Screen_Sync_Test);
% Child protection
AssertOpenGL;%Breaks if Screen() is not working or wrong version of Psychtoolbox

% Open onscreen window:
%sets stimulus presentation screen as "highest" screen
screen=max(Screen('Screens'));
screen=2;
[win, scr_rect] = Screen('OpenWindow', screen);%Open Psychtoolbox screen, designates win as window
[winWidth, winHeight]=Screen('WindowSize', win);%sets window height and width
black=BlackIndex(screen); % Should equal 0.
white=WhiteIndex(screen); % Should equal 255.

%from hyosub's code
% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(scr_rect);
% tablet
mm2pixel = 3.6137;
yOffset = 80*mm2pixel;
yCenter = yCenter + yOffset;
% I think there are 2540 lines per inch (lpi) on tablet
% tablet active area is 19.2 in x 12.0 in
tablet_x_scale = 1/27.625;
tablet_x_offset = -1.1969*2540;
tablet_y_scale = -1/27.625;
tablet_y_offset = 11.724*2540;
tablet_samplingrate = 500; % not sure if true

MAX_SAMPLES=6e6; %about 1 hour @ 1.6kHz = 60*60*1600
thePoints=nan(MAX_SAMPLES,2);
theTimepoints = nan(MAX_SAMPLES,1);
cursorPoints=nan(MAX_SAMPLES,2);
tabletPoints=uint16(nan(MAX_SAMPLES/8,2)); %reduce # of samples since the tablet is sampled @ 200Hz

% colors
pink = [220 0 220];
yellow = [220 220 0];
black = [0 0 0];
white = [220 220 220];
red = [220 0 0];
blue = [0 0 220];
purple = [200 0 200];
violet = [143, 0, 255];

green = [0 220 0];
background=[50, 50, 50];
% text formatting
theFont='Arial';
Screen('TextSize',win,45);
Screen('TextFont',win,theFont);
Screen('TextColor',win,white);
% home position
homeCenterX = winWidth/2;
homeCenterY = winHeight;
homeTopX = homeCenterX - 72; % 72 pixel = 2cm radius
homeTopY = homeCenterY - 72;
homeBottomX = homeCenterX + 72;
homeBottomY = homeCenterY + 72;
home_position = [homeTopX homeTopY homeBottomX homeBottomY];
% cursor
% Load cursor image
[cursor_img, ~, cursor_alpha] = imread('cursor.png');
cursor_img(:,:,4) = cursor_alpha(:,:);
mm2pixel = 3.6137;
pixel2mm = 1/mm2pixel;
cursor_r = 1.75*mm2pixel;
% target parameters
targetRadius = 18; % in pixels (1cm diameter)
targetDistance = 542; % in pixels (15cm)
% reachMaxDistance = (targetDistance - targetRadius)*pixel2mm*0.0393701;   % calculated for inches
reachMaxDistance = (targetDistance - targetRadius);
% target positions
% targetCenter0X = homeCenterX;
% targetCenter0Y = homeCenterY - targetDistance;
% target0 = [(targetCenter0X - targetRadius) (targetCenter0Y - targetRadius) (targetCenter0X + targetRadius) (targetCenter0Y + targetRadius)];
targetCenter2X = homeCenterX + (targetDistance * sin(45));
targetCenter2Y = homeCenterY - (targetDistance * cos(45));
target2 = [(targetCenter2X - targetRadius) (targetCenter2Y - targetRadius) (targetCenter2X + targetRadius) (targetCenter2Y + targetRadius)]; % 60 deg cclw from straight ahead
targetCenter1X = homeCenterX - (targetDistance * sin(45));
targetCenter1Y = homeCenterY - (targetDistance * cos(45));
target1 = [(targetCenter1X - targetRadius) (targetCenter1Y - targetRadius) (targetCenter1X + targetRadius) (targetCenter1Y + targetRadius)]; % 60 deg clw from straight ahead
% target location table
Target_Loc = [target1; target2];
Target_Table = Target_Loc(trials.target_num,:);

% for photodiode
corner_rect = [winWidth - 50, 0, winWidth, 50];%upper right corner

% for text instruction display
xTextLong = 100;
xTextShort = 700;
yTextLong = winHeight/4;
yTextShort = winHeight/2;
% Clear screen to background color:
Screen('FillRect', win, background);

% Initial display and sync to timestamp:
vbl=Screen('Flip',win);

% Give the display a moment to recover from the change of display mode when
% opening a window. It takes some monitors and LCD scan converters a few seconds to resync.
WaitSecs(2);

% %% Task Instructions
% Screen('DrawText', win, 'In todays task, you will be reaching for circular targets one at a time', xTextLong, yTextLong, background, white);
% Screen('Flip', win);
% WaitSecs(0.2);KbWait
% Screen('DrawText', win, 'First, the outline of a target will appear, then it will fill in with color', xTextLong, yTextLong, background, white);
% Screen('Flip', win);
% WaitSecs(0.2);KbWait
% Screen('DrawText', win, 'Wait until the target fills in with color to begin your reach', xTextLong, yTextLong, background, white);
% Screen('Flip', win);
% WaitSecs(0.2);KbWait
% Screen('DrawText', win, 'Slice through the target as fast and accurately as you can', xTextLong, yTextLong, background, white);
% Screen('Flip', win);
% WaitSecs(0.2);KbWait
% Screen('DrawText', win, 'Once the target disappears, return to the home position and relax your arm', xTextLong, yTextLong, background, white);
% Screen('Flip', win);
% WaitSecs(0.2);KbWait

% interface with tablet
WinTabMex(0, win); %initializes tablet
pktData = [];


%% DAQ setup
s = daq.createSession('ni');
s.DurationInSeconds = parameters.sweep_duration;
s.Rate = parameters.sampling_rate;
addchannels(s,diode);

%% Trial Loop
for trial = 1:total_trials
    targets = Target_Table(trial,:);
    % for wintabmex
    k = 0;
    inside_home = 0;
    tab_k = 15;
    hX = [];
    hY = [];
    EMG_start = GetSecs; % returns time in seconds at beginning of trial
    
    lh = addlistener(s,'DataAvailable',@plotData);
    s.startBackground();
    
    trial_start = GetSecs;
    trialLength = 1;
    prep_delay = .9;
    deltaT = 1/200;
    HideCursor
    %% RETURN HOME PHASE
    WinTabMex(2); %Empties the packet queue in preparation for collecting actual data
    
    while inside_home == 0
        
        Screen('FillOval', win, blue, home_position); % home position filled
        
        pkt = WinTabMex(5);
        
        while ~isempty(pkt) % makes sure data are in packet; once pkt is 'grabbed,' then rest of code executes
            tabletPoints(tab_k,1:2) = pkt(1:2)';    % placing x and y (pkt rows 1,2) into tabletPoints variable
            %                             tabletTime(tab_k) = (pkt(6)-tabletTime(16))/1000;   % tab_k initialized to 15; giving a little buffer at start of game?
            tab_k = tab_k+1;    % now tab_k is just another iterating variable
            %                             tablet_queue_length(k) = tablet_queue_length(k)+1;  % adding each loop through
            pkt = WinTabMex(5); % reads the latest data point out of a tablet's event queue
        end
        
        
        % HAND COORDINATES
        % x,y coordinates from WinTabMex pkt
        hX = (double(tabletPoints(tab_k-1,1))-tablet_x_offset)*tablet_x_scale;
        hY = (double(tabletPoints(tab_k-1,2))-tablet_y_offset)*tablet_y_scale;
        
        
        cursor = [(hX - cursor_r) (hY - cursor_r) (hX + cursor_r) (hY + cursor_r)];
        
        % make cursor appear when 1cm from home position
        if hY > home_position(2) - 72 & hX > home_position(1) - reachMaxDistance % 36 pixels = 2cm
            Screen('FillOval', win, white, cursor);
            Screen('Flip', win);
        end
        %         Screen('FillOval', win, white, cursor);
        %         Screen('Flip', win);
        
        if hX > home_position(1) && hX < home_position(3) && hY > home_position(2) && hY < home_position(4)
            inside_home = 1;
            trials.gotHome(trial,1) = GetSecs;
        else
            inside_home = 0;
        end
    end
    
    tab_k = 15; % reset before reach phase
    
    %% TMS PHASE
    %checks if early movement has occured - sends message and marks trial
    WinTabMex(2);
    if inside_home == 1
        while GetSecs - trials.gotHome(trial,1) < (rand(1)+.5) % on home for .5 to 1.5 sec before start of trial
            %                 WaitSecs(rand(1)); % home circle waits between 0-1sec
            Screen('FillRect', win, black, corner_rect); % photodiode to black
            Screen('FillOval', win, blue, home_position); % home stays on screen
            if hX > home_position(1) - reachMaxDistance % prevents flicker of cursor in corner
            Screen('FillOval', win, white, cursor);
            end
            Screen('Flip', win);
            
            pkt = WinTabMex(5);
            
            while ~isempty(pkt) % makes sure data are in packet; once pkt is 'grabbed,' then rest of code executes
                tabletPoints(tab_k,1:2) = pkt(1:2)';    % placing x and y (pkt rows 1,2) into tabletPoints variable
                %                             tabletTime(tab_k) = (pkt(6)-tabletTime(16))/1000;   % tab_k initialized to 15; giving a little buffer at start of game?
                tab_k = tab_k+1;    % now tab_k is just another iterating variable
                %                             tablet_queue_length(k) = tablet_queue_length(k)+1;  % adding each loop through
                pkt = WinTabMex(5); % reads the latest data point out of a tablet's event queue
            end
            
            
            % HAND COORDINATES
            % x,y coordinates from WinTabMex pkt
            hX = (double(tabletPoints(tab_k-1,1))-tablet_x_offset)*tablet_x_scale;
            hY = (double(tabletPoints(tab_k-1,2))-tablet_y_offset)*tablet_y_scale;
            % currently not stored in trials table
            
            cursor = [(hX - cursor_r) (hY - cursor_r) (hX + cursor_r) (hY + cursor_r)];
        end
        Screen('FrameOval', win, violet, targets, 3); % target outline (prep cue)
        Screen('FillRect', win, white, corner_rect); % photodiode to white
        Screen('FillOval', win, blue, home_position); % home stays on screen
        if hX > home_position(1) - reachMaxDistance
            Screen('FillOval', win, white, cursor);
        end
        Screen('Flip', win);
        trials.prep_cue_onset(trial,1) = GetSecs;
        % may add logic to check cursor stays within home while TMS
        % Baseline TMS pulse
        if TMS && strcmp(trials.TMS(trial,1),'bas') % string compare, if TMS and trial is baseline
            while GetSecs-trial_start < parameters.ITI_pulse_times % Wait to deliver TMS until ITI pulse time is met
                pause(0)
            end
            myMS.fire(); % trigger TMS via serial port
        end
        
        while GetSecs < (trials.prep_cue_onset(trial,1) + prep_delay)
            
            
            % Delay TMS pulse
            if TMS && strcmp(trials.TMS(trial,1),'del')
                while GetSecs - trials.prep_cue_onset(trial,1) < parameters.delay_pulse_times
                    pause(0)
                end
                myMS.fire(); % trigger TMS via serial port
            end
            
            pkt = WinTabMex(5);
            
            while ~isempty(pkt) % makes sure data are in packet; once pkt is 'grabbed,' then rest of code executes
                tabletPoints(tab_k,1:2) = pkt(1:2)';    % placing x and y (pkt rows 1,2) into tabletPoints variable
                %                             tabletTime(tab_k) = (pkt(6)-tabletTime(16))/1000;   % tab_k initialized to 15; giving a little buffer at start of game?
                tab_k = tab_k+1;    % now tab_k is just another iterating variable
                %                             tablet_queue_length(k) = tablet_queue_length(k)+1;  % adding each loop through
                pkt = WinTabMex(5); % reads the latest data point out of a tablet's event queue
            end
            
            
            % HAND COORDINATES
            % x,y coordinates from WinTabMex pkt
            hX = (double(tabletPoints(tab_k-1,1))-tablet_x_offset)*tablet_x_scale;
            hY = (double(tabletPoints(tab_k-1,2))-tablet_y_offset)*tablet_y_scale;
            % currently not stored in trials table
            
            cursor = [(hX - cursor_r) (hY - cursor_r) (hX + cursor_r) (hY + cursor_r)];
            Screen('FrameOval', win, violet, targets, 3); % target outline (prep cue)
            Screen('FillRect', win, white, corner_rect); % photodiode to white
            Screen('FillOval', win, blue, home_position); % home stays on screen
            if hX > home_position(1) - reachMaxDistance
                Screen('FillOval', win, white, cursor);
            end
            Screen('Flip', win);
            
            if hX > home_position(1) & hX < home_position(3) & hY > home_position(2) & hY < home_position(4)
                inside_home = 1;
            else
                inside_home = 0;
            end
            
            
            if tab_k > 15 & inside_home == 0
                % mark trial for pre-movement
                Screen('DrawText', win, 'Wait for the target to fill in', xTextShort, winHeight/2, white, background);
                Screen('Flip', win);
                WaitSecs(3);
                trials.too_soon(trial,1) = 1;
            end
            tab_k = 15; % reset before reach phase
        end
    end
    %% REACH PHASE
    
    if strcmp(trials.go_or_catch(trial,1), 'go') & ~trials.too_soon(trial,1) == 1 % go trial
        WinTabMex(2); %Empties the packet queue in preparation for collecting actual data
        
        trials.go_cue_onset(trial,1) = GetSecs;
        stop = trials.go_cue_onset(trial,1) + trialLength;
        k = 0;
        thePoints = []; % clear all points
        while GetSecs<stop
            k = k + 1;
            
            
            %This loop runs for deltaT or until it successfully retrieves some data from the queue
            %                     while 1  %Note this loop MUST be broken manually, as 'while 1' always returns TRUE
            pkt = WinTabMex(5);
            while ~isempty(pkt) % makes sure data are in packet; once pkt is 'grabbed,' then rest of code executes
                tabletPoints(tab_k,1:2) = pkt(1:2)';    % placing x and y (pkt rows 1,2) into tabletPoints variable
                %                             tabletTime(tab_k) = (pkt(6)-tabletTime(16))/1000;   % tab_k initialized to 15; giving a little buffer at start of game?
                tab_k = tab_k+1;    % now tab_k is just another iterating variable
                %                             tablet_queue_length(k) = tablet_queue_length(k)+1;  % adding each loop through
                pkt = WinTabMex(5); % reads the latest data point out of a tablet's event queue
            end
            
            
            % HAND COORDINATES
            % x,y coordinates from WinTabMex pkt
            hX = [];
            hY = [];
            hX = (double(tabletPoints(tab_k-1,1))-tablet_x_offset)*tablet_x_scale;
            hY = (double(tabletPoints(tab_k-1,2))-tablet_y_offset)*tablet_y_scale;
            if k == 2
                x_origin = hX;
                y_origin = hY;
            end
            
            thePoints(k,:) = [hX hY]; % record full precision points
            %                         theTimepoints(k) = tabletTime(tab_k-1); % record full precision points
            %                         hand_dist(k) = sqrt((hX-xCenter)^2 + (hY-yCenter)^2);
            if strcmp(trials.phase{trial},'perturbation')
                [hX hY] = rotatexy(hX-homeCenterX, hY-homeCenterY, trials.rotation(trial,1), parameters.gain, parameters.rotation_direction);
                    hX = hX + homeCenterX;
                    hY = hY + homeCenterY;
%                 if strcmp(parameters.rotation_direction,'p')
                    %                 cursor = [(hX + (hX/2)- cursor_r) (hY - (hY/2)- cursor_r) (hX + (hX/2) + cursor_r) (hY - (hY/2) + cursor_r)];
%                     if trials.target_num(trial,1) == 1
%                         xShift = cos((atan(hX/hY))-parameters.rotation_angle)*(sqrt((hX^2) + (hY^2)));
%                         yShift = sin((atan(hX/hY))-parameters.rotation_angle)*(sqrt((hX^2) + (hY^2)));
%                         cursor = [(xShift - cursor_r) (yShift - cursor_r) (xShift + cursor_r) (yShift + cursor_r)];
%                     elseif trials.target_num(trial,1) ==2
%                         xShift = cos((atan(hX/hY))-parameters.rotation_angle)*(sqrt((hX^2) + (hY^2)));
%                         yShift = sin((atan(hX/hY))-parameters.rotation_angle)*(sqrt((hX^2) + (hY^2)));
%                         cursor = [(xShift - cursor_r) (yShift - cursor_r) (xShift + cursor_r) (yShift + cursor_r)];
%                     elseif strcmp(parameters.rotation_direction,'n')
                        cursor = [(hX - cursor_r) (hY - cursor_r) (hX + cursor_r) (hY + cursor_r)];
%                     end
%                 end
            else
                cursor = [(hX - cursor_r) (hY - cursor_r) (hX + cursor_r) (hY + cursor_r)];
                cursorPoints(k,:) = [hX hY]; % record full precision points
            end
            if ~strcmp(trials.phase{trial},'washout_noFB')
                
                if k > 2
                    x_distance = hX - x_origin;
                    y_distance = hY - y_origin;
                    euclidian_distance = sqrt(x_distance^2 + y_distance^2);
                    distances(trial,k-1) = euclidian_distance;
                    
                    if euclidian_distance > reachMaxDistance
                    else
                        Screen('FillOval', win, white, cursor);
                    end
                elseif hX > home_position(1) - reachMaxDistance
                    Screen('FillOval', win, white, cursor);
                end
            end
            Screen('FillOval', win, violet, targets); % target is filled in  = imperative cue
            Screen('FillRect', win, black, corner_rect); % photodiode rectangle back to black
            
            if k == 1
                trials.go_cue_onset(trial,1) = GetSecs;
            end
            
            Screen('Flip', win);
        end
        
        %     pktData = pktData';  %Assemble the data and then transpose to arrange data in columns because of Matlab memory preferences
        
        
        
        %Sorts data and outputs to a save file
        if ~isempty(cursorPoints)
            %         trials.tabXpos{trial,1} = thePoints(1:tablet_samplingrate*trialLength,1);
            %         trials.tabYpos{trial,1} = thePoints(1:tablet_samplingrate*trialLength,2);
            trials.tabXpos{trial,1} = thePoints(1:k,1);
            trials.tabYpos{trial,1} = thePoints(1:k,2);
            %         trials.tabZpos{trial,1} = pktData(:,3);
            %         trials.tabTimeStamp{trial,1} = pktData(:,6);
            
        end
        % pktData = [];
        
        
    elseif strcmp(trials.go_or_catch(trial,1), 'catch') & ~trials.too_soon(trial,1) == 1 % catch trial
        Screen('FrameOval', win, violet, targets, 3); % target outline remains
        Screen('FillRect', win, white, corner_rect); % photodiode remains white
        Screen('Flip', win);
        WaitSecs(1);
        
        
    end
    %% Feedback Phase
    
    WinTabMex(2);
    
    pkt = WinTabMex(5);
    
    while ~isempty(pkt) % makes sure data are in packet; once pkt is 'grabbed,' then rest of code executes
        tabletPoints(tab_k,1:2) = pkt(1:2)';    % placing x and y (pkt rows 1,2) into tabletPoints variable
        %                             tabletTime(tab_k) = (pkt(6)-tabletTime(16))/1000;   % tab_k initialized to 15; giving a little buffer at start of game?
        tab_k = tab_k+1;    % now tab_k is just another iterating variable
        %                             tablet_queue_length(k) = tablet_queue_length(k)+1;  % adding each loop through
        pkt = WinTabMex(5); % reads the latest data point out of a tablet's event queue
    end
    
    
    % HAND COORDINATES
    % x,y coordinates from WinTabMex pkt
    hX = (double(tabletPoints(tab_k-1,1))-tablet_x_offset)*tablet_x_scale;
    hY = (double(tabletPoints(tab_k-1,2))-tablet_y_offset)*tablet_y_scale;
    
    
    cursor = [(hX - cursor_r) (hY - cursor_r) (hX + cursor_r) (hY + cursor_r)];
    
    if ~isempty(trials.tabXpos{trial,1})
        hX_origin = trials.tabXpos{trial,1}(2);
        hY_origin = trials.tabYpos{trial,1}(2);
        
        past_threshold = 0;
        maxReachPoint = [0 0];
        for index = 2:k
            x_distance = trials.tabXpos{trial,1}(index)-hX_origin;
            y_distance = trials.tabYpos{trial,1}(index)-hY_origin;
            euclidian_distance = sqrt(x_distance^2 + y_distance^2);
            if euclidian_distance > reachMaxDistance & ~past_threshold
                trials.maxReachPoint{trial,1} = [trials.tabXpos{trial,1}(index) trials.tabYpos{trial,1}(index)];
                maxReachPoint = [trials.tabXpos{trial,1}(index) trials.tabYpos{trial,1}(index)];
                past_threshold = 1;
                trials.movement_time(trial,1) = GetSecs - trials.go_cue_onset(trial,1);
            end
     
        end
        
        inside_target = 0;
        if maxReachPoint(1) > targets(1) && maxReachPoint(1) < targets(3) && maxReachPoint(2) > targets(2) && maxReachPoint(2) < targets(4)
            inside_target = 1;            
        end
    end
    tab_k = 15; % reset before reach phase
    
    if strcmp(trials.go_or_catch(trial,1),'go') & isempty(trials.maxReachPoint{trial,1})
        Screen('DrawText', win, 'Reach Faster', xTextShort, winHeight/2, white, background);
        Screen('Flip', win);
        WaitSecs(1.5);
    end
    
    if inside_target
        trials.hit_or_miss(trial,1) = 1;
        
        Screen('FillOval', win, blue, home_position); % home position displayed
        Screen('Flip', win);
        WaitSecs(2);
        
    elseif ~inside_target
        trials.hit_or_miss(trial,1) = 0;
        Screen('FillOval', win, blue, home_position); % return to home prompted
        Screen('Flip', win);
        WaitSecs(2);
    end
    
    % add testing breaks
    if trial == 65 % 65th trial = 15 before rotation block
        WinTabMex(3) % pause tablet querry
        Screen('DrawText', win, 'Take a Break', xTextShort, winHeight/2, white, background);
        Screen('Flip',win);
        WaitSecs(0.2);KbWait
    elseif trial == 155 % 155th trial = 15 before post-rotation block
        WinTabMex(3) % pause tablet querry
        Screen('DrawText', win, 'Take a Break', xTextShort, winHeight/2, white, background);
        Screen('Flip',win);
        WaitSecs(0.2);KbWait
    elseif trial == 245 % 215th trial = 15 before reachInDark block
        WinTabMex(3) % pause tablet querry
        Screen('DrawText', win, 'Take a Break', xTextShort, winHeight/2, white, background);
        Screen('Flip',win);
        WaitSecs(0.2);KbWait
    end
    
    %% Save Data
    if ~practice && parameters.save_per_sweep%only saves data if run trial
        cur_path = pwd;
        
        if isfolder([cur_path,'/data'])
        else
            mkdir(cur_path,'/data');%if variable
        end
        
        if ischar(subject.ID)%makes folder for subject if none exists already, if subject id is composed of characters or numbers
            if isfolder([cur_path,'/data/',subject.ID])
            else mkdir([cur_path,'/data/',subject.ID]);
            end
            subject_ID = subject.ID;
        elseif isnumeric(subject.ID)
            subject_ID = sprintf('%d',subject.ID);
            if isfolder([cur_path,'/data/',subject_ID])
            else mkdir([cur_path,'/data/',subject_ID]);
            end
        end
        
        outfile=sprintf('%s_%s_reach_pilot_%s_%s.mat', subject_ID, date);
        
        try
            save(['data/',subject_ID,filesep,outfile],'trials', 'subject', 'distances', 'Target_Loc');
        catch%in case save doesn't work
            fprintf('couldn''t save %s\n saving to conditional_stop_TMS.mat\n',outfile);
            subject_ID = sprintf('%d',subject_ID);%format data into string
            save(subject_ID);
        end
        
    end
    
    s.wait();
    %% extract data from figure, refresh figure
    [trials]=pulldata(diode,trial,f1,num_channels,trials);
    EMGfigure(num_channels,parameters.EMG_plot_Ylims,parameters.reference_line,diode,f1,[],parameters.xlims, trial+1)
    %%
    delete(lh) % delete listener
    %savestart=GetSecs;
    assignin('base','trials',trials);
    assignin('base','subject',subject);
    
end
%% feedback rotation
    function [rx, ry] = rotatexy(x,y,phi,gain,rotation_direction)
        % phi is in degrees
        phi=phi*pi/180;
        [theta r]=cart2pol(x,y);
        if strcmp(rotation_direction, 'n')
            [rx ry]=pol2cart(theta-phi,gain*r); % theta-phi = cclw / theta + phi = clw
        elseif strcmp(rotation_direction, 'p')
            [rx ry]=pol2cart(theta+phi,gain*r); % theta-phi = cclw / theta + phi = clw
        end
    end

%% shut it down
WinTabMex(3); % Stop/Pause data acquisition.
Priority(0);

if save_data && ~parameters.save_per_sweep
    cur_path = pwd;
    
    if isfolder([cur_path,'/data'])
    else
        mkdir(cur_path,'/data')
    end
    
    if ischar(subject.ID)%makes folder for subject if none exists already, if subject id is composed of characters or numbers
        if isfolder([cur_path,'/data/',subject.ID])
        else mkdir([cur_path,'/data/',subject.ID]);
        end
        subject_ID = subject.ID;
    elseif isnumeric(subject.ID)
        subject_ID = sprintf('%d',subject.ID);
        if isfolder([cur_path,'/data/',subject_ID])
        else mkdir([cur_path,'/data/',subject_ID]);
        end
    end
    if mvc
        outfile=sprintf('%s_MVC_EMGrecord_data_%s.mat', subject_ID, date);
    else
        outfile=sprintf('%s_EMGrecord_data_%s.mat', subject_ID, date);
    end
    
    save(['data/',subject_ID,filesep,outfile]','trials', 'subject'); % save data
end

Screen('DrawText', win, 'End of Testing!', xTextShort, winHeight/2, white, background);
Screen('Flip', win);
WaitSecs(3);
sca%Screen('CloseAll')
WinTabMex(1); % Shutdown driver.
stop(s);
ShowCursor
%% plot data
    function plotData(src,event)
        plot_data = [];
        for chan = 1:num_channels
            plot_data{chan}=event.Data(:,chan)-offset(chan);
        end
        if diode
            plot_data{num_channels+1}=event.Data(:,diode_chan);%-offset(chan); % check for fixed diode offset value
        end
        
        plots = size(plot_data,2);
        for chan = 1:plots
            subplot(plots,1,chan);
            plot(event.TimeStamps,plot_data{chan},'k');
        end
    end
end


