function out = create_zscore_flip(zscore, affine_info, dfield_path, dramms_dir,save_dir)
    % !!create zscore difference feature!!
    % zscore already exists in TTC atlas space, so load affine info 
    % for atlas hemisphere transformation 
    movingRefObj_T1 = affine_info.mov;
    fixedRefObj_T1 = affine_info.fixed;
    
    % flip zscore 
    zsc_flip = flip(zscore, 2);
    
    % linearly transform zscore to it self 
    zsc_aff = imwarp(zsc_flip, movingRefObj_T1, affine_info.T.Transformation, 'OutputView', fixedRefObj_T1, 'SmoothEdges', true);
    
    % save linearly transformed z-score to directory
    nifti_save(zsc_aff, 'zsc_f_linear_tr', save_dir);
    
    zscore_lin_path = strcat(save_dir, '/zsc_f_linear_tr');
%     zscore_lin = niftiread(strcat(zscore_lin_path);
    
    % nonlinearly transform of fliped zscore AT TTC ATLAS SPACE
    dramms_warp(zscore_lin_path,dfield_path, save_dir, 'ss_fliped_zscore', dramms_dir);
    
    zscore_fliped_registered = niftiread(strcat(strcat(save_dir, '/ss_fliped_zscore.nii')));
        
    % compute zscore hemisphere difference
    zscore_diff_atlas_space = abs(zscore - zscore_fliped_registered);
    
    nifti_save(zscore_diff_atlas_space, 'zscore_diff_as', save_dir);
    
    zscore_fliped_registered_path = strcat(save_dir, '/zscore_diff_as');
    
    out.zscore_diff_atlas_space = zscore_diff_atlas_space;
    out.zscore_fliped_registered = zscore_fliped_registered;
    out.zscore_fliped_registered_path = zscore_fliped_registered_path;
end