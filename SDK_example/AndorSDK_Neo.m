%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - Title: AndorSDK_Neo.m
% - Author: XYZ
% - Created date: July 1, 2021
% - Modified date:
% - Notes:
%       1.)
% - Version: 
% - Environments: Win10 (64-bit) / MATLAB 2020b (64-bit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all, clear all, warning('off')

%% connect camera
AT_InitialiseLibrary();
[~,hndl]=AT_Open(0);
disp('Camera initialized');

%% monitor sensor temperature and cooling
[~,SensorTemp] = AT_GetFloat(hndl,'SensorTemperature')                      % get sensor temperaure
[~,currentIndex] = AT_GetEnumIndex(hndl,'TemperatureStatus')                % get temperature status [0-cooler off, 1-stable, 2-cooling, 3-drift, 4-not stable, 5-Fault]
[~,cooling] = AT_GetBool(hndl,'SensorCooling')                              % get cooling status
AT_SetBool(hndl,'SensorCooling', 1);                                        % turn on/off cooling

%% 
% acquisition rate
[~,frameRate] = AT_GetFloat(hndl,'FrameRate')
[~,frameRate_Max] = AT_GetFloatMax(hndl,'FrameRate')
[~,frameRate_Min] = AT_GetFloatMin(hndl,'FrameRate')
AT_SetFloat(hndl,'FrameRate',frameRate_Max);

% min exposure time = clock
[~,bool] = AT_GetBool(hndl,'Overlap')
AT_SetBool(hndl,'Overlap', 1);

% exposure time
ExposureTimeInSecond = 0.001;
AT_SetFloat(hndl,'ExposureTime', ExposureTimeInSecond);                     
[~,ExposureTimeInSecond] = AT_GetFloat(hndl,'ExposureTime')

% gain mode
[~,currentIndex] = AT_GetEnumIndex(hndl,'SimplePreAmpGainControl')          % 0-11-bit (high well capacity), 1-11-bit (low noise), 2-16-bit (low noise & high well capacity)
AT_SetEnumIndex(hndl,'SimplePreAmpGainControl',0);

% spurious noise filter
[~,bool] = AT_GetBool(hndl,'SpuriousNoiseFilter')

% ROI
[~,bool] = AT_GetBool(hndl,'VerticallyCentreAOI')
AT_SetBool(hndl,'VerticallyCentreAOI', 1);

% AT_SetInt(hndl,'AOIWidth',512);
% AT_SetInt(hndl,'AOIHeight',512);

[~,imagesize] = AT_GetInt(hndl,'ImageSizeBytes')
[~,height] = AT_GetInt(hndl,'AOIHeight')
[~,width] = AT_GetInt(hndl,'AOIWidth') 
[~,left] = AT_GetInt(hndl,'AOILeft ')
[~,stride] = AT_GetInt(hndl,'AOIStride') 

% coding
[~,currentIndex] = AT_GetEnumIndex(hndl,'PixelEncoding')                    % 0-Mono12, 2-Mono16

% readout
[~,currentIndex] = AT_GetEnumIndex(hndl,'PixelReadoutRate')                 % 0-10 MHz, 1-100 MHz, 2-200 MHz, 3-280 MHz
[~,currentIndex] = AT_GetEnumIndex(hndl,'SensorReadoutMode')                % 0-Top Down Simultaneous, 1-Centre Out Simultaneous, 2-Outside In Simultaneous, 3-Bottom Up Simultaneous, 4-Top Down Sequential, 5-Bottom Up Sequential

% trigger mode
[~,currentIndex] = AT_GetEnumIndex(hndl,'TriggerMode')                      % 0-Internal, 1-External Level Transition, 2-External Start, 3-External Exposure, 4-Software, 5-Advanced, 6-External

% shtter type
[~,currentIndex] = AT_GetEnumIndex(hndl,'ElectronicShutteringMode')         % 0-rolling shutter, 1-global shutter

%% Kinetic series mode
AT_SetEnumString(hndl,'CycleMode','Fixed');
AT_SetEnumString(hndl,'TriggerMode','Internal');
AT_SetEnumString(hndl,'SimplePreAmpGainControl','11-bit (high well capacity)');
AT_SetEnumString(hndl,'PixelEncoding','Mono12');

frameCount = 200;
AT_SetInt(hndl,'FrameCount',frameCount);
for X = 1:frameCount
    AT_QueueBuffer(hndl,imagesize);
end

database = uint16(zeros(height,width,frameCount));
disp('Starting acquisition...');
AT_Command(hndl,'AcquisitionStart'); tic
for i=0:frameCount-1
    [~,buf] = AT_WaitBuffer(hndl,1000);
    AT_QueueBuffer(hndl,imagesize);
    [~,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
    database(:,:,i+1)=flip(transpose(buf2));
end
disp('Acquisition complete'), toc
AT_Command(hndl,'AcquisitionStop');
AT_Flush(hndl);

%% Live mode
AT_SetEnumString(hndl,'CycleMode','Continuous');
AT_SetEnumString(hndl,'TriggerMode','Software');
AT_SetEnumString(hndl,'SimplePreAmpGainControl','11-bit (high well capacity)');
AT_SetEnumString(hndl,'PixelEncoding','Mono12');

disp('Preview...');
AT_Command(hndl,'AcquisitionStart');
h = figure(1);
while(ishandle(h))
    AT_QueueBuffer(hndl,imagesize);
    AT_Command(hndl,'SoftwareTrigger');
    [~,buf] = AT_WaitBuffer(hndl,1000);
    [~,buf2] = AT_ConvertMono12ToMatrix(buf,height,width,stride);
    figure(1), cla(gca), imshow(flip(transpose(buf2)),[min(buf2(:)),max(buf2(:))])
    drawnow;
end
disp('Done.');
AT_Command(hndl,'AcquisitionStop');
AT_Flush(hndl);

%% disconnect camera
AT_Close(hndl);
AT_FinaliseLibrary();
disp('Camera shutdown.');
