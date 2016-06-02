% Script saves all open figure windows to 3 file formats to the directory
% specified by the user.  (3 formats: .fig, .emf, .png)
hfigs = get(0,'children');  %Get list of figures

LocalPath = 'C:\Users\David\OneDrive\Doctoral Work\Dissertation\Figures\Mechanical Experiment Results\';
directory = uigetdir(LocalPath,...
            'Select  directory to save plots');
DataPath = fullfile(directory,'ModulusData');
save(DataPath)

for i = 1:length(hfigs)
    % Set figure size and position on screen
    figure(hfigs(i))
    %     ax = gca;
    %     set(ax,'XTickMode','manual');
    %     set(ax,'YTickMode','manual');
    %     set(ax,'YTickMode','manual');
    set(hfigs(i),'PaperUnits','inches')
    set(hfigs(i),'PaperPosition',[3,3,6,3.5])
    set(hfigs(i),'PaperPositionMode','manual')
    %     set(hfigs(i),'PaperSize',[6,3.5])
    h = get(hfigs(i),'children');
    hLeg = [];
    for k = 1:length(h)
        if strcmpi(get(h(k),'Tag'),'legend')
            hLeg = h(k);
            break;
        end
    end
%     set(hLeg, 'Location', 'west')
%     set(hLeg, 'Location','south')
end
for i = 1:length(hfigs)
    figure(hfigs(i))        %Bring figure to foreground
    
    filename = get(gcf,'name'); %Get window title for filename
    % If no special window title specified, give generic filename
    if isempty(filename)
        fname = sprintf('Figure %2.0f',i);
        filename = fname;
    end
    FilePath = fullfile(directory,filename);
    % Save figures to specified path
    print(hfigs(i),FilePath,'-dpng','-r300');
    saveas(hfigs(i),FilePath,'fig');
    print(hfigs(i),FilePath,'-dmeta');
    
end
