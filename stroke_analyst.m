%% aquire data to run, set variables
addpath(genpath(pwd));
dramms_path = "home/makis/myprograms/dramms/bin";
atlas_path = "/home/makis/Documents/GitRepos/data_dependencies";
output_folder_path = "/home/makis/Documents/GitRepos/processing_folder";

%set variables
if exist('subject_info', 'var')
    subject = subject_info.subject;
    reference = subject_info.reference;
    index = subject_info.index; 
else
    if ~exist('subject', 'var')
        subject = imread(path);
        index = 'bp0_86';
    end
end

% aquire atlas 
ttc_atlas = load(strcat(atlas_path, '/myatlasv1.mat'));
reference = find_atlas_img(index, ttc_atlas);

% load hemisphere transformations 
hemi_tr = load(strcat(atlas_path, '/hemisphere_transformations','/hemisphere_transformations.mat'));

%% register to ttc_atlas 

% create training data object
training_data.subject = subject;

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

hem_diff_features = create_hem_diff_feat(reference, index, zscore_out, hemi_tr, affine_data_S2A, ...
    non_lin_reg_info, save_dir, atlas_path, dramms_path);

