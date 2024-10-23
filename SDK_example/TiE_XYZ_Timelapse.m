%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - Title: TiE_XYZ_Timelapse.m
% - Author: XYZ
% - Created date: November 25, 2020
% - Modified date: November 26, 2020
% - Notes:
%       1.)
% - Version: 1.1
% - Environments: Win10 (64-bit) / MATLAB 2020b (64-bit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all, clear all, warning('off')

%%
global listing_Pos
listing_Pos = [];

%% Load system configuration
import mmcorej.*
mmc = CMMCore;
mmc.loadSystemConfiguration('MMConfig_TiE_XYZ_AndorEM.cfg');

%% Get image infomation
width = mmc.getImageWidth();
height = mmc.getImageHeight();
if (mmc.getBytesPerPixel==2)
    pixelType = 'uint16';
else
    pixelType = 'uint8';
end

%% Set parameters of imaging system
% set camera exposure time
ExposureTimeInMilliSec = 30;
mmc.setExposure(ExposureTimeInMilliSec)
mmc.getExposure()

% set gain value
GainValue = 10;
mmc.getProperty('Andor','Pre-Amp-Gain')                                     % ask current gain mode
mmc.setProperty('Andor','Gain',num2str(GainValue))                          % default 2
mmc.getProperty('Andor','Gain')                                             % ask current gain value

% set lamp intensity
DiaLampVolt = 15;
mmc.setProperty('TIDiaLamp','Intensity',num2str(DiaLampVolt))
mmc.getProperty('TIDiaLamp','Intensity')

%% Preview and add ROIs
ScreenSize = get(0,'ScreenSize');

fig = uifigure('Position',[ScreenSize(1),ScreenSize(4)-256,128,128]);
btn1 = uibutton(fig,'State',...
    'Text','Preview',...
    'Position',[32, 76, 64, 24],...
    'ValueChangedFcn', @(btn1,event) PreviewCCD(btn1,mmc,width,height,pixelType));

btn2 = uibutton(fig,'Push',...
    'Text','Add ROI',...
    'Position',[32, 32, 64, 24],...
    'ButtonPushedFcn', @(btn2,event) defineROI(btn2,mmc));

%% Main
% timelapse setting
IntervalTimeInSecond = 120;
nLoops = 90;

% 
outputdir = 'F:\XYZ\Test';

% initialization
T = timer('TimerFcn',@(~,~) disp(datetime(now,'ConvertFrom','datenum')),...
    'StartDelay',IntervalTimeInSecond);
[~,msg]=mkdir(outputdir);
if ~isempty(msg)
   error('Directory already exists, please rename outputdir.') 
end
nFrames = size(Positions,1);
database = uint16(zeros(height,width,nFrames));

% execute timelapse task
disp(strcat('Running...',string(datetime(now,'ConvertFrom','datenum'))))
for nLoop = 1:nLoops
    start(T)
    disp(strcat('Running...','(current loop:',num2str(nLoop),' / total loop:',num2str(nLoops),')'))
    
    % trun on the lamp
    mmc.setProperty('TIDiaLamp','State','1')
    pause(3)                                                                % to make sure the lamp has been turn on
    
    %
    for nFrame = 1:nFrames
        % move stage
        mmc.setXYPosition(listing_Pos(nFrame,1),listing_Pos(nFrame,2))
        pause(1)                                                            % to make sure the stage is arrived at defined position
        
        % capture
        Img = TakeSignal(mmc, width, height, pixelType);
        database(:,:,nFrame) = Img;
    end
    
    % turn off the lamp
    mmc.setProperty('TIDiaLamp','State','0')
    
    % write database into disk
    outputfile = [outputdir,'\T_',num2str(nLoop),'.tif'];
    for nFrame = 1:nFrames
        imwrite(database(:,:,nFrame),outputfile,'WriteMode','append','Compression','None');
    end
    
    wait(T)
end
disp('Done.')
