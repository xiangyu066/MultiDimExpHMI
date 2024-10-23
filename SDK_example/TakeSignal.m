function Img = TakeSignal(mmc, width, height, pixelType)
mmc.snapImage();
Img = mmc.getImage();
Img = typecast(Img, pixelType);
Img = reshape(Img,width,height,[]);
Img = transpose(Img);