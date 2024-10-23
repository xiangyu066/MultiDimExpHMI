%%
% Author: XYZ
% Ver. x.x
close all, clear all

%%
global msec um
msec = 1;
um = 1;

%% Load system configuration
import mmcorej.*             
mmc = CMMCore;
mmc.loadSystemConfiguration('MMConfig_TiE_XYZ.cfg');

%% stage command
% ask current position
mmc.getPosition('TIZDrive')
mmc.getXPosition()
mmc.getYPosition()

% set position
mmc.setPosition('TIZDrive',1790)
mmc.setXYPosition()

%% set camera parameters
mmc.setExposure(50*msec)
mmc.getExposure()

mmc.setProperty('Andor','Gain','300')                                        % default 2
mmc.getProperty('Andor','Gain')                                             % ask current gain value
mmc.getProperty('Andor','Pre-Amp-Gain')                                     % ask current gain mode

%% get image size and type
width = mmc.getImageWidth();
height = mmc.getImageHeight();
if mmc.getBytesPerPixel == 2
    pixelType = 'uint16';
else
    pixelType = 'uint8';
end

%% snap image
mmc.snapImage();
Img = mmc.getImage();
Img = typecast(Img, pixelType);                                             % pixels must be interpreted as unsigned integers
Img = reshape(Img,width,height,[]);                                         % image should be interpreted as a 2D array
Img = transpose(Img);                                                       % make column-major order for MATLAB

figure, imshow(Img(:,:),[])
