function Preview_Zyla(btn,mmc,hndl,dq,imagesize,height,width,stride)
if (btn.Value==true)
    btn.Text='Closed';
%     mmc.setProperty('TIDiaLamp','State','1')                                % turn on the lamb
    write(dq,5);

    % camera setting
    AT_SetEnumString(hndl,'CycleMode','Continuous');
    AT_SetEnumString(hndl,'TriggerMode','Software');
    AT_SetEnumString(hndl,'SimplePreAmpGainControl','12-bit (low noise)');
    AT_SetEnumString(hndl,'PixelEncoding','Mono12');
%     AT_SetEnumString(hndl,'SimplePreAmpGainControl','16-bit (low noise & high well capacity)');
%     AT_SetEnumString(hndl,'PixelEncoding','Mono16');
    AT_Command(hndl,'AcquisitionStart');
    
    [~,SensorTemp] = AT_GetFloat(hndl,'SensorTemperature');                     % get sensor temperaure
    [~,frameRate] = AT_GetFloat(hndl,'FrameRate');
    disp(['Current sensor temperature is ',num2str(SensorTemp),' degree Celsius.'])
    disp(['The acquisition rate is ',num2str(frameRate),' Hz.'])
    disp('Open shutter...')
    
    h = imagesc(zeros(height,width));
    colormap('gray')
    set(gcf,'WindowStyle','docked')
    
else
    btn.Text='Preview';
%     mmc.setProperty('TIDiaLamp','State','0')                                % turn off the lamb
    write(dq,0);

    close(gcf)
    disp('Close shutter...')
    
    % flush camera buffer
    AT_Command(hndl,'AcquisitionStop');
    AT_Flush(hndl);
end

while (btn.Value)
    AT_QueueBuffer(hndl,imagesize);
    AT_Command(hndl,'SoftwareTrigger');
    [~,buf] = AT_WaitBuffer(hndl,1000);
    [~,buf2] = AT_ConvertMono12ToMatrix(buf,height,width,stride);
%     [~,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
    set(h,'CData',flip(buf2.',2))
%     set(gca, 'CLim',[512,800])
%     mmc.getProperty('TIPFSOffset','Position')
    drawnow
end

end