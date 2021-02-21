function out = transform_to_ss(img_path, linear_T, dfield_path, name, dramms_dir, save_dir)
    % transform image to subject space
    % inverse deformable registration 
    fixedRefObj = linear_T.fixedRefObj;
    movingRefObj = linear_T.movingRefObj;
    inv_linear_transf = linear_T.inv_aff;
    
    dramms_warp(img_path, dfield_path, save_dir, name, dramms_dir);

    inv_def_img = niftiread(strcat(save_dir, '/',name, '.nii'));
    
    img_ss = imwarp(inv_def_img, fixedRefObj, inv_linear_transf, ...
            'OutputView', movingRefObj, 'SmoothEdges', true);   
    
    out.img_ss = img_ss;    
end