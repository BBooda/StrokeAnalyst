% create visualization data for updated ttc atlas
% define save_dir
save_d = "/home/makis/Documents/GitRepos/data_dependencies/atlas_final/atlas_updated_imgs";

try 
    load('registered.mat');

    imwrite(uint8(a_slice), strcat(save_d, '/', index, '_avg.jpg'));
    imwrite(adapthisteq(uint8(a_slice)), strcat(save_d, '/', index, 'ench_avg.jpg'));
    imwrite(uint8(S), strcat(save_d, '/', index, '_std.jpg'));
    
catch exception
    disp("no registered.m in directory");
end

%% create visualization data 
% save lesion mask, hemisphere masks, zscore map, registered slice and
% reference slice
% READ ME
% 1. Define parent folder containg sub folders that contain a all.mat file
% 2. load allen masks and json dictionary 
% load allen masks and anatomical regions dictionary
atlas_path = "/home/makis/Documents/GitRepos/data_dependencies";
allen_masks = load(fullfile(atlas_path, 'allen_masks.mat'));
allen_masks = allen_masks.allen_masks;

fname = strcat(atlas_path, '/acronyms.json');
fid = fopen(fname);
raw = fread(fid,inf);
str = char(raw');
dictionary = jsondecode(str);

%% continue execution

parent_folder = '/home/makis/Documents/GitRepos/processing_folder/finalTests/-n003-14a';
S = dir(fullfile(parent_folder));

return_adr = S(1).folder;

folders = cell(1, length(S));
folder_name = cell(1, length(S));
for i = 1:length(S)
    if length(S(i).name) > 2 && S(i).isdir
        folders{i} = fullfile(S(i).folder, S(i).name);
        folder_name{i} = S(i).name;
    end
end
folders(cellfun('isempty',folders)) = [];
folder_name(cellfun('isempty',folder_name)) = [];

for i = 1:length(folders)
    load(fullfile(folders{i}, 'all.mat'));
    
    % workaround 
    original_save_dir = save_dir;
    
    % create visualization data directory
    temp = strsplit(save_dir, 'er/');
    temp = strcat(temp(1), 'er/');
    mkdir(temp, strcat('vis_',num2str(index)));
    save_dir = strcat(temp, strcat('vis_',num2str(index)));
    
    % compute volumetric data 
    compute_volumetric_data(ml_p, zscore_out.ss_LHM, zscore_out.ss_RHM, index, save_dir)
    
    % save registered and reference
    imwrite(uint8(registered), strcat(save_dir, "/", num2str(index), "_registered.jpg"));
    imwrite(uint8(reference.Img), strcat(save_dir, "/", num2str(index), "_reference.jpg"));

    % create lesion overlays
    les = blend_img(subject, ml_p, 60);
    imwrite(les, strcat(save_dir, "/", num2str(index), ".jpg"));

    left_hemi = blend_img(subject, zscore_out.ss_LHM, 60);
    imwrite(left_hemi, strcat(save_dir, "/left_", num2str(index), ".jpg"));

    right_hem = blend_img(subject, zscore_out.ss_RHM, 60);
    imwrite(right_hem, strcat(save_dir, "/right_", num2str(index), ".jpg"));
    fig = figure();
    imshow(zscore_out.zscore, [3 10]); colormap(jet);
    saveas(fig, strcat(save_dir, "/zscore_", num2str(index), ".jpg"));
    close(fig);
    
    % workaround to use absolute paths from all.mat file
    % this is mandatory for affected region identification 
    % steps: 1. move folder to its original location, 2. perform all
    % necessary actions 3. move folder back
    movefile(folders{i}, "/home/makis/Documents/GitRepos/processing_folder");
    
    % affected region identification
    % load masks, etc. call function
    % transform ml_p to atlas space for region naming 
    try
        ml_p_atlas_s = transform_to_as(ml_p, 'ml_prediction_as', ...
            affine_data_S2A, non_lin_reg_info.regi_output_path_dfield, ...
            save_dir, dramms_path);
    
        region_naming(dictionary, allen_masks, index, ...
            ml_p_atlas_s.def_transformed_img, original_save_dir)
    catch
        disp("region namining exeption");
    end
    
    % move folder back 
    movefile(fullfile("/home/makis/Documents/GitRepos/processing_folder" , folder_name{i}),...
        return_adr);
    
    try
        % copy file to affect regions txt to visualization folder
        copyfile(fullfile(folders{i}, "affected_regions.txt"), save_dir);
    catch
        disp('affected_regions.txt does not exist');
    end
    
    try
        % remove transformation .nii files
        nii_paths = dir(fullfile(save_dir, '*.nii'));
        for j = 1:length(nii_paths)
            delete(fullfile(test(j).folder,test(j).name));
        end
    catch
        disp('remove file exeption');
    end
end

disp("----------FINISHED------------");
   