function listing_Pos = nisPosToMat(inputfile)
S = readstruct(inputfile);
SS = S.no_name;
fields = fieldnames(SS);

listing_Pos = [];
for nPt = 4:length(fieldnames(S.no_name))
    SSS = getfield(SS,fields{nPt});
    x = SSS.dXPosition.valueAttribute;
    y = SSS.dYPosition.valueAttribute;
    PFS = SSS.dPFSOffset.valueAttribute/40;
    listing_Pos = [listing_Pos;x,y,PFS];
end

