clc
clear all
%File = '2012-06-22_Compress_-13C-SH.xlsx';
%Pathname = 'C:\Users\David Walters\Documents\MSU Research\Doctoral Work\Mechanical Testing\Surface Hoar\2012-06-18_Compression\Surface Hoar -13C\';
[File,Pathname,Index] = uigetfile('C:\Doctoral Researach\Mechanical Testing\Radiation Recrystallization\Experiments\*.xlsx','Choose the Excel file');
path(path,Pathname);
Data = xlsread(File,'untitled');
    %Column 1 = Time (s)
    %Column 2 = ARAMIS Signal
    %Column 3 = Load (V)
    %Column 4 = Excitation Voltage
   
Time = Data(:,1);
RawLoad = Data(:,3);
Excit = Data(:,4);

for i=1:length(Excit)
    CalibFactor(i,1) = (444.822162/(0.003*Excit(i)))';
end
Load = RawLoad.*CalibFactor;
minLoad = max(Load);
zeroedLoad = Load - minLoad;

Disp = Time*100;

figure
cfig = get(gcf,'color');
ax(1)=gca;
h = get(ax(1),'Position');
set(ax(1),'Position',[h(1) h(2)+.1 h(3) h(4)-.1])
% set(ax(1),'XColor','k','YColor','k');

h2 = [h(1) h(2) h(3) h(4)];
ax(2)=axes('Position',h2,...
   'XAxisLocation','bottom',...
   'YAxisLocation','left',...
   'Color','none',...
   'XColor','r','YColor','k');
xlabel('Displacement (\mum)')
set(ax(1),'XLim',[min(Time) max(Time)]);
set(ax(2),'XLim',[min(Disp) max(Disp)]);
set(ax(2),'YTick',[])
line([get(ax(1),'xlim') get(ax(1),'xlim')],[(get(ax(2),'ylim')*2) get(ax(1),'ylim')],...
   'Color',cfig,'Parent',ax(2),'Clipping','off');
axes(ax(1));
% subplot(2,1,1)
plot(Time,zeroedLoad,'b')
xlabel('Time (s)')
ylabel('Load (N)')
title('Load vs. Time')
grid on
xLimMan = input('\nKeep auto-x scale limits, yes(1) or no(0)?\n');
if xLimMan == 0
    xLims = input('\nManually enter time limits ([min max])\n');
    set(ax(1),'XLim',[xLims(1) xLims(2)]);
    set(ax(2),'XLim',([xLims(1) xLims(2)]*100));
    
    line([get(ax(1),'xlim') get(ax(1),'xlim')],[(get(ax(2),'ylim')*2) get(ax(1),'ylim')],...
   'Color',cfig,'Parent',ax(2),'Clipping','off');
    axes(ax(1));
end


%set(ax,'box','off')
% 
% subplot(2,1,2)
% plot(Disp,zeroedLoad,'r')
% xlabel('Displacement (\mum)')
% ylabel('Load (N)')
% title('Load vs. Displacement')
% if xLimMan == 0
%     xlim(xLims*100);
% end
% grid on



