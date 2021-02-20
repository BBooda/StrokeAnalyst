function zscore_out = compute_zscore(registered, reference, hemi_masks, index, save_dir, inv_dfield_path, lin_transf, dramms_dr)
%     % determine th path of registered subject
%     subj_reg_path = strcat(app.save_dir, '/registered_', app.IndexiesListBox.Value, '_to_average.nii');

    % load registerd subject
%      subject_registered = uint8(niftiread(subj_reg_path));
%      app.sub_T.registered = subject_registered;

    % set original threshold for zscore calculation
    threshold = 3;

    % determine hemispheres
    mid_th = compute_midline_threshold(reference.Img);

    % cmp zscore image
    zscore = double(double(registered)-reference.Img)./reference.STD;

    % save zscore 
    zscore_out.zscore = zscore;

    % apply threshold and compute mask indicating points with a value > 3 STD
    abn_img = zscore > threshold;
    
    % compute hemisphere masks. Currently using two techniques (this is just temporary).
    if hemi_masks.isKey(index)
        % 8 January hemisphere changes.
        right_hem_mask = hemi_masks(index).Right;
        left_hem_mask = hemi_masks(index).Left;

        %determine ubnormal hemisphere
        abn_right = right_hem_mask.* abn_img;
        abn_left = left_hem_mask.* abn_img;
        if (sum(abn_right(:) > 0) > sum(abn_left(:) > 0))
            zscore_out.hemi_flag = 1;
        else
            zscore_out.hemi_flag = 0;
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

         zscore_out.hemi_flag = 0; % if hemi flag = 0, lesion hemisphere is left, else for hemi_flag = 1, lesion hemisphere = right

         %check wich hemisphere presents bigger abnormality(area wise)
         if length(x2) > length(x1)
            x1 = x2;
            y1 = y2;
            zscore_out.hemi_flag = 1;
         end

         abn_img = zeros(size(zscore));
         for i = 1:length(y1)
            abn_img(y1(i), x1(i)) = 1;
         end

         %compute masks for right and left hemisphere
         [suby, subx] = find(registered(:,:) ~= 0);
         right_hem_mask = zeros(size(registered));
         left_hem_mask = zeros(size(registered));
         for i = 1:length(subx)
            if subx(i) >= mid_th
                right_hem_mask(suby(i), subx(i)) = 1;
            else
                left_hem_mask(suby(i), subx(i)) = 1;
            end
         end
    end


     %pass to output
     zscore_out.right_hem_mask = right_hem_mask;
     zscore_out.left_hem_mask = left_hem_mask;

     % compute hemisphere masks at subject space 
%              create_nifti({right_hem_mask}, app.save_dir, 'right_hem_mask_atlas_space', [0.021 0.021 0 1]);
%              create_nifti({left_hem_mask}, app.save_dir, 'left_hem_mask_atlas_space', [0.021 0.021 0 1]);
     nifti_save(right_hem_mask, 'right_hem_mask_atlas_space', save_dir);
     nifti_save(left_hem_mask, 'left_hem_mask_atlas_space', save_dir);
     
     % create zscore nifti file, exclude unwanted values
     zscore(isnan(zscore(:))) = 0;
     zscore(isinf(zscore(:))) = 20;
     nifti_save(zscore, 'zscore_atlas_space', save_dir);

     % set paths for dramms, apply inv deformation field.
     zscore_out.r_h_mask_path = strcat(save_dir, '/right_hem_mask_atlas_space');
     zscore_out.l_h_mask_path = strcat(save_dir, '/left_hem_mask_atlas_space');
     zscore_out.zscore_path = strcat(save_dir, '/zscore_atlas_space');
     
     % inverse non linear transformation on hemisphere masks
     dramms_warp(zscore_out.r_h_mask_path,inv_dfield_path, save_dir, 'right_h_mask_inversedDf', dramms_dr);
     dramms_warp(zscore_out.l_h_mask_path,inv_dfield_path, save_dir, 'left_h_mask_inversedDf', dramms_dr);
     dramms_warp(zscore_out.zscore_path,inv_dfield_path, save_dir, 'zscore_inversedDf', dramms_dr);

     % read inverse linear transformation on hemi masks
     inv_rhem_mask = 255*uint8(niftiread(strcat(save_dir, '/right_h_mask_inversedDf.nii')));
     inv_lhem_mask = 255*uint8(niftiread(strcat(save_dir, '/left_h_mask_inversedDf.nii')));
     inv_zscore = niftiread(strcat(save_dir, '/zscore_inversedDf.nii'));     
     
     subject_space_rhem_mask = imwarp(imbinarize(inv_rhem_mask), lin_transf.fixedRefObj, lin_transf.inv_aff, ...
         'OutputView', lin_transf.movingRefObj, 'SmoothEdges', true);

     subject_space_lhem_mask = imwarp(imbinarize(inv_lhem_mask), lin_transf.fixedRefObj, lin_transf.inv_aff, ... 
         'OutputView', lin_transf.movingRefObj, 'SmoothEdges', true);
     
     ss_zscore= imwarp(inv_zscore, lin_transf.fixedRefObj, lin_transf.inv_aff, ... 
         'OutputView', lin_transf.movingRefObj, 'SmoothEdges', true);

     zscore_out.ss_RHM = subject_space_rhem_mask;
     zscore_out.ss_LHM = subject_space_lhem_mask;
     zscore_out.ss_zscore = ss_zscore;
end