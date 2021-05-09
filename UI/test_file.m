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