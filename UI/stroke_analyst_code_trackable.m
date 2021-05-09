classdef stroke_analyst_ui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        FileMenu                     matlab.ui.container.Menu
        loadimagesMenu               matlab.ui.container.Menu
        setmodelpathMenu             matlab.ui.container.Menu
        setsubjectpathMenu           matlab.ui.container.Menu
        setdefaultoutputdirMenu      matlab.ui.container.Menu
        setdependenciesdirMenu       matlab.ui.container.Menu
        setdrammsdirMenu             matlab.ui.container.Menu
        FigurePanel                  matlab.ui.container.Panel
        TabGroup                     matlab.ui.container.TabGroup
        ImagesTab                    matlab.ui.container.Tab
        IndexiesListBoxLabel         matlab.ui.control.Label
        IndexiesListBox              matlab.ui.control.ListBox
        renameButton                 matlab.ui.control.Button
        UIAxes                       matlab.ui.control.UIAxes
        SliceNameEditFieldLabel      matlab.ui.control.Label
        SliceNameEditField           matlab.ui.control.EditField
        DataPreprocessingPanel       matlab.ui.container.Panel
        DataPreDropDown              matlab.ui.control.DropDown
        BGSegmentationButton         matlab.ui.control.Button
        PCARotationButton            matlab.ui.control.Button
        MonoSwitch                   matlab.ui.control.Switch
        GraphCutButton               matlab.ui.control.Button
        reloadButton                 matlab.ui.control.Button
        flipButton                   matlab.ui.control.Button
        GraphSegmTab                 matlab.ui.container.Tab
        GPAxes                       matlab.ui.control.UIAxes
        PixelAnnotationButtonGroup   matlab.ui.container.ButtonGroup
        foregroundButton             matlab.ui.control.ToggleButton
        backgroundButton             matlab.ui.control.ToggleButton
        eraseButton                  matlab.ui.control.ToggleButton
        computeButton                matlab.ui.control.Button
        clearbackgroundButton        matlab.ui.control.Button
        clearforegroundButton        matlab.ui.control.Button
        FinishButton                 matlab.ui.control.Button
        markpointsButton             matlab.ui.control.Button
        Slider                       matlab.ui.control.Slider
        AtlasTab                     matlab.ui.container.Tab
        AtlasAxes                    matlab.ui.control.UIAxes
        IndexListBoxLabel            matlab.ui.control.Label
        IndexListBox                 matlab.ui.control.ListBox
        ResultsTab                   matlab.ui.container.Tab
        RIndexiesListBoxLabel        matlab.ui.control.Label
        RIndexiesListBox             matlab.ui.control.ListBox
        ResAxes1                     matlab.ui.control.UIAxes
        ResAxes2                     matlab.ui.control.UIAxes
        RD1DropDownLabel             matlab.ui.control.Label
        RD1DropDown                  matlab.ui.control.DropDown
        RD2DropDownLabel             matlab.ui.control.Label
        RD2DropDown                  matlab.ui.control.DropDown
        LinearTransfTab              matlab.ui.container.Tab
        TestLinAxes                  matlab.ui.control.UIAxes
        lineartransformButton        matlab.ui.control.Button
        LogTextAreaLabel             matlab.ui.control.Label
        LogTextArea                  matlab.ui.control.TextArea
        TabGroup2                    matlab.ui.container.TabGroup
        ControlTab                   matlab.ui.container.Tab
        RUNButton                    matlab.ui.control.Button
        ChoosedirectoryButton        matlab.ui.control.Button
        SettingsTab                  matlab.ui.container.Tab
        loadmodelButton              matlab.ui.control.Button
        histogramequalizationButton  matlab.ui.control.Button
        SetDropDown                  matlab.ui.control.DropDown
        LesionCorrectionTab          matlab.ui.container.Tab
        markButton                   matlab.ui.control.Button
        Switch                       matlab.ui.control.RockerSwitch
        finalButton                  matlab.ui.control.Button
        Radius                       matlab.ui.control.Spinner
    end

    
    properties (Access = private)
        imgs % Cell array of imgs
        imgs_cpy % cpy of cell array of imgs
        imgs_segmented % cell array of images after BG segmentation
        img_names % Cell array of img names, needed for registration
        mono % indicates whether the processing will be for a single img or for all 
        
        % +++++++++++++graph cut variables+++++++++++++ 
        x_b
        y_b
        x_f
        y_f
        gp_img 
        % -------------graph cut variables-------------
        atlas % TTC atlas variable
        wor_dir % directory of processing 
        reference % reference atlas slice for each subject slice
        save_dir % directory of each subject slice.
        sub_T % struct that holds all transformation information, i.e. index transformation matrices...
        registered % struct for registered subject. Contains zscore, lesion prediction, ...
        hemi_flag % hemisphere flag, if hemi flag = 0, lesion hemisphere is left. If hemi_flag = 1, lesion hemisphere = right
        hemi_T % struct contains transformations between hemispheres of the same slice. 
        model % machine learning model
        super_dens % superpixel density, 0 to 1 parameter that specifies superpixel density 
        results % Description
        allen_masks % allen_masks on TTC atlas
        dictionary % json file containing allen labels naming parsed
        
        exDataFig % external figure
        add_mask % correction mask, add new points
        remove_mask % correction mask, remove points
        corrected_lesion % corrected lesion mask, including corrected points and ML lesion prediction
        paths % required paths to run the app. path{1} := ML model path,.. 
        model_path % absolute model path
        model_names % model names. used to choose between models.
        hemi_masks % hemisphere masks dictionary
        affine_data_S2A % create linear transformation output struct 
        hemi_tr % hemisphere transformations for hemisphere differencies features
    end
    
    methods (Access = private)
        
        % 1ST FUNCTION
        % function to get data cursor position   
        % assign values to vectors for graph cut algorithm
        function txt = dateTipUpdateFcn(app,src,evnt)
            %determine between background and foreground
            % assign and scatter plot FG points
            if (strcmp(app.PixelAnnotationButtonGroup.SelectedObject.Text, 'foreground'))
                app.x_f = [app.x_f ; evnt.Position(1)];
                app.y_f = [app.y_f ; evnt.Position(2)];
                txt = sprintf('saved point: (%g,%g)',evnt.Position);
                hold(app.GPAxes, 'on');
                scatter(app.GPAxes,app.x_f,app.y_f, 'green', 'filled');
                hold(app.GPAxes, 'off');
            else
                % assing and scatter plot BG points
                app.x_b = [app.x_b ; evnt.Position(1)];
                app.y_b = [app.y_b ; evnt.Position(2)];
                txt = sprintf('saved point: (%g,%g)',evnt.Position);
                hold(app.GPAxes, 'on');
                scatter(app.GPAxes,app.x_b,app.y_b, 'red', 'filled');
                hold(app.GPAxes, 'on');
                scatter(app.GPAxes,app.x_f,app.y_f, 'green', 'filled');
                hold(app.GPAxes, 'off');
            end                   
        end
    
        function txt = data_les_cor(app,src,evnt)
            %determine points to correct on final lesion prediction
            % update upon each data tip 
            [rows, cols] = size(app.add_mask);
            if (strcmp(app.Switch.Value, 'Add'))
                
                
                x = evnt.Position(1);
                y = evnt.Position(2);
                
                app.add_mask = (app.add_mask + pixel_brush(cols, rows, app.Radius.Value, [x, y])) ~= 0;
                
                app.corrected_lesion = (double(app.sub_T.lesion) + double(app.add_mask)) ~= 0;
                
                imshow(blend_img(app,app.sub_T.subject, app.corrected_lesion, 60), 'Parent', app.ResAxes1);
%                 imshow(blend_img(app,app.sub_T.subject, app.corrected_lesion, 60));
            else
                % assing and scatter plot BG points
                x = evnt.Position(1);
                y = evnt.Position(2);
                
                % asign points on remove_mask
                app.remove_mask = (app.remove_mask + pixel_brush(cols, rows, app.Radius.Value, [x, y])) ~= 0;
                
                app.corrected_lesion = (double(app.sub_T.lesion) - double(app.remove_mask)) > 0;
                
                imshow(blend_img(app,app.sub_T.subject, app.corrected_lesion, 60), 'Parent', app.ResAxes1);
%                 imshow(blend_img(app,app.sub_T.subject, app.corrected_lesion, 60));
            end                   
        end
    
        %2ND FUNCTION
        %perform graph cut segmentation
        function graph_cut_segm(app,foresub,backsub, img)
            
            % initialize slider value, determines superpixel density
%             app.super_dens = 0.5;
%             app.Slider.Value = 0.5;
            
            %determine foreground, background indexies
            foregroundInd = sub2ind(size(img),foresub(:,2),foresub(:,1));
            backgroundInd = sub2ind(size(img),backsub(:,2),backsub(:,1));
            
            [heigth, width] = size(img);
            num_of_pix = width * heigth;
            % determine num of superpixels as percentage 
            num_of_super = round(num_of_pix * (0.0005 + 0.0001*app.super_dens)); % where 0.0003 % is the 0.03 % of the original number
            
            L = superpixels(img,num_of_super);
            
            
            bg_mask = lazysnapping(img,L,foregroundInd,backgroundInd);
            app.gp_img = bsxfun(@times, img, cast(bg_mask, 'like', img));
            
            % visualize results
            update_gp_visual(app,app, true, img, bg_mask);
        end
        
        %3RD FUNCTION
        % blend mask with img, transparent visualization
        function out = blend_img(app,img1, img2, p)
        %where img1 the original img
        %img2 usually the mask
        %p -> the transparency percentage 
        
            mask = zeros(size(img1));
            mask(:,:,2) = (255*img2);
            % opacity percentage 
            alpha = p;
            alpha = alpha/100;
            out = alpha * img1 + (1 - alpha) * uint8(mask);
        
        
        end
    
        %4TH FUNCTION 
        function update_gp_visual(app, ~,flag, varargin)
            % flag indicates whether a segmentation has occur or data points have been cleared.
            if (flag)
                imshow(blend_img(app,varargin{1}, varargin{2}, 60), 'Parent', app.GPAxes); 
                hold(app.GPAxes, 'on');
                scatter(app.GPAxes,app.x_b,app.y_b, 'red', 'filled');
                hold(app.GPAxes, 'on');
                scatter(app.GPAxes,app.x_f,app.y_f, 'green', 'filled'); 
                hold(app.GPAxes, 'off');
            else
                imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, 'Parent', app.GPAxes); 
                hold(app.GPAxes, 'on');
                scatter(app.GPAxes,app.x_b,app.y_b, 'red', 'filled');
                hold(app.GPAxes, 'on');
                scatter(app.GPAxes,app.x_f,app.y_f, 'green', 'filled'); 
                hold(app.GPAxes, 'off');
            end
        end
    
        %5TH FUNCTION
        % computes reference image key using name indexing
        function [ref,index] = find_reference_img(app, str)
            if strcmp(str(1:2), 'bn')
                ref = str2double(strcat('-', str(3), '.', str(5:6)));
            else
                ref = str2double(strcat(str(3), '.', str(5:6)));
            end
            % load atlas if not loaded.
            if isempty(app.atlas)
%                 app.atlas = load('/home/makis/Documents/MouseStrokeImageAnalysis/Data/subjects_results/myatlasv1.mat');
                 app.atlas = load(strcat(app.paths{4}, '/myatlasv1.mat'));  
                 app.IndexListBox.Items = app.atlas.index_list;
                 imshow(uint8(app.atlas.my_atlas(0.02).Img), 'Parent', app.AtlasAxes);
            end
            index = ref;
            ref = app.atlas.my_atlas(ref);
        end
        
        %6TH FUNCTION
        %
        function create_processing_folder(app)
            % check date and time 
            date = datestr(floor(now));
            new_dir = strcat(date, "-",app.IndexiesListBox.Value);
            
            % create directory
            mkdir(app.wor_dir, new_dir);
            
            % set save directory
            % save dir will change for each different slice while working dir (wor_dir) will remain the same.
            app.save_dir = strcat(app.wor_dir, '/', new_dir);
            
        end
        
        %7TH FUNCTION
         function linear_registration_ui(app, subject, reference)

            [~,~,chann_test] = size(subject);

            if chann_test > 1 
                % call linear registration function given as input the
                % coresponding linear transformation
                [aff_out, ~,movingRefObj,fixedRefObj] = linear_registration(rgb2gray(subject),reference, "Ttype", app.SetDropDown.Value);
            else
                [aff_out, ~,movingRefObj,fixedRefObj] = linear_registration((subject),reference, "Ttype", app.SetDropDown.Value);
            end

            %save tranformation information
            app.sub_T.index = app.IndexiesListBox.Value;
            app.sub_T.subject = subject;
            app.sub_T.reference = app.reference;
            app.sub_T.aff_out = aff_out;
            app.sub_T.movingRefObj = movingRefObj;
            app.sub_T.fixedRefObj = fixedRefObj;

            % inverse linear transfor
            app.sub_T.inv_aff = invert(aff_out.Transformation);

            % create nifti files for dramms non linear registration
            app.affine_data_S2A = create_affine_data(aff_out, subject, reference,... 
            app.sub_T.index, app.save_dir, movingRefObj, fixedRefObj);

            cd(app.save_dir);
         end
    
        
        %8TH FUNCTION
        function non_linear_registration_ui(app)
            %determine reference image (atlas image) path.
            ref_path = strcat(app.save_dir, '/reference.nii');
            
            % determine path for linearly transformed image
            sub_aff_path = strcat(app.save_dir, '/aff_sub_to_average.nii');
            
            % non linearly registered subject path
            regi_sub_path = app.save_dir;
            
            %call dramms, perform non linear registration
            dramms_2dregistration_ui(app,ref_path,sub_aff_path,regi_sub_path, app.IndexiesListBox.Value);
            
            % inverse deformation field
            %deternine deformation field path 
            dfield_path = strcat(app.save_dir, '/dfield');
            dramms_inverse_dfield_ui(dfield_path, app.save_dir, app.paths{5});
            
        end
        
        %9TH FUNCTION
        % computes zscore and lesion hemisphere
        function cmp_zscore(app)
            % determine th path of registered subject
            subj_reg_path = strcat(app.save_dir, '/registered_', app.IndexiesListBox.Value, '_to_average.nii');
            
            % load registerd subject
             subject_registered = uint8(niftiread(subj_reg_path));
             app.sub_T.registered = subject_registered;
             
            % set original threshold for zscore calculation
            threshold = 3;
            
            % determine hemispheres
            mid_th = compute_midline_threshold(app.reference.Img);
            
            % cmp zscore image
            zscore = double(double(subject_registered)-app.reference.Img)./app.reference.STD;
            
            % save zscore 
            app.sub_T.zscore = zscore;
            
            % apply threshold and compute mask indicating points with a value > 3 STD
            abn_img = zscore > threshold;
            
            % compute hemisphere masks. Currently using two techniques (this is just temporary).
            [~, index] = find_reference_img(app, app.IndexiesListBox.Value);
            if app.hemi_masks.isKey(index)
                % 8 January hemisphere changes.
                right_hem_mask = app.hemi_masks(index).Right;
                left_hem_mask = app.hemi_masks(index).Left;
                
                %determine ubnormal hemisphere
                abn_right = right_hem_mask.* abn_img;
                abn_left = left_hem_mask.* abn_img;
                if (sum(abn_right(:) > 0) > sum(abn_left(:) > 0))
                    app.hemi_flag = 1;
                else
                    app.hemi_flag = 0;
                end
            else
                % determine lesion hemisphere, i.e. compare number of abnormality points
                [y, x] = find(abn_img);
                 x1 = [];x2 = [];
                 y1 = [];y2 = [];
                
                 % keep points only in wanted hemisphere
                 for i = 1:length(y)
                    if x(i) < mid_th
                        x1 = [x1, x(i)];
                        y1 = [y1, y(i)];
                    else
                        x2 = [x2, x(i)];
                        y2 = [y2, y(i)];
                    end
                 end
                 
                 app.hemi_flag = 0; % if hemi flag = 0, lesion hemisphere is left, else for hemi_flag = 1, lesion hemisphere = right
                 
                 %check wich hemisphere presents bigger abnormality(area wise)
                 if length(x2) > length(x1)
                    x1 = x2;
                    y1 = y2;
                    app.hemi_flag = 1;
                 end
                 
                 abn_img = zeros(size(zscore));
                 for i = 1:length(y1)
                    abn_img(y1(i), x1(i)) = 1;
                 end
                 
                 %compute masks for right and left hemisphere
                 [suby, subx] = find(subject_registered(:,:) ~= 0);
                 right_hem_mask = zeros(size(subject_registered));
                 left_hem_mask = zeros(size(subject_registered));
                 for i = 1:length(subx)
                    if subx(i) >= mid_th
                        right_hem_mask(suby(i), subx(i)) = 1;
                    else
                        left_hem_mask(suby(i), subx(i)) = 1;
                    end
                 end
            end
            
             
             %pass to struct for later use
             app.sub_T.right_hem_mask = right_hem_mask;
             app.sub_T.left_hem_mask = left_hem_mask;
             
             % compute hemisphere masks at subject space 
%              create_nifti({right_hem_mask}, app.save_dir, 'right_hem_mask_atlas_space', [0.021 0.021 0 1]);
%              create_nifti({left_hem_mask}, app.save_dir, 'left_hem_mask_atlas_space', [0.021 0.021 0 1]);
             nifti_save(app, right_hem_mask, 'right_hem_mask_atlas_space', app.save_dir);
             nifti_save(app, left_hem_mask, 'left_hem_mask_atlas_space', app.save_dir);
             
             % set paths for dramms, apply inv deformation field.
             r_h_mask_path = strcat(app.save_dir, '/right_hem_mask_atlas_space');
             l_h_mask_path = strcat(app.save_dir, '/left_hem_mask_atlas_space');
             inv_dfield_path = strcat(app.save_dir, '/inv_dfield');
             % inverse non linear transformation on hemisphere masks
             dramms_warp_ui(r_h_mask_path,inv_dfield_path, app.save_dir, 'right_h_mask_inversedDf', app.paths{5});
             dramms_warp_ui(l_h_mask_path,inv_dfield_path, app.save_dir, 'left_h_mask_inversedDf', app.paths{5});
             
             %inverse linear transformation on hemi masks
             inv_rhem_mask = 255*uint8(niftiread(strcat(app.save_dir, '/right_h_mask_inversedDf.nii')));
             inv_lhem_mask = 255*uint8(niftiread(strcat(app.save_dir, '/left_h_mask_inversedDf.nii')));
             
             subject_space_rhem_mask = imwarp(imbinarize(inv_rhem_mask), app.sub_T.fixedRefObj, app.sub_T.inv_aff, ...
                 'OutputView', app.sub_T.movingRefObj, 'SmoothEdges', true);

             subject_space_lhem_mask = imwarp(imbinarize(inv_lhem_mask), app.sub_T.fixedRefObj, app.sub_T.inv_aff, ... 
                 'OutputView', app.sub_T.movingRefObj, 'SmoothEdges', true);
             
             app.sub_T.ss_RHM = subject_space_rhem_mask;
             app.sub_T.ss_LHM = subject_space_lhem_mask;
        end
        
        %10TH FUNCTION
        function ml_pre = ml_lesion_pred(app)
            
%             L = load('/home/makis/Documents/MouseStrokeImageAnalysis/Data/subjects_results/hemisphere_transformations.mat', 'hemi_transf','hemi_transf_l', 'hemi_transf_r');
            L = load(strcat(app.paths{4},'/hemisphere_transformations/hemisphere_transformations.mat'), 'hemi_transf','hemi_transf_l', 'hemi_transf_r');
            % get hemisphere transformations
            % one object for slices transformed from left to right and one object for right to left ??
            app.hemi_T.hemi_transf = L.hemi_transf;
            app.hemi_T.hemi_transf_l = L.hemi_transf_l;
            app.hemi_T.hemi_transf_r = L.hemi_transf_r;
            
            
            name = app.IndexiesListBox.Value;
            
            %determine hemi_flag value, keep everything left
            if app.hemi_flag == 1 % hemi_flag == 1 => lesion right
                hem_mask = app.sub_T.right_hem_mask;
                ss_hem_mask = app.sub_T.ss_RHM;
            else
                hem_mask = app.sub_T.left_hem_mask;
                ss_hem_mask = app.sub_T.ss_LHM;
            end
            
            zscore = app.sub_T.zscore;
            % get rid of infinity and nan values.
            zscore(isnan(zscore(:))) = 0;
            zscore(isinf(zscore(:))) = 20;
            
            
            
            if app.hemi_flag == 1
                % if lesion hemisphere is right, obtain transformations and continue, else compute transformations for this index
                
                if app.hemi_T.hemi_transf_r.isKey(name)
                    fixedRefObj_T1 = app.hemi_T.hemi_transf_r(name).fixed;
                    movingRefObj_T1 = app.hemi_T.hemi_transf_r(name).mov;
                    aff_ref_flip = app.hemi_T.hemi_transf_r(name).T ;
%                     hemi_flag = app.hemi_T.hemi_transf_r(name).hemi_flag;
                %     dfield_path = strcat('/home/makis/Documents/MouseStrokeImageAnalysis/Data/subjects_results/hemisphere_transformations/', name);
        
                else
                    %compute transformations for this index.
                    
                    % find zscore hemisphere difference feature
                    % check registration between hemispheres 
                    ref_flip = flip(app.reference.Img, 2);
        
                    % linearly register hemispheres
                    [aff_ref_flip, ~,movingRefObj_T1,fixedRefObj_T1] = multimodal_affine_reg((ref_flip),app.reference.Img);
        %              affine_matrix_o = aff_out.Transformation;
        
%                      save('f_zscore_to_ref_aff', 'aff_ref_flip', 'movingRefObj_T1', 'fixedRefObj_T1');
        
                     %deformally register hemispheres
%                      create_nifti({aff_ref_flip.RegisteredImage}, app.save_dir, 'aff_ref_flip', [0.021 0.021 0 1]);
                     nifti_save(app, aff_ref_flip.RegisteredImage, 'aff_ref_flip', app.save_dir);
        
                     % set paths for dformable registration
%                      aff_path = load_file_names('aff_ref_flip', 'nii');
%                      aff_path = strcat(pwd, '/',aff_path{1},'.nii' );
%                      out_path = pwd;
                     aff_path = strcat(app.save_dir, '/aff_ref_flip.nii');
                     out_path = app.save_dir;
                     ref_path = strcat(app.save_dir, '/reference.nii');
        
                     % update .mat file 
                     % load files and update 
                     hemi_transf_r = L.hemi_transf_r;
                     hemi_transf = L.hemi_transf;
                     hemi_transf_l = L.hemi_transf_l;
                     
                     %save hemisphere transformation
                     %create transf object
                     transf.fixed = fixedRefObj_T1;
                     transf.mov = movingRefObj_T1;
                     transf.T = aff_ref_flip;
                     transf.hemi_flag = app.hemi_flag;
                    
                     %create and save to struct
                     hemi_transf_r(name) = transf;                   
                     
                     %save struct, save deformation field.
%                      save('/home/makis/Documents/MouseStrokeImageAnalysis/Data/subjects_results/hemisphere_transformations', 'hemi_transf', 'hemi_transf_l', 'hemi_transf_r');
                    save(strcat(app.paths{4},'/hemisphere_transformations/hemisphere_transformations'), 'hemi_transf', 'hemi_transf_l', 'hemi_transf_r');
                     dfield_path = strcat(app.paths{4},'/hemisphere_transformations/r_hemisphere/', name);
        
        
                     dramms_2dregistration_ui(app,ref_path,aff_path,out_path, name,dfield_path);
        
                end
        
            else
                %else we are in a left hemisphere detection (left lesion hit).
                % if transformation exists, assign values to use, else perform hemisphere transformation
                if app.hemi_T.hemi_transf_l.isKey(name)
                    fixedRefObj_T1 = app.hemi_T.hemi_transf_l(name).fixed;
                    movingRefObj_T1 = app.hemi_T.hemi_transf_l(name).mov;
                    aff_ref_flip = app.hemi_T.hemi_transf_l(name).T ;
%                     app.hemi_flag = app.hemi_T.hemi_transf_l(name).hemi_flag;
                %     dfield_path = strcat('/home/makis/Documents/MouseStrokeImageAnalysis/Data/subjects_results/hemisphere_transformations/', name);
        
                else
                    % find zscore hemisphere difference feature
                    % check registration between hemispheres 
                    ref_flip = flip(app.reference.Img, 2);
        
                    % linearly register hemispheres
                    [aff_ref_flip, ~,movingRefObj_T1,fixedRefObj_T1] = multimodal_affine_reg((ref_flip),app.reference.Img);
        %              affine_matrix_o = aff_out.Transformation;
%                      save('f_zscore_to_ref_aff', 'aff_ref_flip', 'movingRefObj_T1', 'fixedRefObj_T1');
        
                     %deformably register hemispheres
%                      create_nifti({aff_ref_flip.RegisteredImage}, app.save_dir, 'aff_ref_flip', [0.021 0.021 0 1]);
                      nifti_save(app, aff_ref_flip.RegisteredImage, 'aff_ref_flip', app.save_dir);
        
                     % set paths for dformable registration
%                      aff_path = load_file_names('aff_ref_flip', 'nii');
%                      aff_path = strcat(pwd, '/',aff_path{1},'.nii' );
%                      out_path = pwd;
                     aff_path = strcat(app.save_dir, '/aff_ref_flip.nii');
                     out_path = app.save_dir;
                     ref_path = strcat(app.save_dir, '/reference.nii');
                     
                     % update .mat file 
                     % load files and update 
                     hemi_transf_r = L.hemi_transf_r;
                     hemi_transf = L.hemi_transf;
                     hemi_transf_l = L.hemi_transf_l;
                     
                     %save hemisphere transformation
                     transf.fixed = fixedRefObj_T1;
                     transf.mov = movingRefObj_T1;
                     transf.T = aff_ref_flip;
                     transf.hemi_flag = app.hemi_flag;
                     
                     % save struct..
                     hemi_transf_l(name) = transf;
                     save(strcat(app.paths{4},'/hemisphere_transformations/hemisphere_transformations'), 'hemi_transf', 'hemi_transf_l', 'hemi_transf_r');
                     dfield_path = strcat(app.paths{4},'/hemisphere_transformations/l_hemisphere/', name);
        
        
                     dramms_2dregistration_ui(app,ref_path,aff_path,out_path, name,dfield_path);
        
                end
            end
            
            
            % use transformations, compute features, predict lesion.
            % use hemi flag and determine deformation field path
            
            if app.hemi_flag == 1
                dfield_path = strcat(app.paths{4},'/hemisphere_transformations/r_hemisphere/', name, 'dfield');
        
            else
                dfield_path = strcat(app.paths{4},'/hemisphere_transformations/l_hemisphere/', name, 'dfield');
        
            end
            
            % zscore flip 
%             zsc_flip = app.zscore;
            zsc_flip = flip(zscore, 2);
            % linearly register fliped zscore, use T1
            zsc_aff = imwarp(zsc_flip, movingRefObj_T1, aff_ref_flip.Transformation, 'OutputView', fixedRefObj_T1, 'SmoothEdges', true);
%             create_nifti({zsc_aff}, pwd, 'zsc_aff', [0.021 0.021 0 1]);
            nifti_save(app, zsc_aff, 'zsc_aff', pwd);
        
%             ssf_zsc_path = load_file_names('zsc_aff', 'nii');
%             ssf_zsc_path = ssf_zsc_path{1};
%             ssf_zsc_path = strcat(pwd,'/', ssf_zsc_path);
            ssf_zsc_path = strcat(app.save_dir, '/zsc_aff');
            
            % deformally register zsc_aff, use T2


            dramms_warp_ui(ssf_zsc_path,dfield_path, app.save_dir, 'ssf_zscore', app.paths{5});    
            
            % load ss_zscore (ssf := subject space flip)
            ssf_zscore = niftiread(strcat(app.save_dir,'/ssf_zscore.nii'));
            
            
            % compute hemisphere difference
            zsc_dif = abs(zscore - ssf_zscore);
            
            % keep left hemisphere (use as feature)
            zsc_dif = zsc_dif .* hem_mask;
            
            % keep left hemisphere feauture one

            zsc_dif = zsc_dif .* hem_mask;
            
            % go back to subject space
            %inverse deformation field
            
            %load inversed dfield ( subject image to reference tranform )
%             inv_dfield_path = load_file_names('inv', 'nii.gz');
%             inv_dfield_path = inv_dfield_path{1};
%             inv_dfield_path = strcat(pwd,'/', inv_dfield_path);
            
            inv_dfield_path = strcat(app.save_dir, '/inv_dfield');
            
        
            %apply transformation to zscore diference, bring to native space (zscore dif feature).
        
            % create .nifti for dramms
%             create_nifti({zsc_dif}, pwd, 'zsc_dif', [0.021 0.021 0 1]);
            nifti_save(app, zsc_dif, 'zsc_dif', pwd);
        
            % load .nifti image path
%             z_path = load_file_names('zsc_dif', 'nii');
%             z_path = z_path{1};
%             z_path = strcat(pwd, '/',z_path);
            z_path = strcat(app.save_dir, '/zsc_dif');
        
           
            % apply inversed dfield, save as ss_zscore (subject space zscore)
            dramms_warp_ui(z_path,inv_dfield_path, app.save_dir, 'zsc_dif', app.paths{5});
        
            % load and apply inversed linear tranform to native space
            % compute inverse linear transformation. This linear transf is the one between subject and TTC atlas slice.
            
            
            zsc_dif = imwarp(niftiread(strcat(app.save_dir, '/zsc_dif.nii')), app.sub_T.fixedRefObj, app.sub_T.inv_aff, ...
            'OutputView', app.sub_T.movingRefObj, 'SmoothEdges', true);
            
            
            % cmpt zscore feauture at subject space
            %mask zscore
            zscore = hem_mask .* zscore;
        
            %apply transformation to zscore, bring to native space, zscore feature
        
            % create .nifti for dramms
%             create_nifti({zscore}, pwd, 'tr_zscore', [0.021 0.021 0 1]);
            nifti_save(app, zscore, 'tr_zscore', pwd);
        
            % load .nifti image path
%             z_path = load_file_names('tr_zscore', 'nii');
%             z_path = z_path{1};
%             z_path = strcat(pwd, '/',z_path);
            z_path = strcat(app.save_dir, '/tr_zscore');
        
            % apply inversed dfield, save as ss_zscore (subject space zscore)
            dramms_warp_ui(z_path,inv_dfield_path, app.save_dir, 'ss_zscore', app.paths{5});
        
            % load and apply inversed linear tranform to native space
            ss_zscore = imwarp(niftiread(strcat(app.save_dir,'/ss_zscore.nii')), app.sub_T.fixedRefObj, app.sub_T.inv_aff, ...
            'OutputView', app.sub_T.movingRefObj, 'SmoothEdges', true);
        
            sub_hem = bsxfun(@times, app.sub_T.subject, cast(ss_hem_mask,class(app.sub_T.subject)));
            
            % save all important information 
            app.sub_T.ss_zscore = ss_zscore;
            app.sub_T.zsc_dif = zsc_dif;
            app.sub_T.hemi_flag = app.hemi_flag;
            
            %choose predictor function according to model loaded.
            if strcmp(app.model_names{1}, 'mdl_16')
                [out,scores] = rf_z_pred(sub_hem, ss_zscore, zsc_dif, app.model); % rgb + [3 3] median filtering, mdl_16
            elseif strcmp(app.model_names{1}, 'mdl_31')
                [out,scores] = rf_z_pred_v1(sub_hem, ss_zscore, zsc_dif, app.model); % rgb + [3 3] moving average filtering, mdl_31
            elseif strcmp(app.model_names{1}, 'mdl_11_3')
                [out,scores] = rf_z_pred_v2(sub_hem, ss_zscore, zsc_dif, app.model); % hsv + [3 3] moving average filtering, mdl_11_3
            end
            
            app.sub_T.scores = scores;
            
            ml_pre = bwareafilt(imbinarize(out),4); 
            
            imshow(ml_pre, 'Parent', app.ResAxes2);
            
            
        end
    
    
    
    
        %11TH FUNCTION
        function dramms_2dregistration_ui(app,target_path,moving_path,out_path, file_name, varargin)
            %   dramms_2dregistration(target_path,moving_path,out_path)
            %   +input => absolute file paths
            %   -output => 2 files. Registered Image to target and deformation field.   
            
                
            %     moving_path = strcat(moving_path, "/",file_name, ".nii");
                target_path = convertCharsToStrings(target_path);
                
                moving_path = convertCharsToStrings(moving_path);
            
                out_path_dfield = convertCharsToStrings(strcat(out_path, '/dfield.nii.gz'));
                
                if ~isempty(varargin)
                    out_path_dfield = convertCharsToStrings(strcat(varargin{1}, 'dfield.nii.gz'));
                end
                
                out_path = convertCharsToStrings(strcat(out_path, "/registered_", file_name, "_to_average.nii"));
                
                
                
            
            %     sett = " -w 1 -a 0 -v -v";
            
            
            %  -c   <int>              How to use mutual-saliency weighting. 
            %                         0 -- (default) do not use mutual-saliency if there are no outlier regions (lesions, cuts, etc);
            %                        1 -- use but do not save mutual-saliency map; 
            
                
                sett = " -w 1 -a 0 -c 1"; % < -c 1 > for lesions and cuts..
            %     sett = " -w 1 -a 0";
                ret_add = pwd;
                %create cell with registered slices to reference
                
                % Change directory to dramms bin to run dramms algorithms.
%                 cd('~/myprograms/dramms/bin/');
                cd(app.paths{5});
            
                % log output
                app.LogTextArea.Value = [app.LogTextArea.Value; "run Dramms registration..."];
%                 my_log(app, 'TEST--DRAMMS REGI LIVE');
                
                command = strcat("./dramms", " -S ", moving_path, " -T ", target_path, " -O ", out_path, " -D ", out_path_dfield,sett);
                [status, result] = system(command, '-echo');
                if status ~= 0
                    app.LogTextArea.Value = [app.LogTextArea.Value; result]; 
                end
                   
                 cd(ret_add)
                 
                 
                 app.LogTextArea.Value = [app.LogTextArea.Value; "Dramms registration finished!"];          
                 
            
            end


        %12TH FUNCTION
        function cmp_area_save_res(app, lesion_m, left_hemi, right_hemi)
            pix_area = 0.021*0.021;    
            
            [y, ~] = find(lesion_m);
            lesion_area = length(y)*pix_area;
            
            [y, ~] = find(left_hemi);
            lh_area = length(y)*pix_area;
            
            [y, ~] = find(right_hemi);
            rh_area = length(y)*pix_area;
            
%             T = table('Size',[3 1], 'VariableTypes', {'double'});
            Names = {cell2mat(app.img_names(strcmp(app.img_names, app.IndexiesListBox.Value))); 'lesion_area'; 'left_hem_area'; 'right_hem_area'};
            
%             VariableNames{end + 1} = {};
                        
            Variables = [NaN;lesion_area; lh_area; rh_area];
            
            T = table(Names,Variables); 
            
            writetable(T, strcat(app.save_dir, '/results.xls'));
            
            % affected region identification, save to file
            
            app.region_naming();
            
            if 1 
                imwrite(app.sub_T.subject, strcat(app.save_dir, '/subject.jpg'));
                imwrite(app.sub_T.lesion, strcat(app.save_dir, '/lesion_pred.jpg'));
            end
            
            % save matlab file
            subject_info = app.sub_T;
            save(strcat(app.save_dir,'/all'), 'subject_info');
            clear('subject_info');
            
        end
        
        %13TH FUNCTION
        function area_identification(app, inv_dfield, lesion_mask)
            % load mask
            
            mask = zeros(app.sub_T.reference.Img);
            
            % create nifti
            
%             create_nifti({mask}, app.save_dir, 'anatomical_mask', [0.021 0.021 0 1]);
            nifti_save(app, mask, 'anatomical_mask', app.save_dir);
            
            mask_path = strcat(app.save_dir, '/anatomical_mask.nii');
            
            % transforms label masks to subject space. 
            % use mask to filter out non affected anatomical areas. 
            
            % inverse deformable transformation
            
            dramms_warp_ui(mask_path, inv_dfield, app.save_dir, 'anat_mask_inv_def', app.paths{5});
            
            % inverse linear transformation
                
            ss_an_mask = imwarp(niftiread(strcat(app.save_dir,'/anat_mask_inv_def.nii')), app.sub_T.fixedRefObj, app.sub_T.inv_aff, ...
            'OutputView', app.sub_T.movingRefObj, 'SmoothEdges', true);
            
            % apply mask
            
            affected_areas = lesion_mask.*ss_an_mask;
            
            % search in dictionary
            
            
            
            % save results
            
        end
        
        function [MOVINGREG, tform, movingRefObj,fixedRefObj] = linear_regi(app, MOVING,FIXED)
            %registerImages  Register grayscale images using auto-generated code from Registration Estimator app.
            %  [MOVINGREG] = registerImages(MOVING,FIXED) Register grayscale images
            %  MOVING and FIXED using auto-generated code from the Registration
            %  Estimator app. The values for all registration parameters were set
            %  interactively in the app and result in the registered image stored in the
            %  structure array MOVINGREG.
            
            % Auto-generated by registrationEstimator app on 28-Dec-2019
            %-----------------------------------------------------------
            
            
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
            tform = imregtform(MOVING,movingRefObj,FIXED,fixedRefObj,app.SetDropDown.Value,optimizer,metric,'PyramidLevels',3,'InitialTransformation',initTform);
            MOVINGREG.Transformation = tform;
            MOVINGREG.RegisteredImage = imwarp(MOVING, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true);
            
            % Store spatial referencing object
            MOVINGREG.SpatialRefObj = fixedRefObj;
        end
        
        % affected region identification
        function region_naming(app)
            % load labels, if not loaded 
            if isempty(app.dictionary)
                fname = strcat(app.paths{4}, '/acronyms.json');
                fid = fopen(fname);
                raw = fread(fid,inf);
                str = char(raw');
                app.dictionary = jsondecode(str);
            end
            % if not loaded, load allen masks
            if isempty(app.allen_masks)
                app.allen_masks = load(strcat(app.paths{4}, '/allen_masks.mat'));
                app.allen_masks = app.allen_masks.allen_masks;
            end
            % transform mask to subject space
            
            % perform linear transformation 
            lp_linear = imwarp(app.sub_T.lesion, app.sub_T.movingRefObj, app.sub_T.aff_out.Transformation, 'OutputView', app.sub_T.fixedRefObj, 'SmoothEdges', true);
            
            % perform non linear registration 
%             create_nifti({lp_linear}, app.save_dir, 'lp_lin', [0.021 0.021 0 1]);
            nifti_save(app, lp_linear, 'lp_lin', app.save_dir);
            
            lp_lin_path = strcat(app.save_dir, '/lp_lin');
            
            dfield_path = strcat(app.save_dir, '/dfield'); 
            
            dramms_warp_ui(lp_lin_path,dfield_path, app.save_dir, 'lesion_pred_atlas_space', app.paths{5});
            
            % read from file 
            
            lp_AS = niftiread(strcat(app.save_dir, '/lesion_pred_atlas_space.nii'));            
            
            % filter allen mask using lesion prediction\
            
            % load corresponding mask 
            [~, index] = find_reference_img(app, app.IndexiesListBox.Value);
            
            %extract original allen mask and keep unique
            ori_allen_labels = unique(extract_allen_mask_v1(calculate_atlas_index(index)));
            
            
            
            % that mask exists
            if app.allen_masks.isKey(index)
                label_mask = app.allen_masks(index);
                
                if isequal(size(label_mask), size(lp_AS))
                    affected_regions_mask = label_mask .* lp_AS;
            
                    % aquire interpolated points indexies
                    int_indexies = ismember(affected_regions_mask, ori_allen_labels);      
                    
                    % filter out interpolated points, set to zero
                    
                    affected_regions_mask(~int_indexies) = 0;
                    
                    % filter duplicates and find affected regions 
                    
                    labels = unique(fix(affected_regions_mask(:)));
        
                    hit_regions = cell(numel(labels),1);
                    for i = 1:numel(labels)
                        hit_regions{i} = app.js_find(app.dictionary.msg, labels(i));
                    end
                    
                    filePh = fopen(strcat(app.save_dir,'/affected_regions.txt'),'w');
                    fprintf(filePh,'%s\n',hit_regions{:});
                    fclose(filePh);
                end
            end
            
        end
        
        function ot = js_find(app,mat, val)
            % ot = js_find(mat, val), mat is the json struct and val is the id
            % value.
            % recursive function, search in dictionary for allen labels. Returns
            % name for id.
            if isempty(mat)
                ot = [];
                return;
            end
        
            ind = [mat.id] == val;
            if (sum(ind(:)) ~= 0) %|| (isempty(A1.children))
                ot = mat(ind).name;
                return;
            end
            for i = 1:length(mat)
                
                    ot = js_find(mat(i).children, val);
                    if ~isempty(ot)
                        break;
                    end
                
            end
            
        end
        
        function check_paths(app, varargin)
            %check in to the same directory if paths.json file exist. 
            %Display to log Text area path status.
            if isfile('paths.json')
                % read paths.json file 
                fid = fopen('paths.json', 'r');
                raw = fread(fid, inf);
                str = char(raw');
                fclose(fid);
                paths = jsondecode(str);
                app.paths = paths;
                
                % display to log if path doesnt exist
    
                if strcmp(varargin{1}, 'disp')
                    for i = 1:numel(paths)
                        if isempty(paths{i})
                            if i == 1
                                app.LogTextArea.Value = [app.LogTextArea.Value; "WARNING: set absolute path for model!"];
                            elseif i == 2
                                app.LogTextArea.Value = [app.LogTextArea.Value; "NOTE: set path directory for test subjects"];
                            elseif i == 3
                                app.LogTextArea.Value = [app.LogTextArea.Value; "NOTE: set path for default output directory"];
                            elseif i == 4
                                app.LogTextArea.FontColor = 'red';
                                app.LogTextArea.Value = [app.LogTextArea.Value; "WARNING: set path for ui dependencies directory"];
%                                 app.LogTextArea.FontColor = 'black';
                            else
                                app.LogTextArea.Value = [app.LogTextArea.Value; "NOTE: set path for dramms software directory"];
                            end
                            
                        end
                    end
                end
                
            else 
                %if file doesnt exist create an empty file path 
                fid = fopen('paths.json', 'w');
                paths = {'' ; pwd; pwd; ''; ''};
                app.paths = paths;
                js = jsonencode(paths);
                fprintf(fid, js);
                fclose(fid);
                app.LogTextArea.Value = [app.LogTextArea.Value; "NOTE: paths.json file not found." ; "Create an empty paths.json file."; "Please set absolute path for ML model."; ...
                    "Please set path for ui dependencies dir." ; "Please set path for dramms software."];
            end            
        end
    
    
        
        
        function write_paths(app)
            % write paths to json file, use app.paths, a class variable which is updated from the file menu buttons
            fid = fopen('paths.json', 'w');
            paths = {app.paths{1} ; app.paths{2}; app.paths{3}; app.paths{4}; app.paths{5}};
            js = jsonencode(paths);
            fprintf(fid, js);
            fclose(fid);
        end
        
        function nifti_save(app,img, name, path)
%             app.LogTextArea.Value = [app.LogTextArea.Value ; "file created..."];
            [~, ~, channels] = size(img);
            
            if channels > 2 
                img = rgb2gray(img);
            end
            
            
            
            % create a nifti file and load header info
            if isempty(path)
               path = pwd; 
            end
            
            fullname = strcat(path, '/', name, '.nii');
            
            niftiwrite(single(img), fullname);
            
            % read header info 
            header = niftiinfo(fullname);
            
            % alter header according to input arguments 
            header.PixelDimensions = [0.0210 0.0210];
            header.Datatype =  'single';
            header.BitsPerPixel = 32;
            header.SpaceUnits = 'Millimeter';
            header.TimeUnits = 'Second';
            header.MultiplicativeScaling = 1;
            header.TransformName = 'Sform';
            
            header.Transform.T = [0.0210, 0, 0, 0; 0, 0.0210, 0, 0; 0, 0, 1.0000, 0;  0.0210, 0.0210, 1.0000, 1.0000];
        
        % "header.raw" values are updated with the changes of the header(above code, not sure, check this); 
        
            header.raw.pixdim = [1 0.0210 0.0210 1 0 0 0 0];
            header.raw.scl_slope = 1;
            header.raw.xyzt_units = 10;
            header.raw.qform_code = 2;
            header.raw.sform_code = 2;
            header.raw.qoffset_x = 0.0210;
            header.raw.qoffset_y = 0.0210;
            header.raw.qoffset_z = 1;
            header.raw.srow_x = [0.0210 0 0 0.0210];
            header.raw.srow_y = [0 0.0210 0 0.0210];
            header.raw.srow_z = [0 0 1 1];
            header.raw.qform_code = 2;
            header.raw.sform_code = 2;
            header.raw.qoffset_x = 0.0210;
            header.raw.qoffset_y = 0.0210;
            header.raw.qoffset_z = 1;
            
            
            % re-save file with new header.
            niftiwrite(single(img), fullname, header);
            
        
        
        
        end
        
        function my_log(app, str)
            app.LogTextArea.Value = [app.LogTextArea.Value; str];
        end
    end
    

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % show logo, must be in working directory
            logo_path = 'logo.jpg';
            if isfile(logo_path)
                imshow(imread(logo_path), 'Parent', app.UIAxes);               
            else
                app.LogTextArea.Value = [app.LogTextArea.Value; "Logo file not found!"];
            end
            
            
            
            % check for path file and display status 
            check_paths(app, 'disp');
            
            % set paths 
            app.model_path = app.paths{1};
            
            app.LogTextArea.Value = [app.LogTextArea.Value; "Welcome, hit: file -> load images to start."];
            
            if ~isempty(app.paths{4})
                %FIX hard coded path value
                app.hemi_masks = load(strcat(app.paths{4}, '/hemisphere_masks.mat'));
                app.hemi_masks = app.hemi_masks.hemi_m;
                
                app.hemi_tr = load(strcat(app.paths{4}, '/hemisphere_transformations','/hemisphere_transformations.mat'));
            else 
                app.hemi_masks = [];
                app.LogTextArea.Value = [app.LogTextArea.Value; "Hemisphere masks not found, please set dependencies path first."];
            end
        end

        % Menu selected function: loadimagesMenu
        function loadimagesMenuSelected(app, event)
            %+++Fuction, load images from file++++++++++++++++
%             addpath('~/Documents/MouseStrokeImageAnalysis/ScriptTest/area_calculation/');
%             addpath('~/Documents/MouseStrokeImageAnalysis/ScriptTest/registration2d/')
%             addpath('~/Documents/MouseStrokeImageAnalysis/ScriptTest/false_positive/');
%             addpath('~/Documents/MouseStrokeImageAnalysis/ScriptTest/UI_functions/');  
            addpath(genpath(app.paths{4}));
            app.LogTextArea.Value = [app.LogTextArea.Value; "Choose images to analyze..."];
            
            app.imgs = [];
            app.imgs_cpy = [];
            app.img_names = [];
            % load multiple or single images
            [file,path] = uigetfile({'*.*'}, 'Select a File',app.paths{2}, 'MultiSelect','on');
            
            
            %check if single
            
            if iscell(file)
                % if multiple selections 
                for i = 1:numel(file)
                    app.imgs{i} = imread(strcat(path, file{i}));
                    temp = file{i};
                    % get rid of file extension for .jpg
                    app.img_names{i} = temp(1:(end - 4));
                    
                    
                    % set list box values with img names
                    app.IndexiesListBox.Items = app.img_names;
                    % show first image
                    imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, 'Parent', app.UIAxes);
                end
            else
                if ischar(file) && ischar(path) 
                    app.imgs{1} = imread(strcat(path, file));
                    app.img_names{1} = file;
                    app.IndexiesListBox.Items = app.img_names;
                    imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, 'Parent', app.UIAxes);
    %                 imshow(app.p_img, 'Parent',app.UIAxes);
                end
            end
            app.imgs_cpy = app.imgs;
            app.results = cell(1, numel(app.imgs));
            
        end

        % Value changed function: IndexiesListBox
        function IndexiesListBoxValueChanged(app, event)
            imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, 'Parent', app.UIAxes);
%             value = app.IndexiesListBox.Value;
            
        end

        % Button pushed function: renameButton
        function renameButtonPushed(app, event)
            % rename index of image, essential for image registration 
            
            %find index 
            ind = strcmp(app.img_names, app.IndexiesListBox.Value);
            app.img_names{ind} = app.SliceNameEditField.Value;
            app.IndexiesListBox.Items = app.img_names;
            app.IndexiesListBox.Value = app.SliceNameEditField.Value;
        end

        % Value changed function: MonoSwitch
        function MonoSwitchValueChanged(app, event)
%             if strcmp(app.MonoSwitch.Value, 'Single')
%                 app.mono = true;
%             else
%                 app.mono = false;
%             end
            
        end

        % Button pushed function: BGSegmentationButton
        function BGSegmentationButtonPushed(app, event)
            %perform background segmentation, use input from drop down menu
            if strcmp(app.MonoSwitch.Value, 'Single')
                % compute index for selected image
                ind = find(strcmp(app.img_names, app.IndexiesListBox.Value));
                
                app.imgs_segmented{ind} = segment_img(app.imgs{ind}, app.DataPreDropDown.Value);
                
                app.imgs{ind} = app.imgs_segmented{ind};
                % where app.DataPreDropDown.Value, represents either GraphCut or KMRF option
            else
                for i = 1:numel(app.imgs)
                    app.imgs{i} = segment_img(app.imgs{i}, app.DataPreDropDown.Value);    
                end
            end
            imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, 'Parent', app.UIAxes);
            
        end

        % Button pushed function: GraphCutButton
        function GraphCutButtonPushed(app, event)
            % focuses on tab2 where a graph cut environment is set
            imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, 'Parent', app.GPAxes);
            app.super_dens = 0.5;
%             app.UIFigure.WindowButtonDownFcn  = @(src, evnt)disp(app.UIFigure.CurrentPoint);
                        
        end

        % Selection changed function: PixelAnnotationButtonGroup
        function PixelAnnotationButtonGroupSelectionChanged(app, event)

        end

        % Button pushed function: computeButton
        function computeButtonPushed(app, event)
            % use graph cut annotation vectors and compute segmentation
            app.graph_cut_segm([app.x_f, app.y_f], [app.x_b, app.y_b],app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)});
        end

        % Button pushed function: markpointsButton
        function markpointsButtonPushed(app, event)
            %create figure object
                DataFig = figure();

                %create close figure function
                DataFig.CloseRequestFcn = @(src, evnt)delete(src);
                
                imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}); 
                
                % create data cursor object
                dcm_obj = datacursormode(DataFig);
                set(dcm_obj,'DisplayStyle','datatip',...
                'SnapToDataVertex','off','Enable','on');
                
                %add callback function to dcm_bj
                dcm_obj.UpdateFcn = @(src,evnt)dateTipUpdateFcn(app,src,evnt); 
        end

        % Button pushed function: clearforegroundButton
        function clearforegroundButtonPushed(app, event)
            app.x_f = [];
            app.y_f = [];
            update_gp_visual(app,event, false);
        end

        % Button pushed function: clearbackgroundButton
        function clearbackgroundButtonPushed(app, event)
            app.x_b = [];
            app.y_b = [];
            update_gp_visual(app,event, false);
        end

        % Button pushed function: FinishButton
        function FinishButtonPushed(app, event)
            % clear points
            app.x_b = [];
            app.y_b = [];
            app.x_f = [];
            app.y_f = [];
            % update segmented image on main list
            app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)} = app.gp_img;
            imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, 'Parent', app.UIAxes);
        end

        % Selection change function: TabGroup
        function TabGroupSelectionChanged(app, event)
            selectedTab = app.TabGroup.SelectedTab.Title;
            if strcmp(selectedTab, 'Atlas') && isempty(app.atlas)
%                 app.atlas = load('/home/makis/Documents/MouseStrokeImageAnalysis/Data/subjects_results/myatlasv1.mat');
                app.atlas = load(strcat(app.paths{4}, '/myatlasv1.mat'));
                app.IndexListBox.Items = app.atlas.index_list;
                imshow(uint8(app.atlas.my_atlas(0.02).Img), 'Parent', app.AtlasAxes);
            end
                %             elseif strcmp(selectedTab, 'Atlas')
%                 app.IndexListBox.Items = app.atlas.index_list;
%                 imshow(uint8(app.atlas.my_atlas(0.02).Img), 'Parent', app.AtlasAxes);
%             end
        end

        % Value changed function: IndexListBox
        function IndexListBoxValueChanged(app, event)
            value = app.IndexListBox.Value;
            imshow(uint8(app.atlas.my_atlas(str2double(value)).Img), 'Parent', app.AtlasAxes);
        end

        % Button pushed function: RUNButton
        function RUNButtonPushed(app, event)
            % set original directory to return.
            original_dir = pwd;
            
%             % temporary 
%             app.model = true;
            
            if isempty(app.model)
               app.LogTextArea.Value = [app.LogTextArea.Value; "Model isnt loaded! Please load the model."; "Go to Settings -> load model."]; 
            else
                app.RIndexiesListBox.Items = cell(0,0);
                if strcmp(app.MonoSwitch.Value, 'Single')
                    
                    
                    % if working directory is not set, use default
                    if isempty(app.wor_dir)
                        app.wor_dir = app.paths{3};
                    end
                    
                    % reference is a struct containing AVG img, STD img and anatomical masks.
                    app.reference = find_reference_img(app, app.IndexiesListBox.Value);
                    
                    % create folder for each subject's analysis. Folder lies within original working path and is named by index and date.
                    create_processing_folder(app);
                    
                    % perform linear registration 
                    linear_registration_ui(app, app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, app.reference.Img);
                    
                    non_lin_reg_info = non_linear_registration(app.sub_T.index, app.save_dir, app.paths{5});

                    % load registered image
                    registered = niftiread(non_lin_reg_info.regi_output_path);
                    
                    zscore_out = compute_zscore(registered, app.reference, app.hemi_masks, app.sub_T.index, app.save_dir,...
                        non_lin_reg_info.inv_info.out_path, app.affine_data_S2A, app.paths{5});
                    
                    app.sub_T.zscore = zscore_out.zscore;
                    app.sub_T.ss_RHM = zscore_out.ss_RHM;
                    app.sub_T.ss_LHM = zscore_out.ss_LHM;
                    app.sub_T.registered = registered;
                    
                    imshow(app.sub_T.subject, 'Parent', app.ResAxes1);
                    imshow(app.sub_T.zscore,[3 10], 'Parent',app.ResAxes2);
                    colormap(app.ResAxes2, jet); 
                    
                    % create hemisphere difference features
                    hem_diff_features = create_hem_diff_feat(app.reference, app.sub_T.index, zscore_out, app.hemi_tr, app.affine_data_S2A, ...
                        non_lin_reg_info, app.save_dir, app.paths{4}, app.paths{5}, 'create_color_features', app.sub_T.subject);
                    
                    % create feature vector for both 13 and 19 features 
                    % decide hemisphere mask 
                    if zscore_out.hemi_flag == 1
                        hemi_mask = zscore_out.ss_RHM;
                    else
                        hemi_mask = zscore_out.ss_LHM;
                    end
                    
                    f_v_19 = create_ml_features(hemi_mask, 'subject', app.sub_T.subject, 'zscore',...
                        zscore_out.ss_zscore, 'zscore_dif', hem_diff_features.zsc_dif_ss, ...
                        'color_features', hem_diff_features.color_features);
                    
                    app.sub_T.lesion = ml_prediction(app.model, f_v_19, app.sub_T.subject);
                    
                    
%                     my_log(app, 'TEST--NON Linear Block');
%                     non_linear_registration(app);
%                     
%                     cmp_zscore(app);
%                     
%                     imshow(app.sub_T.subject, 'Parent', app.ResAxes1);
%                     imshow(app.sub_T.zscore,[3 10], 'Parent',app.ResAxes2);
%                     colormap(app.ResAxes2, jet); 
%                     
%                     app.sub_T.lesion = ml_lesion_pred(app);
% %                     create_nifti({app.sub_T.lesion}, app.save_dir, 'lesion_pred_ML', [0.021 0.021 0 1]);
%                     nifti_save(app,app.sub_T.lesion, 'lesion_pred_ML', app.save_dir);
%                         
%                     cmp_area_save_res(app, app.sub_T.lesion, app.sub_T.ss_LHM, app.sub_T.ss_RHM); 
                else
                    app.RIndexiesListBox.Items = app.img_names;
                    
                    for i = 1:numel(app.img_names)
                        app.IndexiesListBox.Value = app.img_names{i};
                        
                        % if working directory is not set, use default
                        if isempty(app.wor_dir)
                            app.wor_dir = app.paths{3};
                        end
                        
                        % reference is a struct containing AVG img, STD img and anatomical masks.
                        app.reference = find_reference_img(app, app.IndexiesListBox.Value);
                        
                        % create folder for each subject's analysis. Folder lies within original working path and is named by index and date.
                        create_processing_folder(app);
                        
                        % perform linear registration 
                        linear_registration_ui(app, app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, app.reference.Img);
                        
%                         non_linear_registration(app);
%                         
%                         cmp_zscore(app);
%                         
%                         imshow(app.sub_T.subject, 'Parent', app.ResAxes1);
%                         imshow(app.sub_T.zscore,[3 10], 'Parent',app.ResAxes2);
%                         colormap(app.ResAxes2, jet); 
%                         
%                         app.sub_T.lesion = ml_lesion_pred(app);
% %                         create_nifti({app.sub_T.lesion}, app.save_dir, 'lesion_pred_ML', [0.021 0.021 0 1]);
%                         nifti_save(app, app.sub_T.lesion, 'lesion_pred_ML', app.save_dir);
%                         
%                         cmp_area_save_res(app, app.sub_T.lesion, app.sub_T.ss_LHM, app.sub_T.ss_RHM); 
%                         
%                         app.results{i} = app.sub_T; 
                    end
                end
            end
            
            % return to original directory.
            cd(original_dir);
        end

        % Button pushed function: ChoosedirectoryButton
        function ChoosedirectoryButtonPushed(app, event)
            % set working directory for data processing and output files
            app.wor_dir = uigetdir(app.paths{3});
            
        end

        % Button pushed function: PCARotationButton
        function PCARotationButtonPushed(app, event)
            % perform pca rotation on images
            [~, app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}] = pcaV1(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)});
            imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, 'Parent', app.UIAxes);
        end

        % Button pushed function: loadmodelButton
        function loadmodelButtonPushed(app, event)
           if isempty(app.model)
                app.LogTextArea.Value = [app.LogTextArea.Value; "Load model..."];
%                 L = load('/home/makis/Documents/MouseStrokeImageAnalysis/Data/trainingData/strokes_4_10_20/mdl_16.mat');
                L = load(app.model_path);
                % get model from struct, assume matlab file with one variable
%                 names = fieldnames(L);
                try
                    app.model = L.model;
                catch exception
                    app.LogTextArea.Value = [app.LogTextArea.Value; getReport(exception)];
                end
                % display if .mat model file contains more than one variable
%                 if numel(names) ~= 1
%                     app.LogTextArea.Value = [app.LogTextArea.Value; "Matlab file **.m contains more than one variable!"; "Please input a model in a .mat file containg only the model variable."];
%                 else
%                     if strcmp(app.model_names{1}, 'mdl_16')
%                         app.model = L.mdl_16;
%                     elseif strcmp(app.model_names{1}, 'mdl_31')
%                         app.model = L.mdl_31;
%                     elseif strcmp(app.model_names{1}, 'mdl_11_3')
%                         app.model = L.mdl_11_3;
%                     end
% %                     app.model = getfield(L, names{1});
% %                     app.model = L.mdl_11_3;
%                     app.LogTextArea.Value = [app.LogTextArea.Value; "Model loaded!"];
%                 end
                
                
           else
               app.LogTextArea.Value = [app.LogTextArea.Value; "Model already loaded!"];
           end
        end

        % Value changed function: RD1DropDown
        function RD1DropDownValueChanged(app, event)
            value = app.RD1DropDown.Value;
            if strcmp(value, 'zscore')
                imshow(app.sub_T.zscore,[3 10], 'Parent', app.ResAxes1)
                colormap(app.ResAxes1, jet);
            elseif strcmp(value, 'reference')
                imshow(uint8(app.sub_T.reference.Img), 'Parent', app.ResAxes1)
            elseif strcmp(value, 'left_hemi')
                imshow( blend_img(app,app.sub_T.subject, app.sub_T.ss_LHM, 60), 'Parent', app.ResAxes1)
            elseif strcmp(value, 'right_hemi')
                imshow( blend_img(app,app.sub_T.subject, app.sub_T.ss_RHM, 60), 'Parent', app.ResAxes1)
            elseif strcmp(value, 'subject')
                imshow( app.sub_T.subject, 'Parent', app.ResAxes1)
            elseif strcmp(value, 'lesion_overlay')
                imshow( blend_img(app,app.sub_T.subject, app.sub_T.lesion, 60), 'Parent', app.ResAxes1)
            elseif strcmp(value, 'lesion')
                imshow(app.sub_T.lesion, 'Parent', app.ResAxes1)
            elseif strcmp(value, 'registered')
                imshow( uint8(app.sub_T.registered), 'Parent', app.ResAxes1)    
            end
            
        end

        % Value changed function: RD2DropDown
        function RD2DropDownValueChanged(app, event)
            value = app.RD2DropDown.Value;
            if strcmp(value, 'zscore')
                imshow(app.sub_T.zscore,[3 10], 'Parent', app.ResAxes2)
                colormap(app.ResAxes2, jet);                
            elseif strcmp(value, 'reference')
                imshow(uint8(app.sub_T.reference.Img), 'Parent', app.ResAxes2)
            elseif strcmp(value, 'left_hemi')
                imshow( blend_img(app,app.sub_T.subject, app.sub_T.ss_LHM, 60), 'Parent', app.ResAxes2)
            elseif strcmp(value, 'right_hemi')
                imshow( blend_img(app,app.sub_T.subject, app.sub_T.ss_RHM, 60), 'Parent', app.ResAxes2)
            elseif strcmp(value, 'subject')
                imshow( uint8(app.sub_T.subject), 'Parent', app.ResAxes2)
            elseif strcmp(value, 'lesion_overlay')
                imshow( blend_img(app,app.sub_T.subject, app.sub_T.lesion, 60), 'Parent', app.ResAxes2)
            elseif strcmp(value, 'registered')
                imshow( uint8(app.sub_T.registered), 'Parent', app.ResAxes2)
            end
        end

        % Button pushed function: reloadButton
        function reloadButtonPushed(app, event)
            app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)} = app.imgs_cpy{strcmp(app.img_names, app.IndexiesListBox.Value)}; 
            imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, 'Parent', app.UIAxes);
        end

        % Button pushed function: flipButton
        function flipButtonPushed(app, event)
            app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)} = flip(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)} , 2);
            imshow(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}, 'Parent', app.UIAxes);
        end

        % Value changed function: Slider
        function SliderValueChanged(app, event)
            app.super_dens = app.Slider.Value;
            
        end

        % Value changed function: RIndexiesListBox
        function RIndexiesListBoxValueChanged(app, event)
            if ~isempty(app.RIndexiesListBox.Items)
                value = app.RIndexiesListBox.Value;
                ind = strcmp(app.img_names, value);
                app.sub_T = app.results{ind};         
                imshow(app.sub_T.zscore,[3 10], 'Parent', app.ResAxes2); 
                colormap(app.ResAxes2, jet);
                app.RD2DropDown.Value = 'zscore';
                app.RD1DropDown.Value = 'lesion';
                imshow( blend_img(app,app.sub_T.subject, app.sub_T.lesion, 60), 'Parent', app.ResAxes1);
            end
            
        end

        % Button pushed function: histogramequalizationButton
        function histogramequalizationButtonPushed(app, event)
            disp('test');
        end

        % Button pushed function: lineartransformButton
        function lineartransformButtonPushed(app, event)
            app.reference = find_reference_img(app, app.IndexiesListBox.Value);
%             aff_out = app.linear_regi(rgb2gray(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}), app.reference.Img);
            aff_out = linear_registration(rgb2gray(app.imgs{strcmp(app.img_names, app.IndexiesListBox.Value)}),...
                app.reference.Img, "Ttype", app.SetDropDown.Value);
            imshow(imfuse(aff_out.RegisteredImage, app.reference.Img, 'falsecolor'), 'Parent', app.TestLinAxes);
        end

        % Button pushed function: markButton
        function markButtonPushed(app, event)

            if strcmp(app.MonoSwitch.Value, 'All')
                %select lesion mask
                value = app.RIndexiesListBox.Value;
                ind = strcmp(app.img_names, value);
                app.sub_T = app.results{ind}; 
            end
            
             %create figure object
            DataFig = figure();

            %create close figure function
            DataFig.CloseRequestFcn = @(src, evnt)delete(src);
            
            imshow(blend_img(app,app.sub_T.subject, app.sub_T.lesion, 60)); 
            
            % create data cursor object
            dcm_obj = datacursormode(DataFig);
            set(dcm_obj,'DisplayStyle','datatip',...
            'SnapToDataVertex','off','Enable','on');
            
            % create masks
            app.add_mask = zeros(size(app.sub_T.lesion));
            app.remove_mask = zeros(size(app.sub_T.lesion));
            
            %add callback function to dcm_bj
            dcm_obj.UpdateFcn = @(src,evnt)data_les_cor(app,src,evnt); 
        end

        % Button pushed function: finalButton
        function finalButtonPushed(app, event)
            app.sub_T.lesion = app.corrected_lesion;
            imshow( blend_img(app,app.sub_T.subject, app.sub_T.lesion, 60), 'Parent', app.ResAxes1);
            imshow(blend_img(app,app.sub_T.subject, app.sub_T.lesion, 60)); 

        end

        % Menu selected function: setmodelpathMenu
        function setmodelpathMenuSelected(app, event)
            % pop up window set path for model
            % use json "paths.json" file to store or read paths
            if ~isempty(app.paths)
                [file,path] = uigetfile({'*.mat*'}, 'Select a File',pwd, 'MultiSelect','off');
                if ischar(file) && ischar(path)
                    app.model_path = strcat(path, file);
                    app.paths{1} = app.model_path; 
                    
                    %update json file
                    write_paths(app);
                    
                    % update Text log 
                    app.LogTextArea.Value = [app.LogTextArea.Value; "Path for ML model, OK!"];
                end
            end
        end

        % Menu selected function: setsubjectpathMenu
        function setsubjectpathMenuSelected(app, event)
            dir = uigetdir(pwd);
           
            if ischar(dir)
                app.paths{2} = dir; 
                
                 %update json file
                 write_paths(app);
                 
                 % update Text log 
                 app.LogTextArea.Value = [app.LogTextArea.Value; "Path for subject/test directory, OK!"];
            end
             
        end

        % Menu selected function: setdefaultoutputdirMenu
        function setdefaultoutputdirMenuSelected(app, event)
            % set default ouput directory, update json file.
            dir = uigetdir(pwd);
           
            if ischar(dir)
                app.paths{3} = dir; 
                
                 %update json file
                 write_paths(app);
                 
                 % update Text log 
                 app.LogTextArea.Value = [app.LogTextArea.Value; "Path for default output directory, OK!"];
            end
        end

        % Menu selected function: setdependenciesdirMenu
        function setdependenciesdirMenuSelected(app, event)
            dir = uigetdir(pwd);
           
            if ischar(dir)
                app.paths{4} = dir; 
                
                 %update json file
                 write_paths(app);
                 
                 % update Text log 
                 app.LogTextArea.Value = [app.LogTextArea.Value; "Path for ui dependensies directory, OK!"];
            end
        end

        % Menu selected function: setdrammsdirMenu
        function setdrammsdirMenuSelected(app, event)
            dir = uigetdir(pwd);
           
            if ischar(dir)
                app.paths{5} = dir; 
                
                 %update json file
                 write_paths(app);
                 
                 % update Text log 
                 app.LogTextArea.Value = [app.LogTextArea.Value; "Path for dramms software, OK!"];
            end
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 779 576];
            app.UIFigure.Name = 'UI Figure';

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = 'File';

            % Create loadimagesMenu
            app.loadimagesMenu = uimenu(app.FileMenu);
            app.loadimagesMenu.MenuSelectedFcn = createCallbackFcn(app, @loadimagesMenuSelected, true);
            app.loadimagesMenu.Text = 'load images';

            % Create setmodelpathMenu
            app.setmodelpathMenu = uimenu(app.FileMenu);
            app.setmodelpathMenu.MenuSelectedFcn = createCallbackFcn(app, @setmodelpathMenuSelected, true);
            app.setmodelpathMenu.Text = 'set model path';

            % Create setsubjectpathMenu
            app.setsubjectpathMenu = uimenu(app.FileMenu);
            app.setsubjectpathMenu.MenuSelectedFcn = createCallbackFcn(app, @setsubjectpathMenuSelected, true);
            app.setsubjectpathMenu.Text = 'set subject path';

            % Create setdefaultoutputdirMenu
            app.setdefaultoutputdirMenu = uimenu(app.FileMenu);
            app.setdefaultoutputdirMenu.MenuSelectedFcn = createCallbackFcn(app, @setdefaultoutputdirMenuSelected, true);
            app.setdefaultoutputdirMenu.Text = 'set default output dir';

            % Create setdependenciesdirMenu
            app.setdependenciesdirMenu = uimenu(app.FileMenu);
            app.setdependenciesdirMenu.MenuSelectedFcn = createCallbackFcn(app, @setdependenciesdirMenuSelected, true);
            app.setdependenciesdirMenu.Text = 'set dependencies dir';

            % Create setdrammsdirMenu
            app.setdrammsdirMenu = uimenu(app.FileMenu);
            app.setdrammsdirMenu.MenuSelectedFcn = createCallbackFcn(app, @setdrammsdirMenuSelected, true);
            app.setdrammsdirMenu.Text = 'set dramms dir';

            % Create FigurePanel
            app.FigurePanel = uipanel(app.UIFigure);
            app.FigurePanel.Title = 'Figure Panel';
            app.FigurePanel.Position = [1 128 779 449];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.FigurePanel);
            app.TabGroup.SelectionChangedFcn = createCallbackFcn(app, @TabGroupSelectionChanged, true);
            app.TabGroup.Position = [1 0 778 432];

            % Create ImagesTab
            app.ImagesTab = uitab(app.TabGroup);
            app.ImagesTab.Title = 'Images';

            % Create IndexiesListBoxLabel
            app.IndexiesListBoxLabel = uilabel(app.ImagesTab);
            app.IndexiesListBoxLabel.HorizontalAlignment = 'right';
            app.IndexiesListBoxLabel.Position = [18 369 50 22];
            app.IndexiesListBoxLabel.Text = 'Indexies';

            % Create IndexiesListBox
            app.IndexiesListBox = uilistbox(app.ImagesTab);
            app.IndexiesListBox.Items = {'image1'};
            app.IndexiesListBox.ValueChangedFcn = createCallbackFcn(app, @IndexiesListBoxValueChanged, true);
            app.IndexiesListBox.Position = [83 319 100 74];
            app.IndexiesListBox.Value = 'image1';

            % Create renameButton
            app.renameButton = uibutton(app.ImagesTab, 'push');
            app.renameButton.ButtonPushedFcn = createCallbackFcn(app, @renameButtonPushed, true);
            app.renameButton.Position = [83 227 100 22];
            app.renameButton.Text = 'rename';

            % Create UIAxes
            app.UIAxes = uiaxes(app.ImagesTab);
            title(app.UIAxes, 'Main Display')
            xlabel(app.UIAxes, '')
            ylabel(app.UIAxes, '')
            app.UIAxes.Position = [206 15 571 378];

            % Create SliceNameEditFieldLabel
            app.SliceNameEditFieldLabel = uilabel(app.ImagesTab);
            app.SliceNameEditFieldLabel.HorizontalAlignment = 'right';
            app.SliceNameEditFieldLabel.Position = [1 248 67 22];
            app.SliceNameEditFieldLabel.Text = 'Slice Name';

            % Create SliceNameEditField
            app.SliceNameEditField = uieditfield(app.ImagesTab, 'text');
            app.SliceNameEditField.Position = [83 248 100 22];
            app.SliceNameEditField.Value = '** New Index **';

            % Create DataPreprocessingPanel
            app.DataPreprocessingPanel = uipanel(app.ImagesTab);
            app.DataPreprocessingPanel.Title = 'Data Preprocessing';
            app.DataPreprocessingPanel.Position = [36 1 155 207];

            % Create DataPreDropDown
            app.DataPreDropDown = uidropdown(app.DataPreprocessingPanel);
            app.DataPreDropDown.Items = {'K&SUPER', 'K&MRF'};
            app.DataPreDropDown.Position = [29 152 98 22];
            app.DataPreDropDown.Value = 'K&MRF';

            % Create BGSegmentationButton
            app.BGSegmentationButton = uibutton(app.DataPreprocessingPanel, 'push');
            app.BGSegmentationButton.ButtonPushedFcn = createCallbackFcn(app, @BGSegmentationButtonPushed, true);
            app.BGSegmentationButton.Position = [20 115 110 22];
            app.BGSegmentationButton.Text = 'BG Segmentation';

            % Create PCARotationButton
            app.PCARotationButton = uibutton(app.DataPreprocessingPanel, 'push');
            app.PCARotationButton.ButtonPushedFcn = createCallbackFcn(app, @PCARotationButtonPushed, true);
            app.PCARotationButton.Position = [25 81 100 22];
            app.PCARotationButton.Text = 'PCA Rotation';

            % Create MonoSwitch
            app.MonoSwitch = uiswitch(app.DataPreprocessingPanel, 'slider');
            app.MonoSwitch.Items = {'Single', 'All'};
            app.MonoSwitch.ValueChangedFcn = createCallbackFcn(app, @MonoSwitchValueChanged, true);
            app.MonoSwitch.Position = [55 14 45 20];
            app.MonoSwitch.Value = 'Single';

            % Create GraphCutButton
            app.GraphCutButton = uibutton(app.DataPreprocessingPanel, 'push');
            app.GraphCutButton.ButtonPushedFcn = createCallbackFcn(app, @GraphCutButtonPushed, true);
            app.GraphCutButton.Position = [25 48 100 22];
            app.GraphCutButton.Text = 'GraphCut';

            % Create reloadButton
            app.reloadButton = uibutton(app.ImagesTab, 'push');
            app.reloadButton.ButtonPushedFcn = createCallbackFcn(app, @reloadButtonPushed, true);
            app.reloadButton.Position = [16.5 286 76 22];
            app.reloadButton.Text = 'reload';

            % Create flipButton
            app.flipButton = uibutton(app.ImagesTab, 'push');
            app.flipButton.ButtonPushedFcn = createCallbackFcn(app, @flipButtonPushed, true);
            app.flipButton.Position = [103 286 80 22];
            app.flipButton.Text = 'flip';

            % Create GraphSegmTab
            app.GraphSegmTab = uitab(app.TabGroup);
            app.GraphSegmTab.Title = 'GraphSegm';

            % Create GPAxes
            app.GPAxes = uiaxes(app.GraphSegmTab);
            title(app.GPAxes, 'Graph Cut Segmentation')
            xlabel(app.GPAxes, '')
            ylabel(app.GPAxes, '')
            app.GPAxes.Position = [132 1 647 406];

            % Create PixelAnnotationButtonGroup
            app.PixelAnnotationButtonGroup = uibuttongroup(app.GraphSegmTab);
            app.PixelAnnotationButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @PixelAnnotationButtonGroupSelectionChanged, true);
            app.PixelAnnotationButtonGroup.Title = 'Pixel Annotation';
            app.PixelAnnotationButtonGroup.Position = [10 257 123 99];

            % Create foregroundButton
            app.foregroundButton = uitogglebutton(app.PixelAnnotationButtonGroup);
            app.foregroundButton.Text = 'foreground';
            app.foregroundButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.foregroundButton.Position = [11 46 100 22];
            app.foregroundButton.Value = true;

            % Create backgroundButton
            app.backgroundButton = uitogglebutton(app.PixelAnnotationButtonGroup);
            app.backgroundButton.Text = 'background';
            app.backgroundButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.backgroundButton.Position = [11 25 100 22];

            % Create eraseButton
            app.eraseButton = uitogglebutton(app.PixelAnnotationButtonGroup);
            app.eraseButton.Text = 'erase';
            app.eraseButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.eraseButton.Position = [11 4 100 22];

            % Create computeButton
            app.computeButton = uibutton(app.GraphSegmTab, 'push');
            app.computeButton.ButtonPushedFcn = createCallbackFcn(app, @computeButtonPushed, true);
            app.computeButton.BackgroundColor = [1 0.4118 0.1608];
            app.computeButton.Position = [21 164 100 22];
            app.computeButton.Text = 'compute';

            % Create clearbackgroundButton
            app.clearbackgroundButton = uibutton(app.GraphSegmTab, 'push');
            app.clearbackgroundButton.ButtonPushedFcn = createCallbackFcn(app, @clearbackgroundButtonPushed, true);
            app.clearbackgroundButton.BackgroundColor = [0.502 0.502 0.502];
            app.clearbackgroundButton.Position = [17 193 108 22];
            app.clearbackgroundButton.Text = 'clear background';

            % Create clearforegroundButton
            app.clearforegroundButton = uibutton(app.GraphSegmTab, 'push');
            app.clearforegroundButton.ButtonPushedFcn = createCallbackFcn(app, @clearforegroundButtonPushed, true);
            app.clearforegroundButton.BackgroundColor = [0.502 0.502 0.502];
            app.clearforegroundButton.Position = [18 223 103 22];
            app.clearforegroundButton.Text = 'clear foreground';

            % Create FinishButton
            app.FinishButton = uibutton(app.GraphSegmTab, 'push');
            app.FinishButton.ButtonPushedFcn = createCallbackFcn(app, @FinishButtonPushed, true);
            app.FinishButton.BackgroundColor = [0.4706 0.6706 0.1882];
            app.FinishButton.Position = [22 131 100 22];
            app.FinishButton.Text = 'Finish';

            % Create markpointsButton
            app.markpointsButton = uibutton(app.GraphSegmTab, 'push');
            app.markpointsButton.ButtonPushedFcn = createCallbackFcn(app, @markpointsButtonPushed, true);
            app.markpointsButton.BackgroundColor = [1 0.4118 0.1608];
            app.markpointsButton.Position = [22 369 100 22];
            app.markpointsButton.Text = 'mark points';

            % Create Slider
            app.Slider = uislider(app.GraphSegmTab);
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);
            app.Slider.Position = [33 106 75 3];
            app.Slider.Value = 50;

            % Create AtlasTab
            app.AtlasTab = uitab(app.TabGroup);
            app.AtlasTab.Title = 'Atlas';

            % Create AtlasAxes
            app.AtlasAxes = uiaxes(app.AtlasTab);
            title(app.AtlasAxes, 'TTC Atlas')
            xlabel(app.AtlasAxes, '')
            ylabel(app.AtlasAxes, '')
            app.AtlasAxes.Position = [223 1 554 406];

            % Create IndexListBoxLabel
            app.IndexListBoxLabel = uilabel(app.AtlasTab);
            app.IndexListBoxLabel.HorizontalAlignment = 'right';
            app.IndexListBoxLabel.Position = [50 332 35 22];
            app.IndexListBoxLabel.Text = 'Index';

            % Create IndexListBox
            app.IndexListBox = uilistbox(app.AtlasTab);
            app.IndexListBox.Items = {'Item 1', ''};
            app.IndexListBox.ValueChangedFcn = createCallbackFcn(app, @IndexListBoxValueChanged, true);
            app.IndexListBox.Position = [100 260 100 96];

            % Create ResultsTab
            app.ResultsTab = uitab(app.TabGroup);
            app.ResultsTab.Title = 'Results';

            % Create RIndexiesListBoxLabel
            app.RIndexiesListBoxLabel = uilabel(app.ResultsTab);
            app.RIndexiesListBoxLabel.HorizontalAlignment = 'right';
            app.RIndexiesListBoxLabel.Position = [13 371 59 22];
            app.RIndexiesListBoxLabel.Text = 'RIndexies';

            % Create RIndexiesListBox
            app.RIndexiesListBox = uilistbox(app.ResultsTab);
            app.RIndexiesListBox.Items = {};
            app.RIndexiesListBox.ValueChangedFcn = createCallbackFcn(app, @RIndexiesListBoxValueChanged, true);
            app.RIndexiesListBox.Position = [87 349 100 46];
            app.RIndexiesListBox.Value = {};

            % Create ResAxes1
            app.ResAxes1 = uiaxes(app.ResultsTab);
            title(app.ResAxes1, 'R Display 1')
            xlabel(app.ResAxes1, '')
            ylabel(app.ResAxes1, '')
            app.ResAxes1.PlotBoxAspectRatio = [1 0.861963190184049 0.861963190184049];
            app.ResAxes1.Position = [1 1 382 338];

            % Create ResAxes2
            app.ResAxes2 = uiaxes(app.ResultsTab);
            title(app.ResAxes2, 'R Display 2')
            xlabel(app.ResAxes2, '')
            ylabel(app.ResAxes2, '')
            app.ResAxes2.PlotBoxAspectRatio = [1 0.828908554572271 0.828908554572271];
            app.ResAxes2.Position = [382 1 395 338];

            % Create RD1DropDownLabel
            app.RD1DropDownLabel = uilabel(app.ResultsTab);
            app.RD1DropDownLabel.HorizontalAlignment = 'right';
            app.RD1DropDownLabel.Position = [260 361 30 22];
            app.RD1DropDownLabel.Text = 'RD1';

            % Create RD1DropDown
            app.RD1DropDown = uidropdown(app.ResultsTab);
            app.RD1DropDown.Items = {'zscore', 'reference', 'left_hemi', 'right_hemi', 'lesion', 'subject', 'lesion_overlay', 'registered'};
            app.RD1DropDown.ValueChangedFcn = createCallbackFcn(app, @RD1DropDownValueChanged, true);
            app.RD1DropDown.Position = [305 361 100 22];
            app.RD1DropDown.Value = 'zscore';

            % Create RD2DropDownLabel
            app.RD2DropDownLabel = uilabel(app.ResultsTab);
            app.RD2DropDownLabel.HorizontalAlignment = 'right';
            app.RD2DropDownLabel.Position = [473 361 30 22];
            app.RD2DropDownLabel.Text = 'RD2';

            % Create RD2DropDown
            app.RD2DropDown = uidropdown(app.ResultsTab);
            app.RD2DropDown.Items = {'zscore', 'reference', 'left_hemi', 'right_hemi', 'lesion', 'lesion_overlay', 'subject', 'registered'};
            app.RD2DropDown.ValueChangedFcn = createCallbackFcn(app, @RD2DropDownValueChanged, true);
            app.RD2DropDown.Position = [518 361 100 22];
            app.RD2DropDown.Value = 'zscore';

            % Create LinearTransfTab
            app.LinearTransfTab = uitab(app.TabGroup);
            app.LinearTransfTab.Title = 'Linear Transf';

            % Create TestLinAxes
            app.TestLinAxes = uiaxes(app.LinearTransfTab);
            title(app.TestLinAxes, 'Title')
            xlabel(app.TestLinAxes, '')
            ylabel(app.TestLinAxes, '')
            app.TestLinAxes.Position = [240 1 537 406];

            % Create lineartransformButton
            app.lineartransformButton = uibutton(app.LinearTransfTab, 'push');
            app.lineartransformButton.ButtonPushedFcn = createCallbackFcn(app, @lineartransformButtonPushed, true);
            app.lineartransformButton.Position = [119 327 100 22];
            app.lineartransformButton.Text = 'linear transform';

            % Create LogTextAreaLabel
            app.LogTextAreaLabel = uilabel(app.UIFigure);
            app.LogTextAreaLabel.HorizontalAlignment = 'right';
            app.LogTextAreaLabel.Position = [201 105 26 22];
            app.LogTextAreaLabel.Text = 'Log';

            % Create LogTextArea
            app.LogTextArea = uitextarea(app.UIFigure);
            app.LogTextArea.Position = [242 1 536 128];

            % Create TabGroup2
            app.TabGroup2 = uitabgroup(app.UIFigure);
            app.TabGroup2.Position = [2 1 186 126];

            % Create ControlTab
            app.ControlTab = uitab(app.TabGroup2);
            app.ControlTab.Title = 'Control';

            % Create RUNButton
            app.RUNButton = uibutton(app.ControlTab, 'push');
            app.RUNButton.ButtonPushedFcn = createCallbackFcn(app, @RUNButtonPushed, true);
            app.RUNButton.BackgroundColor = [0.4706 0.6706 0.1882];
            app.RUNButton.FontWeight = 'bold';
            app.RUNButton.Position = [40 24 106 22];
            app.RUNButton.Text = 'RUN';

            % Create ChoosedirectoryButton
            app.ChoosedirectoryButton = uibutton(app.ControlTab, 'push');
            app.ChoosedirectoryButton.ButtonPushedFcn = createCallbackFcn(app, @ChoosedirectoryButtonPushed, true);
            app.ChoosedirectoryButton.Position = [40 62 106 22];
            app.ChoosedirectoryButton.Text = 'Choose directory';

            % Create SettingsTab
            app.SettingsTab = uitab(app.TabGroup2);
            app.SettingsTab.Title = 'Settings';

            % Create loadmodelButton
            app.loadmodelButton = uibutton(app.SettingsTab, 'push');
            app.loadmodelButton.ButtonPushedFcn = createCallbackFcn(app, @loadmodelButtonPushed, true);
            app.loadmodelButton.Position = [43 71 100 22];
            app.loadmodelButton.Text = 'load model';

            % Create histogramequalizationButton
            app.histogramequalizationButton = uibutton(app.SettingsTab, 'push');
            app.histogramequalizationButton.ButtonPushedFcn = createCallbackFcn(app, @histogramequalizationButtonPushed, true);
            app.histogramequalizationButton.Position = [25 10 136 22];
            app.histogramequalizationButton.Text = 'histogram equalization';

            % Create SetDropDown
            app.SetDropDown = uidropdown(app.SettingsTab);
            app.SetDropDown.Items = {'similarity', 'translation', 'rigid', 'affine'};
            app.SetDropDown.Position = [43 40 100 22];
            app.SetDropDown.Value = 'similarity';

            % Create LesionCorrectionTab
            app.LesionCorrectionTab = uitab(app.TabGroup2);
            app.LesionCorrectionTab.Title = 'Lesion Correction';

            % Create markButton
            app.markButton = uibutton(app.LesionCorrectionTab, 'push');
            app.markButton.ButtonPushedFcn = createCallbackFcn(app, @markButtonPushed, true);
            app.markButton.Position = [12 73 100 22];
            app.markButton.Text = 'mark';

            % Create Switch
            app.Switch = uiswitch(app.LesionCorrectionTab, 'rocker');
            app.Switch.Items = {'Add', 'Remove'};
            app.Switch.FontWeight = 'bold';
            app.Switch.Position = [139 29 20 45];
            app.Switch.Value = 'Add';

            % Create finalButton
            app.finalButton = uibutton(app.LesionCorrectionTab, 'push');
            app.finalButton.ButtonPushedFcn = createCallbackFcn(app, @finalButtonPushed, true);
            app.finalButton.Position = [12 8 100 22];
            app.finalButton.Text = 'final';

            % Create Radius
            app.Radius = uispinner(app.LesionCorrectionTab);
            app.Radius.Limits = [1 20];
            app.Radius.Position = [12 40 97 22];
            app.Radius.Value = 5;
        end
    end

    methods (Access = public)

        % Construct app
        function app = stroke_analyst_ui

            % Create and configure components
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