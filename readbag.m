%ReadBag
% Copy the specified topic messages from rosbag to a table.
% A discription file 'propertyTable.csv' is needed.
% Gxb 2021-09-05
clc
clear
global typeName
global typeNum

[file,path] = uigetfile('*.bag',...
   'Select One or More Files', ...
   'MultiSelect', 'on');
if isequal(file,0)
   disp('User selected Cancel');
else
   file = cellstr(file);
   path = cellstr(path);
   fileName = fullfile(path,file);
end

propertyTable = readtable('propertyTable.csv'); % read configuration file
proSize = size(propertyTable, 1);

fSize = size(file,2);
for count = 1 : fSize
    unit = fix(100/fSize);
    process =  unit * (count - 1);
    disp([num2str(process,'%.2f'), '%  Get the bag<<', ...
        file{1,count}, '(', num2str(count,'%d'), '/', num2str(fSize,'%d'), ')']);
    myBag = rosbag(fileName{1, count});
    
    %% Manual select
    % prompt = 'choose topic: 1-/steering_angle_deg; 2-/velometer/base_link_local; 3-/imu/data; 4-/parking_slot_info; 5-/odometer/local_map/base_link\n';
    %
    % topicChoose = input(prompt);
    
    % if isempty(find([1 2 3 4 5] == topicChoose,1))
    %     return
    % end
    %%
    
    % read data name
    process = process + 0.25 * unit;
    disp([num2str(process,'%.2f'), '%  Resolve the bag...']);
    for topicChoose = 1 : proSize
        topicName = char(propertyTable.topicName(topicChoose));
        dataTableName = erase(topicName, '/');
        
        dataTypeNum = propertyTable.dataTypeNum(topicChoose);
        typeName = ["" ""];
        for typeNum = 1: dataTypeNum
            eval(['typeName(' num2str(typeNum, '%d') ...
                ')= string(propertyTable.typeName' num2str(typeNum, '%d') '(topicChoose));']);
        end
        
        % read bag data
        timeLine = [NaN, NaN];  % NaN for all, set the data time
        if isnan(timeLine(1)) && isnan(timeLine(2))
            eval([dataTableName '= select(myBag, ''Time'', [myBag.StartTime myBag.EndTime], ''Topic'', topicName);']);
        else
            eval([dataTableName '= select(myBag, ''Time'', [timeLine(1) timeLine(2)], ''Topic'', topicName);']);
        end
        
        % copy data to table
        process = process + 0.25 / proSize * unit;
        disp([num2str(process,'%.2f'), '%  Reading data from bag...']);
        eval(['number = ' dataTableName '.NumMessages;']);
        eval(['data = readMessages(' dataTableName ');']);
        eval([dataTableName '=zeros(number, dataTypeNum);']);
        
        process = process + 0.25 / proSize * unit;
        disp([num2str(process,'%.2f'), '%  Create the data table...']);
        for typeNum = 1 : dataTypeNum
            eval([dataTableName '(:,typeNum) = cellfun(@datacopy, data);']);
        end
        
        eval([dataTableName '(:,1) =' dataTableName '(:,1) + ' dataTableName '(:,2) .* 1e-9;']);
%         dataSave(:,1) = dataSave(:,1) + dataSave(:,2) .* 1e-9;
        eval([dataTableName '(:,2) = [];']);
%         dataSave(:,2) = [];
        saveFileName = erase(file{1, count}, '.bag');
        if ~exist('BagData', 'dir')
            mkdir('BagData');
        end
%         saveFileName = ['BagData/' saveFileName '.xls'];
        saveFileName = ['BagData/' saveFileName '.mat'];
        process = process + 0.24 / proSize * unit;
        disp([num2str(process,'%.2f'), '%  Saving data file...']);
        if ~exist(saveFileName, 'file')
            save(saveFileName, dataTableName);
        else
            save(saveFileName, dataTableName, '-append');
        end
%         writematrix(dataSave, saveFileName, 'Sheet', dataTableName);
        process = process + 0.01 / proSize * unit;
        disp([num2str(process,'%.2f'), '%  Finished.']);
    end
end
disp('Process Completed.');
clear;


%---------------------------------
function data = datacopy(mycell)
global typeName
global typeNum

data = eval(['mycell' char(typeName(typeNum))]);
end
