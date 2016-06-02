function [Modulus,ModulusCI,Strain,Stress,ModEqn,ModGOF] = StressStrain(userstrain,plotctrl)
% StressStrain.m
% This function collects data from various sources to analyze the
% experimental mechanical properties of snow.  Load data is collected from
% Labview which includes load and LVDT data taken at 1000 Hz.  In addition,
% detailed strain/displacement data is provided by ARAMIS stage points
% placed at various points of interest.  With this data, stress/strain
% plots are produced along with material properties appropriate for the
% test performed.
%
% INPUTS:
%           userstrain: the user picks the source of strain data for
%           analyzing stress and strain. Valid choices are:
%               'dispx' - Displacement X
%               'dispy' - Displacement Y
%               'epsx' - Strain X
%               'epsy' - Strain Y
%               'epsxy' - Shear Strain
%               'major' - Major Strain
%               'minor' - Minor strain
%
%           plotctrl: Controls which plots display.  Paramters are as
%           follows:
%               0: No Plots
%               1: Stress/Strain Plots Only
%               2: All plots (stress/strain; Load/Displacement;
%               Load-Displacement/Time)
%               3: Load/Displacemet, Load-Displacement/Time plots only;
%
% OUTPUS:
%           Modulus - The slope of the stress strain curve during the
%           linear elastic portion of loading.
%               Ex:
%               -If using epsxy, this would be the shear modulus in (Pa)
%               -If using Major/Minor strain, this would be Young's modulus
%               in the direction of the respective strain (Pa)
%
%           ModulusCI - The lower and upper bounds of the 95% confidence
%           interval of the calculated modulus (described above)
%
%           Strain: Strain vector of the ARAMIS stagepoints averaged
%           together
%
%           Stress: Stress vector associated with the strain vector with
%           the same recording frequency of the strain vector
%
%           ModEqn: This is the cfit object produced by performing linear
%           regression on the linear portion of the stress strain data
%
% VERSION: 1.0
% DATE: May 29, 2014
%
% VERSION: 1.5 - Date: December 7, 2015: Added compressive strain
% functionality
% AUTHOR: David J Walters; Montana State University

%% Set Plot Controls
ebwidth = 0.1;  % Errorbar cap width
font = 'Palatino Linotype';
fsize = 10;
msize = 10;
%% Import Labview load data using subfunction
[Time,TriggerTime,~,Load,LVDT,LocalPath] = LabviewLoad;

%% Import ARAMIS strain data using subfunction
[Stage,Timems,major,minor,epsX,epsY,epsXY,d_xum,d_yum] = ARAMIS(LocalPath);
assignin('base','Timems',Timems)
Cutoff = Time(find(Load==max(Load),1))
if max(Timems{1}) < 1000
    for i = 1:length(Timems)
    Timems{i} = Timems{i} * 1000;
    end
end
for i = 1:length(Timems)
    for j = 1:length(Timems{i})
        if Timems{i}(j)/1000 > Cutoff
            Stage{i}(j:end) = [];
            Timems{i}(j:end) = [];
            major{i}(j:end) = [];
            minor{i}(j:end) = [];
            epsX{i}(j:end) = [];
            epsY{i}(j:end) = [];
            epsXY{i}(j:end) = [];
            d_xum{i}(j:end) = [];
            d_yum{i}(j:end) = [];
            break
        end
    end
end
assignin('base','epsY',epsY)
assignin('base','minor',minor)
assignin('base','epsXY',epsXY)
%% Manipulate Data
% Mesh data from different sources so they match
% Labview records data at 1,000 Hz whereas ARAMIS records data at 15 Hz
% (fps).  This function creates a load vector from Labview such that the
% readings are taken as if recorded at 15 Hz so the vector lengths match.
j = 0;
for i = 1:66:66*length(Timems{1})
    j = j+1;
    AramisLoad(j) = Load(i);
end
Stress = AramisLoad/(250/(100^2));
maxIndex = find(Stress==max(Stress),1);

switch userstrain
    case 'epsxy'
        % Average multiple strain guages for smoother data
        for i = 1:length(epsXY)
            epsXYFull(:,i) = epsXY{i};
        end
        meanEpsXY = mean(epsXYFull,2);
        Strain = meanEpsXY;
        MaxStrain = -meanEpsXY(maxIndex);
        exclusions = excludedata(-meanEpsXY,Stress',...
            'domain',[0 MaxStrain]);
        ft = fittype({'x','1'});
        [ModEqn,ModGOF] = fit(-meanEpsXY,Stress',...
            ft,'Exclude',exclusions)
        Mod = coeffvalues(ModEqn);
        Modulus = Mod(1);
        ModCI = confint(ModEqn);
        ModulusCI = ModCI(:,1);
        %         [ModEqn2,ModGOF2] = fit(-meanEpsXY,AramisStress',...
        %             'poly2','Exclude',exclusions)
        % Shear stress/strain plot
        % Plot Stress vs. Strain
        if plotctrl == 1 || plotctrl == 2
            figure('Name','Shear Stress-Strain','NumberTitle','off')
            plot(ModEqn)
            hold on
            plot(-meanEpsXY,Stress,'-','MarkerSize',msize)
            hold off
            %         hold on
            %         plot(ModEqn2,'g-')
            grid on
            x1 = xlabel('Shear Strain (rad)');
            y1 = ylabel('Stress (Pa)');
            leg = legend('Fit','Data','Location','northwest');
            set(gca,'FontName',font,'FontSize',fsize)
            set([y1 x1],'FontName',font,'FontSize',fsize)
            set(leg,'FontName',font,'FontSize',fsize)
            
            Adjust = input('Would you like to adjust the fit? Yes(1) or No (0)\n');
            if Adjust == 1
                usermaxx = input('Enter domain to fit. [xmin xmax]\n');
                usermaxy = input('Enter domain to fit. [ymin ymax]\n Enter 0 if no vertical limits. \n');
                if usermaxy ~= 0
                    exclusions = excludedata(-meanEpsXY,Stress',...
                        'box',[usermaxx usermaxy]);
                else
                    exclusions = excludedata(-meanEpsXY,Stress',...
                        'domain',usermaxx);
                end
                [ModEqn,ModGOF] = fit(-meanEpsXY,Stress',...
                    ft,'Exclude',exclusions)
                Mod = coeffvalues(ModEqn);
                Modulus = Mod(1);
                ModCI = confint(ModEqn);
                ModulusCI = ModCI(:,1);
                figure('Name','Shear Stress-Strain--Adjusted Fit','NumberTitle','off')
                plot(ModEqn)
                hold on
                plot(-meanEpsXY,Stress,'-','MarkerSize',msize)
                hold off
                grid on
                x1 = xlabel('Shear Strain (rad)');
                y1 = ylabel('Stress (Pa)');
                leg = legend('Fit','Data','Location','northwest');
                set(gca,'FontName',font,'FontSize',fsize)
                set([y1 x1],'FontName',font,'FontSize',fsize)
                set(leg,'FontName',font,'FontSize',fsize)
            end
        end
    case 'minor'
        % Average multiple strain guages for smoother data
        for i = 1:length(minor)
            minorFull(:,i) = minor{i};
        end
        meanminor = mean(minorFull,2);
        Strain = meanminor;
        MaxStrain = -meanminor(maxIndex);
        exclusions = excludedata(-meanminor,Stress',...
            'domain',[0 MaxStrain]);
        ft = fittype({'x','1'});
        [ModEqn,ModGOF] = fit(-meanminor,Stress',...
            ft,'Exclude',exclusions)
        Mod = coeffvalues(ModEqn);
        Modulus = Mod(1)*100; %Strain given in percent
        ModCI = confint(ModEqn);
        ModulusCI = ModCI(:,1)*100; %Strain given in percent
        %         [ModEqn2,ModGOF2] = fit(-meanEpsXY,AramisStress',...
        %             'poly2','Exclude',exclusions)
        % Shear stress/strain plot
        % Plot Stress vs. Strain
        if plotctrl == 1 || plotctrl == 2
            figure('Name','Compressive Stress-Strain','NumberTitle','off')
            plot(ModEqn)
            hold on
            plot(-meanminor,Stress,'-','MarkerSize',msize)
            hold off
            %         hold on
            %         plot(ModEqn2,'g-')
            grid on
            x1 = xlabel('Compressive Strain (%)');
            y1 = ylabel('Stress (Pa)');
            leg = legend('Fit','Data','Location','northwest');
            set(gca,'FontName',font,'FontSize',fsize)
            set([y1 x1],'FontName',font,'FontSize',fsize)
            set(leg,'FontName',font,'FontSize',fsize)
            
            Adjust = input('Would you like to adjust the fit? Yes(1) or No (0)\n');
            if Adjust == 1
                usermaxx = input('Enter domain to fit. [xmin xmax]\n');
                usermaxy = input('Enter domain to fit. [ymin ymax]\n Enter 0 if no vertical limits. \n');
                if usermaxy ~= 0
                    exclusions = excludedata(-meanminor,Stress',...
                        'box',[usermaxx usermaxy]);
                else
                    exclusions = excludedata(-meanminor,Stress',...
                        'domain',usermaxx);
                end
                [ModEqn,ModGOF] = fit(-meanminor,Stress',...
                    ft,'Exclude',exclusions)
                Mod = coeffvalues(ModEqn);
                Modulus = Mod(1)*100;   %Strain given in percent
                ModCI = confint(ModEqn);
                ModulusCI = ModCI(:,1)*100; %Strain given in percent
                figure('Name','Compressive Stress-Strain--Adjusted Fit','NumberTitle','off')
                plot(ModEqn)
                hold on
                plot(-meanminor,Stress,'-','MarkerSize',msize)
                hold off
                grid on
                x1 = xlabel('Compressive Strain (%)');
                y1 = ylabel('Stress (Pa)');
                leg = legend('Fit','Data','Location','northwest');
                set(gca,'FontName',font,'FontSize',fsize)
                set([y1 x1],'FontName',font,'FontSize',fsize)
                set(leg,'FontName',font,'FontSize',fsize)
            end
        end
end

%% Figures
if plotctrl == 2 || plotctrl == 3
    % Plot Load and displacement vs. time
    figure('Name','Load-Displacement vs Time','NumberTitle','off')
    h(1) = subplot(2,1,1);
    plot(Time,Load,'LineWidth',2)
    grid on
    h(2) = subplot(2,1,2);
    plot(Time,LVDT,'r','LineWidth',2)
    grid on
    set(get(h(1),'Ylabel'),'String','Load (N)')
    set(get(h(2),'Ylabel'),'String','Displacement(mm)')
    set(get(h(2),'Xlabel'),'String','Time(s)')
    
    % Plot Load and displacement vs. time, clipped to region of interest
    figure('Name','Load-Displacement vs Time Clipped','NumberTitle','off')
    h(1) = subplot(2,1,1);
    plot(Time,Load,'LineWidth',2)
    grid on
    h(2) = subplot(2,1,2);
    plot(Time,LVDT,'r','LineWidth',2)
    grid on
    set(get(h(1),'Ylabel'),'String','Load (N)')
    set(get(h(2),'Ylabel'),'String','Displacement(mm)')
    set(get(h(2),'Xlabel'),'String','Time(s)')
    % Adjust limits of the plot based on peak load
    set(h(1),'XLim',[0 Time(find(Load==max(Load),1))+0.5]);
    set(h(2),'XLim',[0 Time(find(Load==max(Load),1))+0.5]);
    set(h(1),'YLimMode','Auto');
    set(h(2),'YLimMode','Auto');
    set(h(1),'YTickMode','Auto');
    set(h(2),'YTickMode','Auto');
    
    % Plot Load vs. displacement
    figure('Name','LVDT Displacement vs Load','NumberTitle','off')
    plot(LVDT,Load)
    grid on
    ylabel('Load (N)')
    xlabel('Displacement(mm)')
    % Adjust limits of the plot based on peak load
    xlim([0 LVDT(find(Load==max(Load),1))+0.5]);
end
end

function [Time,TriggerTime,TriggerIndex,Load,LVDT,Pathname] = LabviewLoad
% This subfunction reads the load data produced by the labview virtual
% intrument employed during the experiment.

% Use graphical picking to select the results file after being converted to
% *.xlsx format.
[File,Pathname] = uigetfile('C:\Users\David\Documents\MSU Research\Doctoral Work\Mechanical Testing\Radiation Recrystallization\PhD Work\*.xlsx','Choose the Excel file');
xlsfile = fullfile(Pathname,File);
Data = xlsread(xlsfile,'untitled');
%Column 1 = Time (s)
%Column 2 = ARAMIS Signal
%Column 3 = Load (V)
%Column 4 = Excitation Voltage
%Column 5 = LVDT (V)

% Place columnar data into column vectors
Time = Data(:,1);
Trigger = Data(:,2);
RawLoad = Data(:,3);
Excit = Data(:,4);
RawLVDT = Data(:,5);

% Calculate Trigger Time
i = 1;
while Trigger(i) < 0.5
    i = i+1;
end
TriggerTime = Time(i);
TriggerIndex = i;

%Clip data so the system trigger is the zero point.
Time(1:TriggerIndex) = [];
Time = Time-TriggerTime;
RawLoad(1:TriggerIndex) = [];
RawLVDT(1:TriggerIndex) = [];
Excit(1:TriggerIndex) = [];

% Preallocate calibration factor vectors
CalibFactorLoad = zeros(length(Excit),1);
CalibFactorLVDT = zeros(length(Excit),1);

% Calculate appropriate calibration factors that rely on the excitation
% voltage of the instrument.  This data is logged such that the calibration
% factors can be adjusted on the fly should the excitation voltage
% fluctuate during the experiment.
for i=1:length(Excit)
    CalibFactorLoad(i,1) = (444.822162/(0.003*Excit(i)))';
    CalibFactorLVDT(i,1) = 30/Excit(i);
end


% Calibrate the Load Data
CalibLoad = smooth(-RawLoad.*CalibFactorLoad,50);
MaxLoadIndex = find(CalibLoad == max(CalibLoad));
minLoad = min(CalibLoad(1:MaxLoadIndex));
Load = CalibLoad - minLoad;

% Calibrate the LVDT Data
CalibLVDT = smooth(RawLVDT.*CalibFactorLVDT,50);
minLVDT = min(CalibLVDT);
LVDT = CalibLVDT - minLVDT;
end

function [Stage,Timems,major,minor,epsX,epsY,epsXY,d_xum,d_yum] = ARAMIS(Pathname)
%IMPORTFILE Import numeric data from a text file as column vectors.
%   [VARNAME1,STAGE,TIMEMS,MAJOR,MINOR,EPSX,EPSY,EPSXY,D_XUM,D_YUM] =
%   IMPORTFILE(FILENAME) Reads data from text file FILENAME for the default
%   selection.
%
%   [VARNAME1,STAGE,TIMEMS,MAJOR,MINOR,EPSX,EPSY,EPSXY,D_XUM,D_YUM] =
%   IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data from rows STARTROW
%   through ENDROW of text file FILENAME.
%
% Example:
%   [VarName1,Stage,Timems,major,minor,epsX,epsY,epsXY,d_xum,d_yum] =
%   importfile('2013-12-13 Shear Uniform 2D_point0.txt',6, 107);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2014/06/02 15:06:20

%% Initialize variables.
delimiter = ' ';
if nargin<=2
    startRow = 7;
    endRow = inf;
end

%% Graphically Pick File
RootPath = uigetdir(Pathname,'Choose directory with ARAMIS Files');
Files = dir(fullfile(RootPath,'*.txt'));

for i = 1:length(Files)
    filename = fullfile(RootPath,Files(i).name);
    %% Read columns of data as strings:
    % For more information, see the TEXTSCAN documentation.
    formatSpec = '%s%s%s%s%s%s%s%s%s%s%[^\n\r]';
    
    %% Open the text file.
    fileID = fopen(filename,'r');
    
    %% Read columns of data according to format string.
    % This call is based on the structure of the file used to generate this
    % code. If an error occurs for a different file, try regenerating the code
    % from the Import Tool.
    textscan(fileID, '%[^\n\r]', startRow(1)-1, 'ReturnOnError', false);
    dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'ReturnOnError', false);
    for block=2:length(startRow)
        frewind(fileID);
        textscan(fileID, '%[^\n\r]', startRow(block)-1, 'ReturnOnError', false);
        dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'ReturnOnError', false);
        for col=1:length(dataArray)
            dataArray{col} = [dataArray{col};dataArrayBlock{col}];
        end
    end
    
    %% Close the text file.
    fclose(fileID);
    
    %% Convert the contents of columns containing numeric strings to numbers.
    % Replace non-numeric strings with NaN.
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));
    
    for col=[1,2,3,4,5,6,7,8,9]
        % Converts strings in the input cell array to numbers. Replaced non-numeric
        % strings with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1);
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData{row}, regexstr, 'names');
                numbers = result.numbers;
                
                % Detected commas in non-thousand locations.
                invalidThousandsSeparator = false;
                if any(numbers==',');
                    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                    if isempty(regexp(thousandsRegExp, ',', 'once'));
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % Convert numeric strings to numbers.
                if ~invalidThousandsSeparator;
                    numbers = textscan(strrep(numbers, ',', ''), '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch me
            end
        end
    end
    
    %% Split data into numeric and cell columns.
    rawNumericColumns = raw(:, [1,2,3,4,5,6,7,8,9]);
    % rawCellColumns = raw(:, 10);
    
    
    %% Replace non-numeric cells with NaN
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
    rawNumericColumns(R) = {NaN}; % Replace non-numeric cells
    
    %% Allocate imported array to column variable names
    % VarName1 = cell2mat(rawNumericColumns(:, 1));
    Stage{i} = cell2mat(rawNumericColumns(:, 1));
    Timems{i} = cell2mat(rawNumericColumns(:, 2))%*1000;
    major{i} = cell2mat(rawNumericColumns(:, 3));
    minor{i} = cell2mat(rawNumericColumns(:, 4));
    epsX{i} = cell2mat(rawNumericColumns(:, 5));
    epsY{i} = cell2mat(rawNumericColumns(:, 6));
    epsXY{i} = cell2mat(rawNumericColumns(:, 7));
    d_xum{i} = cell2mat(rawNumericColumns(:, 8));
    d_yum{i} = cell2mat(rawNumericColumns(:, 9));
    % d_yum = rawCellColumns(:, 1);
end
end