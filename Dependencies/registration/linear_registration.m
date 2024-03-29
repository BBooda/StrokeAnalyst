function [MOVINGREG, tform, movingRefObj,fixedRefObj] = linear_registration(MOVING,FIXED, varargin)
            %registerImages  Register grayscale images using auto-generated code from Registration Estimator app.
            %  [MOVINGREG] = registerImages(MOVING,FIXED) Register grayscale images
            %  MOVING and FIXED using auto-generated code from the Registration
            %  Estimator app. The values for all registration parameters were set
            %  interactively in the app and result in the registered image stored in the
            %  structure array MOVINGREG.
            % registration type 'similarity', 'translation', 'rigid', 'affine'
            
            % set registration type 
            if ~isempty(varargin)
                if varargin{1} == "Ttype" && varargin{2} == "rigid"
                    transformation_type = varargin{2};
                end
                if varargin{1} == "Ttype" && varargin{2} == "similarity"
                    transformation_type = varargin{2};
                end
                if varargin{1} == "Ttype" && varargin{2} == "translation"
                    transformation_type = varargin{2};
                end
                if varargin{1} == "Ttype" && varargin{2} == "affine"
                    transformation_type = varargin{2};
                end
            else
                %default type : similarity transformation 
                transformation_type = 'similarity';
            end
            
            % Default spatial referencing objects
            fixedRefObj = imref2d(size(FIXED));
            movingRefObj = imref2d(size(MOVING));
            
            % Intensity-based registration
            [optimizer, metric] = imregconfig('multimodal');
            metric.NumberOfSpatialSamples = 500;
            metric.NumberOfHistogramBins = 50;
            metric.UseAllPixels = true;
            optimizer.GrowthFactor = 1.050000;
            optimizer.Epsilon = 1.50000e-06;
            optimizer.InitialRadius = 6.25000e-03;
            optimizer.MaximumIterations = 100;
            
            % Align centers
            fixedCenterXWorld = mean(fixedRefObj.XWorldLimits);
            fixedCenterYWorld = mean(fixedRefObj.YWorldLimits);
            movingCenterXWorld = mean(movingRefObj.XWorldLimits);
            movingCenterYWorld = mean(movingRefObj.YWorldLimits);
            translationX = fixedCenterXWorld - movingCenterXWorld;
            translationY = fixedCenterYWorld - movingCenterYWorld;
            
            % Coarse alignment
            initTform = affine2d();
            initTform.T(3,1:2) = [translationX, translationY];
            
            %get transformation type from settings drop down menu e.g. similarity, affine, ...
            
            % Apply transformation
            tform = imregtform(MOVING,movingRefObj,FIXED,fixedRefObj,transformation_type,optimizer,metric,'PyramidLevels',3,'InitialTransformation',initTform);
            MOVINGREG.Transformation = tform;
            MOVINGREG.RegisteredImage = imwarp(MOVING, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true);
            
            % Store spatial referencing object
            MOVINGREG.SpatialRefObj = fixedRefObj;
        end