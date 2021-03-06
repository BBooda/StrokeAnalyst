%% aquire data to run, set variables
addpath(genpath("/home/makis/Documents/GitRepos/StrokeAnalyst"));
dramms_path = "home/makis/myprograms/dramms/bin";
atlas_path = "/home/makis/Documents/GitRepos/data_dependencies";
output_folder_path = "/home/makis/Documents/GitRepos/processing_folder";
% aquire atlas 
ttc_atlas = load(strcat(atlas_path, '/myatlasv1.mat'));

% load hemisphere transformations 
hemi_tr = load(strcat(atlas_path, '/hemisphere_transformations','/hemisphere_transformations.mat'));
%% run folder
indexies_c = {'bn0_22', 'bn1_82', 'bn3_08', 'bp1_34'};
for i = 1:numel(indexies_c)
    path = strcat(folder_path, '/', indexies_c{i}, '.jpg');
    
    
    subject = imread(path);
    index = path(end - 9: end - 4);
    
    %set variables
%     if exist('subject_info', 'var')
%         subject = subject_info.subject;
%         reference = subject_info.reference;
%         index = subject_info.index; 
%     else
%         if ~exist('subject', 'var')
%             subject = imread(path);
%     %         index = input("specify brain slice index:",'s');
%             index = path(end - 9: end - 4);
%         end
%     end

    reference = find_atlas_img(index, ttc_atlas);

    % register to ttc_atlas 

    save_dir = create_processing_folder(index, output_folder_path);

    % perform linear registration 
    [lin_out, tform, movingRefObj,fixedRefObj] = linear_registration(rgb2gray(subject), reference.Img);

    % create nifti images to work with dramms
    % name convention: affine data subject to atlas
    affine_data_S2A = create_affine_data(lin_out, subject, reference.Img, index, save_dir, movingRefObj, fixedRefObj);

    % perform non linear registration
    non_lin_reg_info = non_linear_registration(index, save_dir, dramms_path);

    % load registered image
    registered = niftiread(non_lin_reg_info.regi_output_path);

    % load hemisphere masks 
    hemisphere_masks = load(strcat(atlas_path, '/hemisphere_masks.mat'));
    hemisphere_masks = hemisphere_masks.hemi_m;

    zscore_out = compute_zscore(registered, reference, hemisphere_masks, index, save_dir, non_lin_reg_info.inv_info.out_path, affine_data_S2A, dramms_path);

    % create hemisphere difference features
    hem_diff_features = create_hem_diff_feat(reference, index, zscore_out, hemi_tr, affine_data_S2A, ...
        non_lin_reg_info, save_dir, atlas_path, dramms_path, 'create_color_features', subject);

    % create feature vector for both 13 and 19 features 
    % decide hemisphere mask 
    if zscore_out.hemi_flag == 1
        hemi_mask = zscore_out.ss_RHM;
    else
        hemi_mask = zscore_out.ss_LHM;
    end
    % create training data object
    training_data.subject = bsxfun(@times, subject, cast(hemi_mask, 'like', subject));

    f_v_13 = create_ml_features(hemi_mask, 'subject', subject, 'zscore',...
        zscore_out.ss_zscore, 'zscore_dif', hem_diff_features.zsc_dif_ss);

    f_v_19 = create_ml_features(hemi_mask, 'subject', subject, 'zscore',...
        zscore_out.ss_zscore, 'zscore_dif', hem_diff_features.zsc_dif_ss, ...
        'color_features', hem_diff_features.color_features);

    training_data.f_v_13 = f_v_13;
    training_data.f_v_19 = f_v_19;  
    
    disp(['finished with feature creatin at index: ', index])

    ml_p = ml_prediction(model, f_v_19, subject);
%     imshow(ml_p);

    imwrite(ml_p, strcat(save_dir,'/',index, '_pre.jpg'))
    saveExcept(convertStringsToChars(strcat(save_dir, '/all')), 'model');
    
end