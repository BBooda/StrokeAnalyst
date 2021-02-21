function out = transform_to_as(img, name, linear_transf, dfield_path, save_dir, dramms_dir)
    % transform image from subject space to atlas space

    % linearly transform img 
    lin_transf = imwarp(img, linear_transf.movingRefObj, linear_transf.aff_out.Transformation, ...
             'OutputView', linear_transf.fixedRefObj, 'SmoothEdges', true);
         
    % create nifti file 
    nifti_save(lin_transf, strcat(name, '_lin_transformed'), save_dir);
    
    % create path 
    lin_transf_path = strcat(save_dir, '/', name, '_lin_transformed');
    
    dramms_warp(lin_transf_path, dfield_path, save_dir, strcat(name, '_def_transformed'), dramms_dir);
    
    out.def_tranformed_path = strcat(save_dir, '/', name, '_def_transformed.nii');
    
    out.lin_transf_path = lin_transf_path;
    
    out.def_transformed_img = niftiread(out.def_tranformed_path);
    
end