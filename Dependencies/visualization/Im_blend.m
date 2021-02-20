classdef Im_blend < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure          matlab.ui.Figure
        UIAxes            matlab.ui.control.UIAxes
        BlendSliderLabel  matlab.ui.control.Label
        BlendSlider       matlab.ui.control.Slider
        
    end
    properties (Access = private)
        im1 % image1
        im2 % image2
    end

    methods (Access = private)

        % Value changed function: BlendSlider
        function BlendSliderValueChanged(app, event)
            alpha = app.BlendSlider.Value;
            alpha = alpha/100;
            C = alpha * app.im1 + (1 - alpha) * app.im2;
            imshow(C,'Parent',app.UIAxes);
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'UI Figure';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, '')
            xlabel(app.UIAxes, '')
            ylabel(app.UIAxes, '')
            app.UIAxes.Position = [1 1 640 420];

            % Create BlendSliderLabel
            app.BlendSliderLabel = uilabel(app.UIFigure);
            app.BlendSliderLabel.HorizontalAlignment = 'right';
            app.BlendSliderLabel.Position = [212 441 36 22];
            app.BlendSliderLabel.Text = 'Blend';

            % Create BlendSlider
            app.BlendSlider = uislider(app.UIFigure);
            app.BlendSlider.ValueChangedFcn = createCallbackFcn(app, @BlendSliderValueChanged, true);
            app.BlendSlider.Position = [259 450 160 3];
            app.BlendSlider.Value = 50;
        end
    end

    methods (Access = public)

        % Construct app
        function app = Im_blend(im1, im2)
            app.im1 = im1; 
            app.im2 = im2;
            % Create and configure components
            
            createComponents(app)
            %first display
            alpha = app.BlendSlider.Value;
            alpha = alpha/100;
            C = alpha * app.im1 + (1 - alpha) * app.im2;
            imshow(C,'Parent',app.UIAxes);
            
            
            % Register the app with App Designer
            registerApp(app, app.UIFigure)

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