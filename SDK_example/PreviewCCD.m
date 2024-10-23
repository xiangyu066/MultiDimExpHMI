function PreviewCCD(btn, mmc, width, height, pixelType)
if (btn.Value==true)
    btn.Text='Closed';
    mmc.setProperty('TIDiaLamp','State','1')                                % turn on the light
else
    btn.Text='Preview';
    mmc.setProperty('TIDiaLamp','State','0')                                % turn off the light
end

while (btn.Value)
    Img = TakeSignal(mmc, width, height, pixelType);
    figure(1), cla(gca), imshow(Img,[])
    drawnow
end

end