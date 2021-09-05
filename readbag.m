%ReadBag
% Copy the specified topic messages from rosbag to a table.
% A discription file 'propertyTable.csv' is needed.
% Gxb 2021-09-05
clc
clear
global typeName
global typeNum

[file,path] = uigetfile('*.bag');
if isequal(file,0)
   disp('User selected Cancel');
else
   fileName = fullfile(path,file);
end
disp('0%  Get the bag...');
myBag = rosbag(fileName);

propertyTable = readtable('propertyTable.csv'); % read configuration file
prompt = 'choose topic: 1-/steering_angle_deg; 2-/velometer/base_link_local\n';

topicChoose = input(prompt);
if topicChoose ~= 1 && topicChoose ~= 2
    return
end

% read data name
disp('25%  Resolve the bag...');
topicName = char(propertyTable.topicName(topicChoose));
dataTableName = erase(topicName, '/');

dataTypeNum = propertyTable.dataTypeNum(topicChoose);
typeName = ["" ""];
for typeNum = 1: dataTypeNum
    eval(['typeName(' num2str(typeNum, '%d') ...
        ')= string(propertyTable.typeName' num2str(typeNum, '%d') '(topicChoose));']);
end

% read bag data
timeLine = [NaN, NaN];  % NaN for all
if isnan(timeLine(1)) && isnan(timeLine(2))
    eval([dataTableName '= select(myBag, ''Time'', [myBag.StartTime myBag.EndTime], ''Topic'', topicName);']);
else
    eval([dataTableName '= select(myBag, ''Time'', [timeLine(1) timeLine(2)], ''Topic'', topicName);']);
end

% copy data to table
disp('50%  Reading data from bag...');
eval(['number = ' dataTableName '.NumMessages;']);
eval(['data = readMessages(' dataTableName ');']);
dataSave = zeros(number, dataTypeNum);
disp('75%  Create the data table...');
for typeNum = 1 : dataTypeNum
    dataSave(:,typeNum) = cellfun(@datacopy, data);
end

saveFileName = erase(file, '.bag');
if ~exist('BagData', 'dir')
    mkdir('BagData');
end
saveFileName = ['BagData/' saveFileName '.xls'];
disp('99%  Saving data file...');
writematrix(dataSave, saveFileName, 'Sheet', topicChoose);
disp('100%  Finished.')

%---------------------------------
function data = datacopy(mycell)
global typeName
global typeNum

data = eval(['mycell' char(typeName(typeNum))]);
end
