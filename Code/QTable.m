classdef QTable < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        QuantizationTableUIFigure  matlab.ui.Figure
        GridLayout                 matlab.ui.container.GridLayout
        UITable                    matlab.ui.control.Table
        GridLayout2                matlab.ui.container.GridLayout
        DefaultButton              matlab.ui.control.Button
        RandomButton               matlab.ui.control.Button
        DoneButton                 matlab.ui.control.Button
    end

    
    properties (Access = private)
        mainapp % main app
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp, qTable)
            app.mainapp = mainapp;
            t = array2table(qTable);
            app.UITable.Data = t;
        end

        % Button pushed function: DoneButton
        function DoneButtonPushed(app, event)
            app.mainapp.qTable = table2array(app.UITable.Data);
            compressAndShow(app.mainapp);
            app.mainapp.QuantizationTableButton.Enable = 'on';
            delete(app);
        end

        % Close request function: QuantizationTableUIFigure
        function QuantizationTableUIFigureCloseRequest(app, event)
            app.mainapp.QuantizationTableButton.Enable = 'on';
            delete(app)
        end

        % Button pushed function: DefaultButton
        function DefaultButtonPushed(app, event)
            t = array2table(app.mainapp.defaultQTable);
            app.UITable.Data = t;
        end

        % Button pushed function: RandomButton
        function RandomButtonPushed(app, event)
            t = array2table(randi(128, 8));
            app.UITable.Data = t;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create QuantizationTableUIFigure and hide until all components are created
            app.QuantizationTableUIFigure = uifigure('Visible', 'off');
            app.QuantizationTableUIFigure.Position = [100 100 623 364];
            app.QuantizationTableUIFigure.Name = 'Quantization Table';
            app.QuantizationTableUIFigure.CloseRequestFcn = createCallbackFcn(app, @QuantizationTableUIFigureCloseRequest, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.QuantizationTableUIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'1x', 100};

            % Create UITable
            app.UITable = uitable(app.GridLayout);
            app.UITable.ColumnName = '';
            app.UITable.RowName = {};
            app.UITable.ColumnEditable = true;
            app.UITable.Layout.Row = 1;
            app.UITable.Layout.Column = 1;
            app.UITable.FontSize = 15;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.GridLayout);
            app.GridLayout2.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayout2.Layout.Row = 2;
            app.GridLayout2.Layout.Column = 1;

            % Create DefaultButton
            app.DefaultButton = uibutton(app.GridLayout2, 'push');
            app.DefaultButton.ButtonPushedFcn = createCallbackFcn(app, @DefaultButtonPushed, true);
            app.DefaultButton.FontSize = 15;
            app.DefaultButton.Layout.Row = 1;
            app.DefaultButton.Layout.Column = 2;
            app.DefaultButton.Text = 'Default';

            % Create RandomButton
            app.RandomButton = uibutton(app.GridLayout2, 'push');
            app.RandomButton.ButtonPushedFcn = createCallbackFcn(app, @RandomButtonPushed, true);
            app.RandomButton.FontSize = 15;
            app.RandomButton.Layout.Row = 1;
            app.RandomButton.Layout.Column = 3;
            app.RandomButton.Text = 'Random';

            % Create DoneButton
            app.DoneButton = uibutton(app.GridLayout2, 'push');
            app.DoneButton.ButtonPushedFcn = createCallbackFcn(app, @DoneButtonPushed, true);
            app.DoneButton.FontSize = 15;
            app.DoneButton.Layout.Row = 2;
            app.DoneButton.Layout.Column = [2 3];
            app.DoneButton.Text = 'Done';

            % Show the figure after all components are created
            app.QuantizationTableUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = QTable(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.QuantizationTableUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.QuantizationTableUIFigure)
        end
    end
end