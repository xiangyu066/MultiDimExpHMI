close all, clear all
disp('Running...')

%%
inputfile = 'template_TiE.xml';
outputfile = 'multipoints.xml';

%%
% load NIS's ND template
S = readstruct(inputfile);
SS = S.no_name;
fields = fieldnames(SS);
SSS = getfield(SS,fields{4});

% load mat file
load('03-Aug-2021_listing_pos.mat')

% Create elements of structure
S_ = S;
SS_ = SS;
SSS_ = SSS;
for n = 0:size(Pos,1)-1
    SS_ = setfield(SS_,['Point',sprintf('%05d',n)],SSS);
end
S_.no_name = SS_;
fields = fieldnames(SS_);

% convert mat to structure
for n = 4:length(fieldnames(S_.no_name))
    SSS_.dXPosition.valueAttribute = Pos(n-3,1);
    SSS_.dYPosition.valueAttribute = Pos(n-3,2);
    SSS_.dZPosition.valueAttribute = Pos(n-3,3);
    SSS_.dPFSOffset.valueAttribute = Pos(n-3,4)*40;
    SS_ = setfield(SS_,fields{n},SSS_);
end
S_.no_name = SS_;

% save conversion file
writestruct(S_,outputfile,'StructNodeName','variant','FileType','xml')

%%
sampleXMLfile = outputfile;
DOMnode = xmlread(sampleXMLfile);
text = xmlwrite(DOMnode);
startIndex = regexp(text,'\s');
remove_idxs = [];
for n = 2:length(startIndex)
    diff_idx = startIndex(n) - startIndex(n-1);
    if diff_idx==1
       remove_idxs = [remove_idxs,startIndex(n),startIndex(n-1)];
    end
end
remove_idxs = unique(remove_idxs);
text_ = text;
text_(remove_idxs) = '';
text_ = [text_(1:58),'.0',text_(59:end)];

fid = fopen(outputfile,'wt');
fprintf(fid, text_);
fclose(fid);

%%
disp('Done.')
