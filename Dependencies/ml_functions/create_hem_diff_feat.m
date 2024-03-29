function features = create_hem_diff_feat(reference, index, zscore_out, hemi_tr, affine_data_S2A, ...
    non_lin_reg_info, save_dir, atlas_path, dramms_path, varargin)
    % orchestration function to create hemisphere features
    % create hemisphere difference features
    % perform hemisphere registration
    % create hemisphere features 
    hem_registration = register_atlas_hemisphere(reference, index, zscore_out.hemi_flag, hemi_tr, save_dir, atlas_path, dramms_path);

    zscore_fliped_diff = create_zscore_flip(zscore_out.zscore ...
        , hem_registration.linear_transf, hem_registration.dfield_path ...
        , dramms_path, save_dir);

    % compute zscore difference feature. Note: need to isolate affected
    % hemisphere.
    zscore_fliped_diff_ss = transform_to_ss(zscore_fliped_diff.zscore_fliped_registered_path ...
        , affine_data_S2A, non_lin_reg_info.inv_info.out_path ...
        , 'zscore_fliped_diff_ss', dramms_path, save_dir);
    
    features.zsc_dif_ss = zscore_fliped_diff_ss.img_ss;
    
    % if specified as a key value pair, create color hemisphere features 
    if ~isempty(varargin)
        if strcmp(varargin{1}, "create_color_features") && ~isempty(varargin{2})
            color_features = create_hem_diff_color_features(varargin{2}, hem_registration, ...
                affine_data_S2A, non_lin_reg_info, save_dir, dramms_path);
            features.color_features = color_features;
        end
    end
    
end