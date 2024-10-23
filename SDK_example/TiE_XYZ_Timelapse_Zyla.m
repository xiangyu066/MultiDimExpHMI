%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - Title: TiE_XYZ_Timelapse_Zyla.m
% - Author: XYZ
% - Created date: November 26, 2020
% - Modified date: March 16, 2021
% - Notes:
%       1.) The main part is for bead assay.
% - Version: 2.1
% - Environments: Win10 (64-bit) / MATLAB 2020b (64-bit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all, clear all, warning('off')

%% Load system configuration
disp('Loading imaging system configuration...')

% load MM core
import mmcorej.*
mmc = CMMCore;
mmc.loadSystemConfiguration('MMConfig_TiE_XYZ.cfg');
disp('MM core has been initiallized.')

% load SDK for Andor Zyla
AT_InitialiseLibrary();
[~,hndl] = AT_Open(0);
disp('Andor SDK library has been initialized.');

% NI DAQ
dq = daq("ni");
addoutput(dq, "Dev2", "ao0", "Voltage");

%%
global listing_Pos
listing_Pos = nisPosToMat('C:\Users\motorsgroup\Desktop\multipoints2.xml');

%% Set parameters of imaging system
% set lamp intensity
% DiaLampVolt = 20;
% mmc.setProperty('TIDiaLamp','Intensity',num2str(DiaLampVolt));
% mmc.getProperty('TIDiaLamp','Intensity');

%% Andor Zyla setting
% monitor sensor temperature and cooling %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AT_SetBool(hndl,'SensorCooling',1);                                         % turn on/off cooling
[~,cooling] = AT_GetBool(hndl,'SensorCooling');                          	% get cooling status
[~,currentIndex] = AT_GetEnumIndex(hndl,'TemperatureStatus');            	% get temperature status [0-cooler off, 1-stable, 2-cooling, 3-drift, 4-not stable, 5-Fault]
[~,SensorTemp] = AT_GetFloat(hndl,'SensorTemperature');                     % get sensor temperaure
disp(['Current sensor temperature is ',num2str(SensorTemp),' degree Celsius.'])

% min exposure time = clock %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AT_SetBool(hndl,'Overlap',1);
[~,bool] = AT_GetBool(hndl,'Overlap');

% spurious noise filter %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AT_SetBool(hndl,'SpuriousNoiseFilter',1);
[~,bool] = AT_GetBool(hndl,'SpuriousNoiseFilter');

% ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AT_SetBool(hndl,'VerticallyCentreAOI',1);
[~,bool] = AT_GetBool(hndl,'VerticallyCentreAOI');

roiSize = 400;
AT_SetInt(hndl,'AOIHeight',roiSize);
% AT_SetInt(hndl,'AOIWidth',roiSize);
% AT_SetInt(hndl,'AOILeft',1024-roiSize/2);
AT_SetInt(hndl,'AOIWidth',2048);
AT_SetInt(hndl,'AOILeft',0);

[~,imagesize] = AT_GetInt(hndl,'ImageSizeBytes');
[~,height] = AT_GetInt(hndl,'AOIHeight');
[~,width] = AT_GetInt(hndl,'AOIWidth');
[~,left] = AT_GetInt(hndl,'AOILeft');
[~,stride] = AT_GetInt(hndl,'AOIStride');

% gain mode %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AT_SetEnumIndex(hndl,'SimplePreAmpGainControl',2);
[~,currentIndex] = AT_GetEnumIndex(hndl,'SimplePreAmpGainControl');         % 0-12-bit (high well capacity), 1-12-bit (low noise), 2-16-bit (low noise & high well capacity)

% exposure time %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ExposureTimeInSecond = 0.005;
AT_SetEnumString(hndl,'TriggerMode','Internal');
AT_SetFloat(hndl,'ExposureTime', ExposureTimeInSecond);                     
[~,ExposureTimeInSecond] = AT_GetFloat(hndl,'ExposureTime');
disp(['The exposure time is ',num2str(ExposureTimeInSecond),' sec.'])

% acquisition rate %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,frameRate_Max] = AT_GetFloatMax(hndl,'FrameRate');
AT_SetFloat(hndl,'FrameRate',frameRate_Max);
[~,frameRate] = AT_GetFloat(hndl,'FrameRate');
disp(['The acquisition rate is ',num2str(frameRate),' Hz.'])

%% PFS
mmc.setProperty('TIPFSStatus','State','On')
pause(1)
mmc.getProperty('TIPFSStatus','State')
mmc.getProperty('TIPFSOffset','Position')

%% Preview and add ROIs
ScreenSize = get(0,'ScreenSize');

fig = uifigure('Position',[ScreenSize(1),ScreenSize(4)-1024,128,128]);
btn1 = uibutton(fig,'State',...
    'Text','Preview',...
    'Position',[32, 76, 64, 24],...
    'ValueChangedFcn', @(btn1,event) Preview_Zyla(btn1,mmc,hndl,dq,imagesize,height,width,stride));

btn2 = uibutton(fig,'Push',...
    'Text','Add ROI',...
    'Position',[32, 32, 64, 24],...
    'ButtonPushedFcn', @(btn2,event) addROI(btn2,mmc));

%% Main
% timelapse setting %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IntervalTimeInSecond = 3600;
nLoops = 24;
nFrames = 303;
outputdir = 'G:\20210325';

% initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = timer('TimerFcn',@(~,~) disp(datetime(now,'ConvertFrom','datenum')),...
    'StartDelay',IntervalTimeInSecond);
[~,msg] = mkdir(outputdir);
if ~isempty(msg)
   error('Directory already exists, please rename outputdir.') 
end
nPoss = size(listing_Pos,1);
for nPos = 1:nPoss
    outputsubdir = [outputdir,'\Pos',num2str(nPos)];
    mkdir(outputsubdir);
end

% camera setting %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AT_SetEnumString(hndl,'CycleMode','Fixed');
AT_SetEnumString(hndl,'TriggerMode','Internal');
% AT_SetEnumString(hndl,'SimplePreAmpGainControl','12-bit (high well capacity)');
AT_SetEnumString(hndl,'SimplePreAmpGainControl','12-bit (low noise)');
AT_SetEnumString(hndl,'PixelEncoding','Mono12');
% AT_SetEnumString(hndl,'SimplePreAmpGainControl','16-bit (low noise & high well capacity)');
% AT_SetEnumString(hndl,'PixelEncoding','Mono16');
AT_SetInt(hndl,'FrameCount',nFrames);
for X = 1:nFrames
    AT_QueueBuffer(hndl,imagesize);
end
database = uint16(zeros(height,width,nFrames));

% execute timelapse task %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,SensorTemp] = AT_GetFloat(hndl,'SensorTemperature');                     % get sensor temperaure
[~,frameRate] = AT_GetFloat(hndl,'FrameRate');
disp(['Current sensor temperature is ',num2str(SensorTemp),' degree Celsius.'])
disp(['The acquisition rate is ',num2str(frameRate),' Hz.'])
disp(strcat('Running...',string(datetime(now,'ConvertFrom','datenum'))))
for nLoop = 1:nLoops
    start(T)
    disp(strcat('Running...','(current loop:',num2str(nLoop),' / total loop:',num2str(nLoops),')'))
    
    % trun on the lamp
%     mmc.setProperty('TIDiaLamp','State','1')                                
%     pause(3)                                                                % to make sure the lamp has been turn on
    write(dq,5);                                                           
    pause(1)
    
    for nPos = 1:nPoss
        mmc.setXYPosition(listing_Pos(nPos,1),listing_Pos(nPos,2))          % move stage
        mmc.setProperty('TIPFSOffset','Position',num2str(listing_Pos(nPos,4)))
        pause(1)                                                            % to make sure the stage is arrived at defined position
        
        % kinetic series
        AT_Command(hndl,'AcquisitionStart');
        for i = 0:nFrames-1
            [~,buf] = AT_WaitBuffer(hndl,1000);
            AT_QueueBuffer(hndl,imagesize);
            [~,buf2] = AT_ConvertMono12ToMatrix(buf,height,width,stride);
%             [~,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
            database(:,:,i+1) = flip(transpose(buf2),2);
        end
        AT_Command(hndl,'AcquisitionStop');
        
        % write database into disk
        outputfile = [outputdir,'\Pos',num2str(nPos),'\T_',num2str(nLoop-1),'.tif'];
        for nFrame = 1:nFrames
            imwrite(database(:,:,nFrame),outputfile,'WriteMode','append','Compression','None');
        end
    end
    
    % turn off the lamb
%     mmc.setProperty('TIDiaLamp','State','0')                                
    write(dq,0);   
    
    % timer
    wait(T)
end
AT_Flush(hndl);
disp('Done.')

%% disconnect camera
AT_Close(hndl);
AT_FinaliseLibrary();
disp('Camera shutdown.');
