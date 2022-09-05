function dataselection(app)
fig = uifigure('Position',[100 100 250 400]);

% Create Numeric Edit Field
ef_x = uieditfield(fig,'numeric',...
    'Editable',false,...
    'Position',[125 360 100 22]);
ef_y = uieditfield(fig,'numeric',...
    'Editable',false,...
    'Position',[125 320 100 22]);
ef_z = uieditfield(fig,'numeric',...
    'Editable',false,...
    'Position',[125 280 100 22]);
ef_PFS = uieditfield(fig,'numeric',...
    'Editable',false,...
    'Position',[125 240 100 22]);

% Create List Box
lbox = uilistbox(fig,...
    'Items', {},...
    'ItemsData', [],...
    'Position',[10 80 100 300],...
    'ValueChangedFcn', @(src,event) selectionChanged(src));

% Create a push button
btn = uibutton(fig,'push',...
               'Text','Move',...
               'Enable',false,...
               'Position',[125, 200, 100, 22],...
               'ButtonPushedFcn', @(btn,event) MoveStage(btn,event,lbox));
           
% Create a push button
btn2 = uibutton(fig,'push',...
               'Text','Replace',...
               'Enable',false,...
               'Position',[125, 170, 100, 22],...
               'ButtonPushedFcn', @(btn2,event) UpdateList(btn2,event,lbox));
           
% Create a push button
btn3 = uibutton(fig,'push',...
               'Text','Save',...
               'Enable',false,...
               'Position',[125, 140, 100, 22],...
               'ButtonPushedFcn', @(btn3,event) SaveList(btn3,event,lbox));
           
% Create a push button
btn4 = uibutton(fig,'push',...
               'Text','Load',...
               'Enable',true,...
               'Position',[125, 110, 100, 22],...
               'ButtonPushedFcn', @(btn4,event) LoadList(btn4,event,lbox));
        
% Create a push button
btn5 = uibutton(fig,'push',...
               'Text','Nis2Mat',...
               'Enable',true,...
               'Position',[125, 80, 100, 22],...
               'ButtonPushedFcn', @(btn5,event) Nis2Mat(btn5,event,lbox));
           
% Create a push button
btn6 = uibutton(fig,'push',...
               'Text','Mat2Nis',...
               'Enable',true,...
               'Position',[125, 50, 100, 22],...
               'ButtonPushedFcn', @(btn6,event) Mat2Nis(btn6,event,lbox));

%
if size(app.listing_pos,1)>0
    btn.Enable = true;
    btn2.Enable = true;
    btn3.Enable = true;
    for i = 1:size(app.listing_pos,1)
        Items{i} = strcat('XY',num2str(i));
        ItemsData(i) = i;
    end
    lbox.Items = Items;
    lbox.ItemsData = ItemsData;
end

% ValueChangedFcn callback
function selectionChanged(src,event)
    % Display list box data in edit field
    idx = src.Value;
    ef_x.Value = app.listing_pos(idx,1);
    ef_y.Value = app.listing_pos(idx,2);
    ef_z.Value = app.listing_pos(idx,3);
    ef_PFS.Value = app.listing_pos(idx,4);
end

% Create the function for the ButtonPushedFcn callback
function MoveStage(btn,event,lbox)
    if (app.StageConnectButton.Value==1)
        idx = lbox.Value;
        app.listing_pos(idx,:);
        
        % move stage
        app.mmc.setXYPosition(app.listing_pos(idx,1),app.listing_pos(idx,2));
        if strcmp(app.mmc.getProperty('TIPFSStatus','State'),'Off')
            app.mmc.setPosition(app.listing_pos(idx,3));
        else
            app.mmc.setProperty('TIPFSOffset','Position',num2str(app.listing_pos(idx,4)));
        end
        pause(0.2)                                                          % to make sure the stage is arrived at defined position
        
        History = flip(app.HistoryTextArea.Value,1);
        nHistorys = size(History,1);
        History{nHistorys+1,1} = char(strcat(string(datetime(now,'ConvertFrom','datenum')),' -- Move stage to XY', num2str(idx),'.'));
        app.HistoryTextArea.Value = flip(History,1);
    end
end

% Create the function for the ButtonPushedFcn callback
function UpdateList(btn2,event,lbox)
    if (app.StageConnectButton.Value==1)
        idx = lbox.Value;
        x = app.mmc.getXPosition();
        y = app.mmc.getYPosition();
        z = app.mmc.getPosition();
        pfs_z = str2double(app.mmc.getProperty('TIPFSOffset','Position'));
        app.listing_pos(idx,:) = [x,y,z,pfs_z];
        ef_x.Value = app.listing_pos(idx,1);
        ef_y.Value = app.listing_pos(idx,2);
        ef_z.Value = app.listing_pos(idx,3);
        ef_PFS.Value = app.listing_pos(idx,4);
        
        History = flip(app.HistoryTextArea.Value,1);
        nHistorys = size(History,1);
        History{nHistorys+1,1} = char(strcat(string(datetime(now,'ConvertFrom','datenum')),' -- Renew a new coordinate of XY', num2str(idx),'.'));
        app.HistoryTextArea.Value = flip(History,1);
    end
end

% Create the function for the ButtonPushedFcn callback
function SaveList(btn3,event,lbox)
    selpath = uigetdir();
    if selpath~=0
        outputfile = strcat(selpath,'\',string(datetime(floor(now),'ConvertFrom','datenum')),'_listing_pos.mat');%[selpath,'\listing_pos.mat'];
        Pos = app.listing_pos;
        save(outputfile,'Pos');
        
        History = flip(app.HistoryTextArea.Value,1);
        nHistorys = size(History,1);
        History{nHistorys+1,1} = char(strcat(string(datetime(now,'ConvertFrom','datenum')),' -- Save positions.'));
        app.HistoryTextArea.Value = flip(History,1);
    end
end

% Create the function for the ButtonPushedFcn callback
function LoadList(btn4,event,lbox)
    [file,path] = uigetfile('*.mat');
    if path~=0
        S = load([path,file]);
        app.listing_pos = S.Pos0;
        
        for i = 1:size(app.listing_pos,1)
            Items{i} = strcat('XY',num2str(i));
            ItemsData(i) = i;
        end
        lbox.Items = Items;
        lbox.ItemsData = ItemsData;
        btn.Enable = true;
        btn2.Enable = true;
        btn3.Enable = true;
        
        History = flip(app.HistoryTextArea.Value,1);
        nHistorys = size(History,1);
        History{nHistorys+1,1} = char(strcat(string(datetime(now,'ConvertFrom','datenum')),' -- Load positions.'));
        app.HistoryTextArea.Value = flip(History,1);
    end
end

% Convert nis position to matlab array
function Nis2Mat(btn5,event,lbox)
%     [file,path] = uigetfile('*.xml');
%     if path~=0
%         inputfile=[path,file];
%         S = readstruct(inputfile);
%         SS = S.no_name;
%         fields = fieldnames(SS);
%         
%         listing_Pos = [];
%         for nPt = 4:length(fieldnames(S.no_name))
%             SSS = getfield(SS,fields{nPt});
%             x = SSS.dXPosition.valueAttribute;
%             y = SSS.dYPosition.valueAttribute;
%             PFS = SSS.dPFSOffset.valueAttribute/40;
%             listing_Pos = [listing_Pos;x,y,PFS];
%         end
%         
%         app.listing_pos=listing_Pos;
% 
%         History = flip(app.HistoryTextArea.Value,1);
%         nHistorys = size(History,1);
%         History{nHistorys+1,1} = char(strcat(string(datetime(now,'ConvertFrom','datenum')),' -- Load positions from NIS to MATLAB.'));
%         app.HistoryTextArea.Value = flip(History,1);
%     end
end

% Convert nis position to matlab array
function Mat2Nis(btn6,event,lbox)
%     inputfile = 'template_TiE.xml';
%     
%     
%     
%     
%     History = flip(app.HistoryTextArea.Value,1);
%     nHistorys = size(History,1);
%     History{nHistorys+1,1} = char(strcat(string(datetime(now,'ConvertFrom','datenum')),' -- Export positions from MATLAB to NIS.'));
%     app.HistoryTextArea.Value = flip(History,1);

end


end