function affine_data = create_affine_data(aff_out, subject, reference, index, save_dir, movingRefObj, fixedRefObj)
    % save affine information
    affine_data.index = index;
    affine_data.subject = subject;
    affine_data.reference = reference;
    affine_data.aff_out = aff_out;
    affine_data.movingRefObj = movingRefObj;
    affine_data.fixedRefObj = fixedRefObj;
    affine_data.inv_aff = invert(aff_out.Transformation);
    
    % create nifti files, prepare for dramms registration
    % reference/FIXED image
    nifti_save(reference, 'reference', save_dir);
    % linearly registered image
    nifti_save(aff_out.RegisteredImage, 'aff_sub_to_average', save_dir);
end