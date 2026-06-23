classdef Radartestapp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure        matlab.ui.Figure
        AngleButton     matlab.ui.control.Button
        DistanceButton  matlab.ui.control.Button
        RadarButton     matlab.ui.control.Button
        StopButton      matlab.ui.control.Button
        StartButton     matlab.ui.control.Button
        SpectrumAxes    matlab.ui.control.UIAxes
        RadarPolarAxes  matlab.ui.control.UIAxes
        AngleAxes       matlab.ui.control.UIAxes
        DistanceAxes    matlab.ui.control.UIAxes
    end

properties (Access = private)
    s = []
    running = false

    angles = []
    distances = []
    timeData = []
    t0

    hRadar
    hDist
    hDistFiltered
    hSpectrum
    hAngle
    hDistLegend
end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
app.running = false;

   % Distance plot: raw + filtered
    app.hDist = plot(app.DistanceAxes, 0, 0);
    hold(app.DistanceAxes, "on");
    app.hDistFiltered = plot(app.DistanceAxes, 0, 0, "LineWidth", 1.5);

    grid(app.DistanceAxes, "on");
    xlabel(app.DistanceAxes, "Time (s)");
    ylabel(app.DistanceAxes, "Distance (mm)");
    title(app.DistanceAxes, "Raw and Filtered Distance");
    app.hDistLegend = legend(app.DistanceAxes, "Raw", "Filtered");
    ylim(app.DistanceAxes, [0 1000]);

    % Spectrum plot
    app.hSpectrum = plot(app.SpectrumAxes, 0, 0);
    grid(app.SpectrumAxes, "on");
    xlabel(app.SpectrumAxes, "Frequency (Hz)");
    ylabel(app.SpectrumAxes, "Magnitude");
    title(app.SpectrumAxes, "First 10 Seconds Spectrum");
    xlim(app.SpectrumAxes, [0 10]);

    % Angle plot
    app.hAngle = plot(app.AngleAxes, 0, 0);
    grid(app.AngleAxes, "on");
    xlabel(app.AngleAxes, "Time (s)");
    ylabel(app.AngleAxes, "Angle (deg)");
    title(app.AngleAxes, "Live Servo Angle");
    ylim(app.AngleAxes, [0 180]);

    % Radar map using normal UIAxes
    cla(app.RadarPolarAxes);
    hold(app.RadarPolarAxes, "on");
    grid(app.RadarPolarAxes, "on");
    axis(app.RadarPolarAxes, "equal");

    xlim(app.RadarPolarAxes, [-1000 1000]);
    ylim(app.RadarPolarAxes, [0 1000]);

    xlabel(app.RadarPolarAxes, "X distance (mm)");
    ylabel(app.RadarPolarAxes, "Y distance (mm)");
    title(app.RadarPolarAxes, "Live Radar Map");

    % Draw semicircle radar grid
    thetaGrid = deg2rad(0:1:180);

    for r = 200:200:1000
        xGrid = r * cos(thetaGrid);
        yGrid = r * sin(thetaGrid);
        plot(app.RadarPolarAxes, xGrid, yGrid, "Color", [0.5 0.5 0.5]);
    end

    % Draw angle lines
    for angle = 0:30:180
        theta = deg2rad(angle);
        xLine = [0 1000*cos(theta)];
        yLine = [0 1000*sin(theta)];
        plot(app.RadarPolarAxes, xLine, yLine, "Color", [0.5 0.5 0.5]);
    end

    % Live radar points
    app.hRadar = plot(app.RadarPolarAxes, 0, 0, ".", "MarkerSize", 12);


    app.RadarPolarAxes.Visible = "off";
    set(app.RadarPolarAxes.Children, "Visible", "off");

    app.DistanceAxes.Visible = "off";
    set(app.DistanceAxes.Children, "Visible", "off");
    app.hDistLegend.Visible = "off";

    app.SpectrumAxes.Visible = "off";
    set(app.SpectrumAxes.Children, "Visible", "off");

    app.AngleAxes.Visible = "off";
    set(app.AngleAxes.Children, "Visible", "off");
        end

        % Button pushed function: StartButton
        function StartButtonButtonPushed(app, event)
        
    if app.running
    return;
    end

    app.running = true;

    port = "COM3";
    baud = 115200;

    if ~isempty(app.s)
    delete(app.s);
    app.s = [];
    end

    app.s = serialport(port, baud);
    configureTerminator(app.s, "LF");
    app.s.Timeout = 0.2;
    flush(app.s);

    writeline(app.s, "START");
    pause(0.2);

    app.angles = [];
    app.distances = [];
    app.timeData = [];
    app.t0 = datetime("now");

    % Reset live plots
    set(app.hRadar, "XData", 0);
    set(app.hRadar, "YData", 0);

    set(app.hDist, "XData", 0);
    set(app.hDist, "YData", 0);

    set(app.hAngle, "XData", 0);
    set(app.hAngle, "YData", 0);

   while app.running
    try
        line = readline(app.s);
    catch
        break;
    end
    disp(line)
disp(class(line))    
    tokens = regexp(line, "Angle:\s*(\d+)\s*\|\s*Distance:\s*(\d+)", "tokens");

        if ~isempty(tokens)
            angle = str2double(tokens{1}{1});
            distance = str2double(tokens{1}{2});
            t = seconds(datetime("now") - app.t0);

            app.angles(end+1) = deg2rad(angle);
            app.distances(end+1) = distance;
            app.timeData(end+1) = t;

            if numel(app.angles) > 300
                app.angles = app.angles(end-300:end);
                app.distances = app.distances(end-300:end);
                app.timeData = app.timeData(end-300:end);
            end

            % Update radar map
            x = app.distances .* cos(app.angles);
            y = app.distances .* sin(app.angles);

            set(app.hRadar, "XData", x);
            set(app.hRadar, "YData", y);

            % Update distance graph
            set(app.hDist, "XData", app.timeData);
            set(app.hDist, "YData", app.distances);

            % Moving average filter
            filteredDistance = movmean(app.distances, 5);

            set(app.hDistFiltered, "XData", app.timeData);
            set(app.hDistFiltered, "YData", filteredDistance);

            % FFT of first 10 seconds
            idx10 = app.timeData <= 10;

            if sum(idx10) > 10
            xFFT = app.distances(idx10);
            tFFT = app.timeData(idx10);

            % Remove DC offset
            xFFT = xFFT - mean(xFFT);

            % Estimate sampling frequency from real time data
            Fs = 1 / mean(diff(tFFT));

            N = length(xFFT);

            Y = fft(xFFT);
            P2 = abs(Y / N);
            P1 = P2(1:floor(N/2)+1);
            P1(2:end-1) = 2 * P1(2:end-1);

            f = Fs * (0:floor(N/2)) / N;

            set(app.hSpectrum, "XData", f);
            set(app.hSpectrum, "YData", P1);
            end

            % Update angle graph
            set(app.hAngle, "XData", app.timeData);
            set(app.hAngle, "YData", rad2deg(app.angles));

            drawnow;
        end
   end
   if ~isempty(app.s)
    try
        delete(app.s);
    catch
    end
    app.s = [];
    end
        end

        % Button pushed function: StopButton
        function StopButtonButtonPushed(app, event)
   app.running = false;

if ~isempty(app.s)
    try
        writeline(app.s, "STOP");
    catch
    end
end
        end

        % Button down function: RadarPolarAxes
        function Radar(app, event)
            
        end

        % Button pushed function: RadarButton
        function RadarButtonPushed(app, event)
          % Show radar
app.RadarPolarAxes.Visible = "on";
set(app.RadarPolarAxes.Children, "Visible", "on");

% Hide distance
app.DistanceAxes.Visible = "off";
app.hDistLegend.Visible = "off";
set(app.DistanceAxes.Children, "Visible", "off");

% Hide spectrum
app.SpectrumAxes.Visible = "off";
set(app.SpectrumAxes.Children, "Visible", "off");

% Hide angle
app.AngleAxes.Visible = "off";
set(app.AngleAxes.Children, "Visible", "off");
        end

        % Button pushed function: DistanceButton
        function DistanceButtonPushed(app, event)
         % Hide radar
app.RadarPolarAxes.Visible = "off";
set(app.RadarPolarAxes.Children, "Visible", "off");

% Show distance graph
app.DistanceAxes.Visible = "on";
app.hDistLegend.Visible = "on";
set(app.DistanceAxes.Children, "Visible", "on");

% Show spectrum graph
app.SpectrumAxes.Visible = "on";
set(app.SpectrumAxes.Children, "Visible", "on");

% Hide angle graph
app.AngleAxes.Visible = "off";
set(app.AngleAxes.Children, "Visible", "off");
        end

        % Button pushed function: AngleButton
        function AngleButtonPushed(app, event)
  % Hide radar
app.RadarPolarAxes.Visible = "off";
set(app.RadarPolarAxes.Children, "Visible", "off");

% Hide distance
app.DistanceAxes.Visible = "off";
app.hDistLegend.Visible = "off";
set(app.DistanceAxes.Children, "Visible", "off");

% Hide spectrum
app.SpectrumAxes.Visible = "off";
set(app.SpectrumAxes.Children, "Visible", "off");

% Show angle
app.AngleAxes.Visible = "on";
set(app.AngleAxes.Children, "Visible", "on");
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 667 758];
            app.UIFigure.Name = 'MATLAB App';

            % Create DistanceAxes
            app.DistanceAxes = uiaxes(app.UIFigure);
            title(app.DistanceAxes, 'Title')
            xlabel(app.DistanceAxes, 'X')
            ylabel(app.DistanceAxes, 'Y')
            zlabel(app.DistanceAxes, 'Z')
            app.DistanceAxes.Position = [190 417 300 185];

            % Create AngleAxes
            app.AngleAxes = uiaxes(app.UIFigure);
            title(app.AngleAxes, 'Title')
            xlabel(app.AngleAxes, 'X')
            ylabel(app.AngleAxes, 'Y')
            zlabel(app.AngleAxes, 'Z')
            app.AngleAxes.Position = [191 417 300 185];

            % Create RadarPolarAxes
            app.RadarPolarAxes = uiaxes(app.UIFigure);
            title(app.RadarPolarAxes, 'Title')
            xlabel(app.RadarPolarAxes, 'X')
            ylabel(app.RadarPolarAxes, 'Y')
            zlabel(app.RadarPolarAxes, 'Z')
            app.RadarPolarAxes.ButtonDownFcn = createCallbackFcn(app, @Radar, true);
            app.RadarPolarAxes.Position = [189 417 300 185];

            % Create SpectrumAxes
            app.SpectrumAxes = uiaxes(app.UIFigure);
            title(app.SpectrumAxes, 'Title')
            xlabel(app.SpectrumAxes, 'X')
            ylabel(app.SpectrumAxes, 'Y')
            zlabel(app.SpectrumAxes, 'Z')
            app.SpectrumAxes.Position = [186 191 300 185];

            % Create StartButton
            app.StartButton = uibutton(app.UIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonButtonPushed, true);
            app.StartButton.Position = [26 695 100 23];
            app.StartButton.Text = 'Start';

            % Create StopButton
            app.StopButton = uibutton(app.UIFigure, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonButtonPushed, true);
            app.StopButton.Position = [546 694 100 23];
            app.StopButton.Text = 'Stop';

            % Create RadarButton
            app.RadarButton = uibutton(app.UIFigure, 'push');
            app.RadarButton.ButtonPushedFcn = createCallbackFcn(app, @RadarButtonPushed, true);
            app.RadarButton.Position = [27 611 100 23];
            app.RadarButton.Text = 'Radar Button';

            % Create DistanceButton
            app.DistanceButton = uibutton(app.UIFigure, 'push');
            app.DistanceButton.ButtonPushedFcn = createCallbackFcn(app, @DistanceButtonPushed, true);
            app.DistanceButton.Position = [286 611 100 23];
            app.DistanceButton.Text = 'Distance Button';

            % Create AngleButton
            app.AngleButton = uibutton(app.UIFigure, 'push');
            app.AngleButton.ButtonPushedFcn = createCallbackFcn(app, @AngleButtonPushed, true);
            app.AngleButton.Position = [547 611 100 23];
            app.AngleButton.Text = 'Angle Button';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Radartestapp_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end