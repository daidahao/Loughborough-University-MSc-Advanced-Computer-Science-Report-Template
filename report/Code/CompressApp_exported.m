classdef CompressApp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        ImageCompressionSimulationUIFigure  matlab.ui.Figure
        FileMenu                        matlab.ui.container.Menu
        OpenMenu                        matlab.ui.container.Menu
        ReloadMenu                      matlab.ui.container.Menu
        ActionMenu                      matlab.ui.container.Menu
        IncreaseKMenu                   matlab.ui.container.Menu
        DecreaseKMenu                   matlab.ui.container.Menu
        CompressMenu                    matlab.ui.container.Menu
        QuantizationTableMenu           matlab.ui.container.Menu
        VideoMenu                       matlab.ui.container.Menu
        OriginalVideoMenu               matlab.ui.container.Menu
        CompressVideoMenu               matlab.ui.container.Menu
        SaveVideoMenu                   matlab.ui.container.Menu
        GridLayout                      matlab.ui.container.GridLayout
        LeftPanel                       matlab.ui.container.Panel
        LeftGridLayout                  matlab.ui.container.GridLayout
        LeftAxes                        matlab.ui.control.UIAxes
        MiddlePanel                     matlab.ui.container.Panel
        MiddleGridLayout                matlab.ui.container.GridLayout
        MiddleAxes                      matlab.ui.control.UIAxes
        RightPanel                      matlab.ui.container.Panel
        GridLayout2                     matlab.ui.container.GridLayout
        Slider                          matlab.ui.control.Slider
        PleaseselectaJPGorBMPfileLabel  matlab.ui.control.Label
        GridLayout3                     matlab.ui.container.GridLayout
        KValueLabel                     matlab.ui.control.Label
        EditField                       matlab.ui.control.NumericEditField
        CompressButton                  matlab.ui.control.Button
        SavetoFileButton                matlab.ui.control.Button
        GridLayout4                     matlab.ui.container.GridLayout
        OpenButton                      matlab.ui.control.Button
        ReloadButton                    matlab.ui.control.Button
        QuantizationTableButton         matlab.ui.control.Button
        DropDown                        matlab.ui.control.DropDown
        VideoGridLayout                 matlab.ui.container.GridLayout
        OriginalVideoButton             matlab.ui.control.Button
        CompressVideoButton             matlab.ui.control.Button
        SaveVideoButton                 matlab.ui.control.Button
        VideoSlider                     matlab.ui.control.Slider
    end

    
    properties (Access = private)
        currentImage % Current Image
        compressedImage % Compressed Image
        kValue % Value of K
        kValueStep = 0.1 % Increae/Decrease Step of K
        kValueDefault = 1 % Default Value of K
        kValueMax = 1000 % Maximum Value of K
        kValueMin = 0.001 % Minimum Value of K
        qTableApp % qTable App
        currentPath % Current Path of Image Files
        currentVideo % Current Video (if any)
        currentFullpath % Current Full Path of File
        compressedVideoFullPath = fullfile('cache', 'compressed.avi');
        % Full Path of Generated Compressed Video
        originalVideoFullPath = fullfile('cache', 'original.avi');
        % Full Path of Generated Original Video
    end
    
    properties (Access = public)
        defaultQTable = [16, 11, 10, 16, 24, 40, 51, 61;
        12, 12, 14, 19, 26, 58, 60, 55;
        14, 13, 16, 24, 40, 57, 69, 56;
        14, 17, 22, 29, 51, 87, 80, 62;
        18, 22, 37, 56, 68, 109, 103, 77;
        24, 35, 55, 64, 81, 104, 113, 92;
        49, 64, 78, 87, 103, 121, 120, 101;
        72, 92, 95, 98, 112, 100, 103, 99] 
        % Default Quantization Table (qTable)
        qTable % Quantization Table (qTable) at Runtime
    end
    
    methods (Access = private)
        
        function himage = showImage(~, image, axes)
            % Show image on the given axes.
            himage = imshow(image, 'Border', 'tight', 'Parent', axes);
            axes.XLim = [0, himage.XData(2)];
            axes.YLim = [0, himage.YData(2)];
        end
        
        function initImage(app, currentImage)
            % Save image as currentImage and display it
            % on left axes.
            app.currentImage = currentImage;
            showImage(app, app.currentImage, app.LeftAxes);
        end
        
        function resetKValue(app)
            % Reset K Value.
            app.kValue = app.kValueDefault;
            app.EditField.Value = app.kValue;
            app.Slider.Value = log10(app.kValue);
        end
        
        function listImageFiles(app, path, name)
            % List all image files under the current path
            % on the dropdown menu.
            app.currentPath = path;
            files = dir(app.currentPath);
            app.DropDown.Items = {};
            count = 0;
            for i = 1:size(files, 1)
                if ~(files(i).isdir) && ...
                    (contains(files(i).name, 'jpg') || ...
                    contains(files(i).name, 'jpeg') || ...
                    contains(files(i).name, 'bmp') || ...
                    contains(files(i).name, 'mp4')) 
                    count = count + 1;
                    app.DropDown.Items{count} = files(i).name;
                end
            end
            app.DropDown.Value = name;
        end
        
        function image = readFile(app, path, file)
            % Read image from the given path and filename.
            % If the file is a video, display the video slider
            % and return the first frame. Save the VideoReader
            % object as currentVideo.
            % Otherwise, hide the video slider and return the
            % image.
            app.currentFullpath = fullfile(path, file);
            if endsWith(file, '.mp4')
                    app.currentVideo = VideoReader(fullfile(path, file));
                    app.VideoSlider.Limits = [0, app.currentVideo.Duration];
                    app.VideoSlider.MajorTicks = [0:60:app.currentVideo.Duration, ...
                                                app.currentVideo.Duration];
                    app.VideoSlider.MajorTickLabels = ...
                        string(datestr(app.VideoSlider.MajorTicks/24/3600, 'MM:SS'));
                    app.VideoSlider.MinorTicks = 0:10:app.currentVideo.Duration;
                    app.VideoSlider.Value = 0;
                    app.GridLayout.RowHeight(8) = {50};
                    app.VideoGridLayout.Visible = 'on';
                    app.VideoMenu.Enable = 'on';
                    app.SaveVideoButton.Enable = 'off';
                    image = app.readStillFrame(app.currentVideo);
                else
                    app.GridLayout.RowHeight(8) = {0};
                    image = imread(fullfile(path, file));
                    app.VideoGridLayout.Visible = 'off';
                    app.VideoMenu.Enable = 'off';
            end
        end
        
        function [video, count] = readVideo(app, numOfFrames)
            % Read given number of frames from the video.
            previousTime = app.currentVideo.CurrentTime;
            count = 0;
            channel = 3;
            while hasFrame(app.currentVideo)
                frame = readFrame(app.currentVideo);
                count = count + 1;
                if count > numOfFrames
                    count = numOfFrames;
                    break;
                end
                video(:, :, channel*(count-1)+1:channel*count) = frame;
            end
            app.currentVideo.CurrentTime = previousTime;
        end
        
        function numOfFrames = getMaxNumOfFrames(app)
            % Get the maxmum number of frames left from "currentTime" of 
            % the video.
            numOfFrames = floor(app.currentVideo.FrameRate * ...
                min(3, app.currentVideo.Duration - app.currentVideo.CurrentTime));
        end
        
        function writeVideoToFile(~, fullpath, video, framesCount, button)
            % Write the video matrix into a filepath using VideoWriter.
            compressedVW = VideoWriter(fullpath, 'Uncompressed AVI');
            open(compressedVW);
            channel = 3;
            previousPercentage = 0;
            for i = 1:framesCount
                percentage = floor(i / framesCount * 100 / 2);
                if percentage > previousPercentage + 10
                    button.Text = sprintf("%d%%", percentage);
                    previousPercentage = percentage;
                end
                writeVideo(compressedVW, video(:, :, channel*(i-1)+1:channel*i));
            end
            close(compressedVW);
        end
        
        function frame = readStillFrame(~, video)
            % Read a frame from the video without changing the current
            % time.
            previousTime = video.CurrentTime;
            frame = readFrame(video);
            video.CurrentTime = previousTime;
        end
    end
    
    methods (Access = public)
        
        function compressAndShow(app)
            % Compress currentImage into compressedImage, 
            % show it on the middle axes.
            app.compressedImage = py.matlab.compress( ...
                app.currentImage(:), ...
                int32([size(app.currentImage,1), ...
                    size(app.currentImage,2), ...
                    size(app.currentImage,3)]), ...
                app.kValue, app.qTable(:));
            app.compressedImage = uint8(app.compressedImage);
            showImage(app, app.compressedImage, app.MiddleAxes);
        end
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Set up Python Environment
            % pyversion('/Users/dahao/anaconda3/bin/python');
            
            % Load Python Interface
            mod = py.importlib.import_module('matlab');
            py.importlib.reload(mod);
            % Generate a default image.
            image = uint8(ones(200, 200, 3) * 255);
            % Reset K value and Quantization Table.
            resetKValue(app);
            app.qTable = app.defaultQTable;
            % Show the default image on left axes.
            initImage(app, image);
            % Compress and show the image.
            compressAndShow(app);
            % Hide VideoGridLayout
            app.VideoGridLayout.Visible = 'off';
        end

        % Value changing function: Slider
        function SliderValueChanging(app, event)
            changingValue = event.Value;
            % Change K Value in EditField simultaneously
            app.EditField.Value = 10^changingValue;
        end

        % Value changed function: Slider
        function SliderValueChanged(app, event)
            value = app.Slider.Value;
            % Change K Value in EditField simultaneously
            app.kValue = 10^value;
            app.EditField.Value = app.kValue;
            % Compress and show the image.
            compressAndShow(app);
        end

        % Callback function: OpenButton, OpenMenu
        function OpenButtonPushed(app, event)
            % Open a file selector.
            [file, path] = uigetfile( ...
                {'*.jpg;*.jpeg;*.bmp;*.mp4', ...
                'Image or Video Files (*.jpg,*.jpeg,*.bmp,*.mp4)'; ...
                '*.jpg;*.jpeg;*.bmp', ...
                'Image Files (*.jpg,*.jpeg,*.bmp)'; ...
                '*.mp4', 'MPEG-4 Video Files (*.mp4)'}, ...
                'Image / Video Selector');
            if ~isequal(file, 0)
                % If a file is selected, read a image from the file.
                image = readFile(app, path, file);
                % List all image files under the same folder on dropdown
                % menu.
                listImageFiles(app, path, file);
                % Show image on the left axes.
                initImage(app, image);
                % Reset K value.
                resetKValue(app);
                % Change Label Text to filename.
                app.PleaseselectaJPGorBMPfileLabel.Text = file;
                app.PleaseselectaJPGorBMPfileLabel.FontWeight = 'bold';
                % Compress and show the image.
                compressAndShow(app);
            end
        end

        % Value changed function: EditField
        function EditFieldValueChanged(app, event)
            value = app.EditField.Value;
            % Change K Value in Slider simultaneously
            app.Slider.Value = log10(value);
            app.kValue = value;
            % Compress and show the image.
            compressAndShow(app);
        end

        % Callback function: CompressButton, CompressMenu
        function CompressButtonPushed(app, event)
            % Compress and show the image.
            compressAndShow(app);
        end

        % Button pushed function: SavetoFileButton
        function SavetoFileButtonPushed(app, event)
            image = app.compressedImage;
            uisave({'image'});
        end

        % Callback function: ReloadButton, ReloadMenu
        function ReloadButtonPushed(app, event)
            % Reset K Value.
            resetKValue(app);
            % Re-show the original and compressed image.
            initImage(app, app.currentImage);
            compressAndShow(app);
        end

        % Menu selected function: IncreaseKMenu
        function IncreaseKMenuSelected(app, event)
            % Increase K Value.
            app.kValue = min(app.kValue * (10^app.kValueStep), app.kValueMax);
            app.Slider.Value = log10(app.kValue);
            app.EditField.Value = app.kValue;
            compressAndShow(app);
        end

        % Menu selected function: DecreaseKMenu
        function DecreaseKMenuSelected(app, event)
            % Decrease K Value.
            app.kValue = max(app.kValue / (10^app.kValueStep), app.kValueMin);
            app.Slider.Value = log10(app.kValue);
            app.EditField.Value = app.kValue;
            compressAndShow(app);
        end

        % Callback function: QuantizationTableButton, 
        % QuantizationTableMenu
        function QuantizationTableButtonPushed(app, event)
            % Modify the quantization table by calling QTable APP.
            app.QuantizationTableButton.Enable = 'off';
            app.qTableApp = QTable(app, app.qTable);
        end

        % Close request function: ImageCompressionSimulationUIFigure
        function ImageCompressionSimulationUIFigureCloseRequest(app, event)
            % Delete qTableApp before closing.
            delete(app.qTableApp);
            delete(app);
        end

        % Value changed function: DropDown
        function DropDownValueChanged(app, event)
            % Read image from the selected filename.
            filename = app.DropDown.Value;
            image = readFile(app, app.currentPath, filename);
            % Show the original and compressed image.
            initImage(app, image);
            compressAndShow(app);
            % Change the filename label.
            app.PleaseselectaJPGorBMPfileLabel.Text = filename;
            app.PleaseselectaJPGorBMPfileLabel.FontWeight = 'bold';
        end

        % Value changing function: VideoSlider
        function VideoSliderValueChanging(app, event)
            % Change currentVideo currentTime to selected value.
            changingValue = event.Value;
            app.currentVideo.currentTime = changingValue;
            % Read and show the first frame as an image.
            image = app.readStillFrame(app.currentVideo);
            initImage(app, image);
        end

        % Value changed function: VideoSlider
        function VideoSliderValueChanged(app, event)
            % Change currentVideo currentTime to selected value.
            value = app.VideoSlider.Value;
            app.currentVideo.currentTime = value;
            % Read and show the first frame as an image.
            image = app.readStillFrame(app.currentVideo);
            initImage(app, image);
            % Compress and show the image.
            compressAndShow(app);
        end

        % Callback function: OriginalVideoButton, OriginalVideoMenu
        function OriginalVideoButtonPushed(app, event)
            % Play first 3 seconds of Original Video.
            uialert(app.ImageCompressionSimulationUIFigure, ...
                'To save your time, only the first 3 seconds of video will be displayed.', ...
                'Information', ...
                'Icon', 'info');
            numOfFrames = getMaxNumOfFrames(app);
            [video, framesCount] = readVideo(app, numOfFrames);
            writeVideoToFile(app, app.originalVideoFullPath, ...
                video, framesCount, app.OriginalVideoButton);
            app.OriginalVideoButton.Text = {'Original'; 'Video'};
            implay(app.originalVideoFullPath);
        end

        % Callback function: CompressVideoButton, CompressVideoMenu
        function CompressVideoButtonPushed(app, event)
            % Compress and play first 3 seconds of the video.
            % Disable SaveVideo and CompressVideo Button/Menu.
            app.SaveVideoButton.Enable = 'off';
            app.SaveVideoMenu.Enable = 'off';
            app.CompressVideoButton.Enable = 'off';
            app.CompressVideoMenu.Enable = 'off';
            app.CompressVideoButton.Text = "Reading...";
            
            % Read frames of first 3 seconds of the video.
            numOfFrames = getMaxNumOfFrames(app);
            [video, framesCount] = readVideo(app, numOfFrames);
            uialert(app.ImageCompressionSimulationUIFigure, ...
                'To save your time, only the first 3 seconds of video will be compressed.', ...
                'Information', ...
                'Icon', 'info');
            
            % Compress the video using the Python interface.
            app.CompressVideoButton.Text = "Compressing...";
            video = py.matlab.compress(video(:), ...
                int32([size(video,1), ...
                    size(video,2), ...
                    size(video,3)]), ...
                app.kValue, app.qTable(:));
            video = uint8(video);
            
            % Write video into a tempoary file.
            writeVideoToFile(app, app.compressedVideoFullPath, ...
                video, framesCount, app.CompressVideoButton);
            
            % Play the compressed video.
            implay(app.compressedVideoFullPath);
            
            % Enable SaveVideo and CompressVideo Button/Menu.
            app.CompressVideoButton.Text = 'Complete!';
            pause(1);
            app.CompressVideoButton.Text = {'Compress'; 'Video'};
            app.CompressVideoButton.Enable = 'on';
            app.SaveVideoButton.Enable = 'on';
            app.SaveVideoMenu.Enable = 'on';
        end

        % Callback function: SaveVideoButton, SaveVideoMenu
        function SaveVideoButtonPushed(app, event)
            % Save the compressed video into a selected file.
            [file, path] = uiputfile({'*.avi', 'Uncompressed AVI Files (*.avi)'}, ...
                'Save Video File', ...
                'compressed.avi');
            if ~isequal(file, 0) && ~isequal(path, 0)
                copyfile(app.compressedVideoFullPath, fullfile(path, file));
            end
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create ImageCompressionSimulationUIFigure and hide until all components are created
            app.ImageCompressionSimulationUIFigure = uifigure('Visible', 'off');
            app.ImageCompressionSimulationUIFigure.Position = [100 100 1138 502];
            app.ImageCompressionSimulationUIFigure.Name = 'Image Compression Simulation';
            app.ImageCompressionSimulationUIFigure.CloseRequestFcn = createCallbackFcn(app, @ImageCompressionSimulationUIFigureCloseRequest, true);

            % Create FileMenu
            app.FileMenu = uimenu(app.ImageCompressionSimulationUIFigure);
            app.FileMenu.Text = 'File';

            % Create OpenMenu
            app.OpenMenu = uimenu(app.FileMenu);
            app.OpenMenu.MenuSelectedFcn = createCallbackFcn(app, @OpenButtonPushed, true);
            app.OpenMenu.Accelerator = 'O';
            app.OpenMenu.Text = 'Open';

            % Create ReloadMenu
            app.ReloadMenu = uimenu(app.FileMenu);
            app.ReloadMenu.MenuSelectedFcn = createCallbackFcn(app, @ReloadButtonPushed, true);
            app.ReloadMenu.Accelerator = 'R';
            app.ReloadMenu.Text = 'Reload';

            % Create ActionMenu
            app.ActionMenu = uimenu(app.ImageCompressionSimulationUIFigure);
            app.ActionMenu.Text = 'Action';

            % Create IncreaseKMenu
            app.IncreaseKMenu = uimenu(app.ActionMenu);
            app.IncreaseKMenu.MenuSelectedFcn = createCallbackFcn(app, @IncreaseKMenuSelected, true);
            app.IncreaseKMenu.Accelerator = 'I';
            app.IncreaseKMenu.Text = 'Increase K';

            % Create DecreaseKMenu
            app.DecreaseKMenu = uimenu(app.ActionMenu);
            app.DecreaseKMenu.MenuSelectedFcn = createCallbackFcn(app, @DecreaseKMenuSelected, true);
            app.DecreaseKMenu.Accelerator = 'D';
            app.DecreaseKMenu.Text = 'Decrease K';

            % Create CompressMenu
            app.CompressMenu = uimenu(app.ActionMenu);
            app.CompressMenu.MenuSelectedFcn = createCallbackFcn(app, @CompressButtonPushed, true);
            app.CompressMenu.Accelerator = 'C';
            app.CompressMenu.Text = 'Compress';

            % Create QuantizationTableMenu
            app.QuantizationTableMenu = uimenu(app.ActionMenu);
            app.QuantizationTableMenu.MenuSelectedFcn = createCallbackFcn(app, @QuantizationTableButtonPushed, true);
            app.QuantizationTableMenu.Accelerator = 'Q';
            app.QuantizationTableMenu.Text = 'Quantization Table';

            % Create VideoMenu
            app.VideoMenu = uimenu(app.ImageCompressionSimulationUIFigure);
            app.VideoMenu.Enable = 'off';
            app.VideoMenu.Text = 'Video';

            % Create OriginalVideoMenu
            app.OriginalVideoMenu = uimenu(app.VideoMenu);
            app.OriginalVideoMenu.MenuSelectedFcn = createCallbackFcn(app, @OriginalVideoButtonPushed, true);
            app.OriginalVideoMenu.Text = 'Original Video';

            % Create CompressVideoMenu
            app.CompressVideoMenu = uimenu(app.VideoMenu);
            app.CompressVideoMenu.MenuSelectedFcn = createCallbackFcn(app, @CompressVideoButtonPushed, true);
            app.CompressVideoMenu.Text = 'Compress Video';

            % Create SaveVideoMenu
            app.SaveVideoMenu = uimenu(app.VideoMenu);
            app.SaveVideoMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveVideoButtonPushed, true);
            app.SaveVideoMenu.Text = 'Save Video';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.ImageCompressionSimulationUIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', 220};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', 0};
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.BorderType = 'none';
            app.LeftPanel.Layout.Row = [1 7];
            app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.Scrollable = 'on';

            % Create LeftGridLayout
            app.LeftGridLayout = uigridlayout(app.LeftPanel);
            app.LeftGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x'};
            app.LeftGridLayout.Padding = [0 0 0 0];

            % Create LeftAxes
            app.LeftAxes = uiaxes(app.LeftGridLayout);
            title(app.LeftAxes, '')
            xlabel(app.LeftAxes, '')
            ylabel(app.LeftAxes, '')
            app.LeftAxes.PlotBoxAspectRatio = [1 1.0689238210399 1];
            app.LeftAxes.XTick = [];
            app.LeftAxes.YTick = [];
            app.LeftAxes.Layout.Row = [1 5];
            app.LeftAxes.Layout.Column = [1 2];

            % Create MiddlePanel
            app.MiddlePanel = uipanel(app.GridLayout);
            app.MiddlePanel.BorderType = 'none';
            app.MiddlePanel.Layout.Row = [1 7];
            app.MiddlePanel.Layout.Column = 2;
            app.MiddlePanel.Scrollable = 'on';

            % Create MiddleGridLayout
            app.MiddleGridLayout = uigridlayout(app.MiddlePanel);
            app.MiddleGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x'};
            app.MiddleGridLayout.Padding = [0 0 0 0];

            % Create MiddleAxes
            app.MiddleAxes = uiaxes(app.MiddleGridLayout);
            title(app.MiddleAxes, '')
            xlabel(app.MiddleAxes, '')
            ylabel(app.MiddleAxes, '')
            app.MiddleAxes.PlotBoxAspectRatio = [1 1.10399032648126 1];
            app.MiddleAxes.XTick = [];
            app.MiddleAxes.YTick = [];
            app.MiddleAxes.Layout.Row = [1 5];
            app.MiddleAxes.Layout.Column = [1 2];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.BorderType = 'none';
            app.RightPanel.Layout.Row = [1 8];
            app.RightPanel.Layout.Column = 3;
            app.RightPanel.Scrollable = 'on';

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.RightPanel);
            app.GridLayout2.RowHeight = {60, 30, 60, 60, 150, '1x', 30};

            % Create Slider
            app.Slider = uislider(app.GridLayout2);
            app.Slider.Limits = [-3 3];
            app.Slider.MajorTicks = [-3 -2 -1 0 1 2 3];
            app.Slider.MajorTickLabels = {'0.001', '0.01', '0.1', '1', '10', '100', '1000'};
            app.Slider.Orientation = 'vertical';
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);
            app.Slider.ValueChangingFcn = createCallbackFcn(app, @SliderValueChanging, true);
            app.Slider.Layout.Row = [3 6];
            app.Slider.Layout.Column = 2;
            app.Slider.Value = 0.001;

            % Create PleaseselectaJPGorBMPfileLabel
            app.PleaseselectaJPGorBMPfileLabel = uilabel(app.GridLayout2);
            app.PleaseselectaJPGorBMPfileLabel.HorizontalAlignment = 'center';
            app.PleaseselectaJPGorBMPfileLabel.Layout.Row = 1;
            app.PleaseselectaJPGorBMPfileLabel.Layout.Column = 2;
            app.PleaseselectaJPGorBMPfileLabel.Text = {'Please select'; 'a JPG or BMP '; 'file.'};

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.GridLayout2);
            app.GridLayout3.ColumnWidth = {'1x'};
            app.GridLayout3.Padding = [0 0 0 0];
            app.GridLayout3.Layout.Row = 3;
            app.GridLayout3.Layout.Column = 1;

            % Create KValueLabel
            app.KValueLabel = uilabel(app.GridLayout3);
            app.KValueLabel.HorizontalAlignment = 'center';
            app.KValueLabel.VerticalAlignment = 'bottom';
            app.KValueLabel.FontSize = 15;
            app.KValueLabel.Layout.Row = 1;
            app.KValueLabel.Layout.Column = 1;
            app.KValueLabel.Text = 'K Value';

            % Create EditField
            app.EditField = uieditfield(app.GridLayout3, 'numeric');
            app.EditField.Limits = [0 1000];
            app.EditField.ValueChangedFcn = createCallbackFcn(app, @EditFieldValueChanged, true);
            app.EditField.FontSize = 15;
            app.EditField.Layout.Row = 2;
            app.EditField.Layout.Column = 1;
            app.EditField.Value = 1;

            % Create CompressButton
            app.CompressButton = uibutton(app.GridLayout2, 'push');
            app.CompressButton.ButtonPushedFcn = createCallbackFcn(app, @CompressButtonPushed, true);
            app.CompressButton.FontSize = 15;
            app.CompressButton.Layout.Row = 7;
            app.CompressButton.Layout.Column = 1;
            app.CompressButton.Text = 'Compress';

            % Create SavetoFileButton
            app.SavetoFileButton = uibutton(app.GridLayout2, 'push');
            app.SavetoFileButton.ButtonPushedFcn = createCallbackFcn(app, @SavetoFileButtonPushed, true);
            app.SavetoFileButton.FontSize = 15;
            app.SavetoFileButton.Layout.Row = 7;
            app.SavetoFileButton.Layout.Column = 2;
            app.SavetoFileButton.Text = 'Save to File';

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.GridLayout2);
            app.GridLayout4.ColumnWidth = {'1x'};
            app.GridLayout4.Padding = [0 0 0 0];
            app.GridLayout4.Layout.Row = 1;
            app.GridLayout4.Layout.Column = 1;

            % Create OpenButton
            app.OpenButton = uibutton(app.GridLayout4, 'push');
            app.OpenButton.ButtonPushedFcn = createCallbackFcn(app, @OpenButtonPushed, true);
            app.OpenButton.FontSize = 15;
            app.OpenButton.Layout.Row = 1;
            app.OpenButton.Layout.Column = 1;
            app.OpenButton.Text = 'Open';

            % Create ReloadButton
            app.ReloadButton = uibutton(app.GridLayout4, 'push');
            app.ReloadButton.ButtonPushedFcn = createCallbackFcn(app, @ReloadButtonPushed, true);
            app.ReloadButton.FontSize = 15;
            app.ReloadButton.Layout.Row = 2;
            app.ReloadButton.Layout.Column = 1;
            app.ReloadButton.Text = 'Reload';

            % Create QuantizationTableButton
            app.QuantizationTableButton = uibutton(app.GridLayout2, 'push');
            app.QuantizationTableButton.ButtonPushedFcn = createCallbackFcn(app, @QuantizationTableButtonPushed, true);
            app.QuantizationTableButton.FontSize = 15;
            app.QuantizationTableButton.Layout.Row = 4;
            app.QuantizationTableButton.Layout.Column = 1;
            app.QuantizationTableButton.Text = {'Quantization'; 'Table'};

            % Create DropDown
            app.DropDown = uidropdown(app.GridLayout2);
            app.DropDown.Items = {'Image File Name'};
            app.DropDown.ValueChangedFcn = createCallbackFcn(app, @DropDownValueChanged, true);
            app.DropDown.FontSize = 15;
            app.DropDown.Layout.Row = 2;
            app.DropDown.Layout.Column = [1 2];
            app.DropDown.Value = 'Image File Name';

            % Create VideoGridLayout
            app.VideoGridLayout = uigridlayout(app.GridLayout2);
            app.VideoGridLayout.ColumnWidth = {'1x'};
            app.VideoGridLayout.RowHeight = {'1x', '1x', '1x'};
            app.VideoGridLayout.Layout.Row = 5;
            app.VideoGridLayout.Layout.Column = 1;

            % Create OriginalVideoButton
            app.OriginalVideoButton = uibutton(app.VideoGridLayout, 'push');
            app.OriginalVideoButton.ButtonPushedFcn = createCallbackFcn(app, @OriginalVideoButtonPushed, true);
            app.OriginalVideoButton.Layout.Row = 1;
            app.OriginalVideoButton.Layout.Column = 1;
            app.OriginalVideoButton.Text = {'Original'; 'Video'};

            % Create CompressVideoButton
            app.CompressVideoButton = uibutton(app.VideoGridLayout, 'push');
            app.CompressVideoButton.ButtonPushedFcn = createCallbackFcn(app, @CompressVideoButtonPushed, true);
            app.CompressVideoButton.Layout.Row = 2;
            app.CompressVideoButton.Layout.Column = 1;
            app.CompressVideoButton.Text = {'Compress'; 'Video'};

            % Create SaveVideoButton
            app.SaveVideoButton = uibutton(app.VideoGridLayout, 'push');
            app.SaveVideoButton.ButtonPushedFcn = createCallbackFcn(app, @SaveVideoButtonPushed, true);
            app.SaveVideoButton.Enable = 'off';
            app.SaveVideoButton.Layout.Row = 3;
            app.SaveVideoButton.Layout.Column = 1;
            app.SaveVideoButton.Text = {'Save'; 'Video'};

            % Create VideoSlider
            app.VideoSlider = uislider(app.GridLayout);
            app.VideoSlider.MajorTicks = [];
            app.VideoSlider.ValueChangedFcn = createCallbackFcn(app, @VideoSliderValueChanged, true);
            app.VideoSlider.ValueChangingFcn = createCallbackFcn(app, @VideoSliderValueChanging, true);
            app.VideoSlider.MinorTicks = [];
            app.VideoSlider.Interruptible = 'off';
            app.VideoSlider.Layout.Row = 8;
            app.VideoSlider.Layout.Column = [1 2];

            % Show the figure after all components are created
            app.ImageCompressionSimulationUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CompressApp_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.ImageCompressionSimulationUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ImageCompressionSimulationUIFigure)
        end
    end
end