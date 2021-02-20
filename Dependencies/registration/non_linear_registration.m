function non_linear_registration(file_name, save_dir, dramms_path)
    %determine reference image (atlas image) path.
    ref_path = strcat(save_dir, '/reference.nii');

    % determine path for linearly transformed image
    sub_aff_path = strcat(save_dir, '/aff_sub_to_average.nii');

    % non linearly registered subject path
    regi_sub_path = save_dir;

    %call dramms, perform non linear registration
    dramms_2dregistration(ref_path,sub_aff_path,regi_sub_path, file_name, dramms_path);

    % inverse deformation field
    %deternine deformation field path 
    dfield_path = strcat(save_dir, '/dfield');
    dramms_inverse_dfield(dfield_path, save_dir, dramms_path);
            
end