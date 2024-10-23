%%
% Author: XYZ
% Ver. 1.0
close all, clear all

%%
global msec um
msec = 1;
um = 1;

%% Load system configuration
import mmcorej.*             
mmc = CMMCore;
mmc.loadSystemConfiguration('MMConfig_TiE_XYZ.cfg');

%% Get image infomation
width = mmc.getImageWidth();
height = mmc.getImageHeight();
if (mmc.getBytesPerPixel==2)
    pixelType = 'uint16';
else
    pixelType = 'uint8';
end

%% Get and set capture setting
mmc.setExposure(30*msec)
mmc.getExposure()

mmc.setProperty('Andor','Gain','10')                                        % default 2
mmc.getProperty('Andor','Gain')                                             % ask current gain value
mmc.getProperty('Andor','Pre-Amp-Gain')                                     % ask current gain mode

%% Preview
for nFrame = 1:100
    % capture
    mmc.snapImage();
    Img = mmc.getImage();
    Img = typecast(Img,pixelType);
    Img = reshape(Img,width,height,[]);
    Img = transpose(Img);
    
    % monitoring
    figure(1), cla(gca), imshow(Img(:,:),[]), drawnow
end

%% scan large area
% pre register memory
nFrames = 200;
if strcmp(pixelType,'uint16')
    database = uint16(zeros(height,width,nFrames));
else
    database = uint8(zeros(height,width,nFrames));
end

%% evaluate task
disp('Running...'), tic
for nLoop = 1:5
    for nFrame = 1:nFrames
        % move stage
        x = mmc.getXPosition();
        y = mmc.getYPosition();
        if (nFrame==1)&&(nLoop==1)
            mmc.setXYPosition(x,y)
        elseif (nFrame==1)&&(nLoop>1)
            mmc.setXYPosition(x-53*um,y)
        else
            mmc.setXYPosition(x,y+(-1)^(nLoop-1)*53*um)
        end
        pause(0.1)                                                          % to make sure that stage has arrived the defined position 
        
        % capture
        mmc.snapImage();
        Img = mmc.getImage();
        Img = typecast(Img, pixelType);
        Img = reshape(Img,width,height,[]);
        Img = transpose(Img);
        
        % monitoring
        figure(1), cla(gca), imshow(Img(:,:),[]), drawnow
        
        % save data into memory
        database(:,:,nFrame)=Img;
        
        % save batch data into drive
        if (nFrame==nFrames)
            outputfile=strcat('F:\XYZ\Test\test_',num2str(nLoop),'.mat');
            save(outputfile,'database')
        end
    end
end
toc, disp('Done.')


