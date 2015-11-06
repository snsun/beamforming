function collectPoints

xPos = [];
yPos = [];
w = [];
f = 1e3;
c = 340;
fs = 44.1e3;
thetaArrivalAngles = 0;
phiArrivalAngles = 0;
thetaScanningAngles = -90:0.1:90;
phiScanningAngles = 0;


% Create figure and axes
fig = figure;

%Axis for geometry
axArray = subplot(211);
axArray.XLim = [-1 1]*0.6;
axArray.YLim = [-1 1]*0.6;
axArray.ButtonDownFcn = {@drawPoint};
hold(axArray, 'on');
box(axArray, 'on')
axArray.XTick = [-1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1];
axArray.YTick = [-1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1];
grid(axArray, 'on')
grid(axArray,'minor')
title(axArray,'Microphone positions', 'fontweight', 'normal');

%Axis for beampattern
axResponse = subplot(212);
box(axResponse, 'on')
title(axResponse,['Beampattern @ ' sprintf('%0.2f', f*1e-3) ' kHz'],'fontweight','normal');
xlabel(axResponse, '\theta');
ylabel(axResponse, 'dB');
axResponse.XLim = [thetaScanningAngles(1) thetaScanningAngles(end)];
axResponse.YLim = [-40 1];
hold(axResponse, 'on');
grid(axResponse, 'on')
grid(axResponse,'minor')
axResponse.NextPlot = 'replacechildren';


%Add frequency slider
frequencySlider = uicontrol('style', 'slider', ...
    'Units', 'normalized',...
    'position', [0.93 0.1 0.03 0.35],...
    'value', f,...
    'min', 0.1e3,...
    'max', 20e3);
addlistener(frequencySlider, 'ContinuousValueChange', @(obj,evt) changeFrequencyOfSource(obj, evt, obj.Value) );
addlistener(frequencySlider,'ContinuousValueChange',@(obj,evt) title(axResponse, ['Beampattern @ ' sprintf('%0.2f', obj.Value*1e-3) ' kHz'],'fontweight','normal'));

%Add context menu to geometry
cmFigure = uicontextmenu;
uimenu('Parent',cmFigure,'Label','Nor848A-4', 'Callback', { @changeArray });
uimenu('Parent',cmFigure,'Label','Nor848A-10', 'Callback', { @changeArray });
uimenu('Parent',cmFigure,'Label','Clear all', 'Callback', { @clearFigure });
axArray.UIContextMenu = cmFigure;


    function drawPoint(obj, eventData)
        %Don't draw a point on right click
        if strcmp(obj.Parent.SelectionType,'alt')

        else
            plot(axArray,eventData.IntersectionPoint(1),...
                eventData.IntersectionPoint(2),'Marker','.','Color',[0 0.4470 0.7410],...
                'MarkerSize',15);
                      
            xPos = [xPos eventData.IntersectionPoint(1)];
            yPos = [yPos eventData.IntersectionPoint(2)];
            
            w = ones(1, numel(xPos))/numel(xPos);
            plotBeampattern1D(w)
        end
    end

    function changeFrequencyOfSource(~, ~, clickedFrequency)
        f = clickedFrequency;
        plotBeampattern1D(w)
    end

    function plotBeampattern1D(w)
        
        inputSignal = createSignal(xPos, yPos, f, c, fs, thetaArrivalAngles, phiArrivalAngles);
        S = steeredResponseDelayAndSum(xPos, yPos, w, inputSignal, f, c,...
            thetaScanningAngles, phiScanningAngles);
        
        spectrumLog = 10*log10(abs(S)/max(abs(S)));
        plot(axResponse, thetaScanningAngles, spectrumLog)
    end

    function clearFigure(~, ~)
        cla(axArray)
        cla(axResponse)
        xPos = [];
        yPos = [];
    end

    function changeArray(object, eventdata)
        clearFigure
        array = load(['data/arrays/' object.Label '.mat']);
        xPos = array.xPos;
        yPos = array.yPos;
        w = array.hiResWeights;
        plot(axArray,xPos,yPos,'.','Color',[0 0.4470 0.7410],...
            'MarkerSize',10);
        plotBeampattern1D(w)
    end

end


