%% aquire data to run, set variables
addpath(genpath(pwd));
dramms_path = "home/makis/myprograms/dramms/bin";
atlas_path = "/home/makis/Documents/GitRepos/data_dependencies";
output_folder_path = "/home/makis/Documents/GitRepos/processing_folder";

% load allen masks and anatomical regions dictionary
allen_masks = load(fullfile(atlas_path, 'allen_masks.mat'));
allen_masks = allen_masks.allen_masks;

fname = strcat(atlas_path, '/acronyms.json');
fid = fopen(fname);
raw = fread(fid,inf);
str = char(raw');
dictionary = jsondecode(str);

%set variables
if exist('subject_info', 'var')
    subject = subject_info.subject;
    reference = subject_info.reference;
    index = subject_info.index; 
else
    if ~exist('subject', 'var')
        subject = imread(path);
%         index = input("specify brain slice index:",'s');
        index = path(end - 9: end - 4);
    end
end

% aquire atlas 
ttc_atlas = load(strcat(atlas_path, '/myatlasv1.mat'));
reference = find_atlas_img(index, ttc_atlas);

% load hemisphere transformations 
hemi_tr = load(strcat(atlas_path, '/hemisphere_transformations','/hemisphere_transformations.mat'));

%% register to ttc_atlas 

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

ml_p = ml_prediction(model, f_v_19, subject);
% imshow(ml_p);

imwrite(ml_p, strcat(save_dir,'/',index, '_pre.jpg'))
saveExcept(convertStringsToChars(strcat(save_dir, '/all')), 'model');

% save data to visualization folder 
mkdir(save_dir, strcat('vis_',index));
new_save_dir = fullfile(save_dir, strcat('vis_',index));

compute_volumetric_data(ml_p, zscore_out.ss_LHM, zscore_out.ss_RHM, index, new_save_dir)

% transform ml_p to atlas space for region naming 
ml_p_atlas_s = transform_to_as(ml_p, 'ml_prediction_as', ...
        affine_data_S2A, non_lin_reg_info.regi_output_path_dfield, ...
        save_dir, dramms_path);

region_naming(dictionary, allen_masks, index, ml_p_atlas_s.def_transformed_img, new_save_dir);

% save images 
% save registered and reference
imwrite(uint8(registered), strcat(new_save_dir, "/", num2str(index), "_registered.jpg"));
imwrite(uint8(reference.Img), strcat(new_save_dir, "/", num2str(index), "_reference.jpg"));

% create lesion overlays
les = blend_img(subject, ml_p, 60);
imwrite(les, strcat(new_save_dir, "/", num2str(index), ".jpg"));

left_hemi = blend_img(subject, zscore_out.ss_LHM, 60);
imwrite(left_hemi, strcat(new_save_dir, "/left_", num2str(index), ".jpg"));

right_hem = blend_img(subject, zscore_out.ss_RHM, 60);
imwrite(right_hem, strcat(new_save_dir, "/right_", num2str(index), ".jpg"));
fig = figure();
imshow(zscore_out.zscore, [3 10]); colormap(jet);
saveas(fig, strcat(new_save_dir, "/zscore_", num2str(index), ".jpg"));
close(fig);

disp("---------FINISHED---------");