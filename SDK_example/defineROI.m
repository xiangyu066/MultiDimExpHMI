function defineROI(btn,mmc)
global listing_Pos
x = mmc.getXPosition();
y = mmc.getYPosition();
listing_Pos = [listing_Pos;x,y];
end