function out = create_img_hem_diff(img, name,affine_info, dfield_path, dramms_dir,save_dir)
    % zscore already exists in TTC atlas space, so load affine info 
    % for atlas hemisphere transformation 
    movingRefObj_T1 = affine_info.mov;
    fixedRefObj_T1 = affine_info.fixed;
    
    % flip zscore 
    img_flip = flip(img, 2);
    
    % linearly transform zscore to it self 
    lin_transf = imwarp(img_flip, movingRefObj_T1, affine_info.T.Transformation, 'OutputView', fixedRefObj_T1, 'SmoothEdges', true);
    
    % save linearly transformed img to directory
    nifti_save(lin_transf, name, save_dir);
    
    img_lin_path = strcat(save_dir, '/', name);
%     zscore_lin = niftiread(strcat(zscore_lin_path);
    
    % nonlinearly transform of fliped zscore AT TTC ATLAS SPACE
    dramms_warp(img_lin_path ,dfield_path, save_dir, strcat('ss_fliped_', name), dramms_dir);
    
    img_fliped_registered = niftiread(strcat(strcat(save_dir, '/', strcat('ss_fliped_', name),'.nii')));
        
    % compute zscore hemisphere difference
    as_diff_img = abs(img - img_fliped_registered);
    
    nifti_save(as_diff_img, strcat('as_diff_', name), save_dir);
    
    as_diff_img_path = strcat(save_dir, '/', strcat('as_diff_', name));
    
    out.img_diff_atlas_space = as_diff_img;
    out.img_fliped_registered = img_fliped_registered;
    out.img_fliped_registered_path = as_diff_img_path;
end