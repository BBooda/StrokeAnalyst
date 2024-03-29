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
% load('all');

parent_folder = '/home/makis/Documents/GitRepos/processing_folder/finalTests/-n003-4_back';
S = dir(fullfile(parent_folder));
folders = cell(1, length(S));
for i = 1:length(S)
    if length(S(i).name) > 2 && S(i).isdir
        folders{i} = fullfile(S(i).folder, S(i).name);
    end
end
folders(cellfun('isempty',folders)) = [];

for i = 1:length(folders)
    load(fullfile(folders{i}, 'all.mat'));
    
    
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

end

%% montage brains
path = "/home/makis/Documents/GitRepos/processing_folder/finalTests/-n003-14a";
S = dir(fullfile(path));
folders = cell(1, length(S));
for i = 1:length(S)
    if length(S(i).name) > 2 && S(i).isdir
        if ~(S(i).name(1:5) == "visua")
            folders{i} = fullfile(S(i).folder, S(i).name);
        end
    end
end
folders(cellfun('isempty',folders)) = [];
pairs = cell(1, length(folders));

for i = 1:length(folders)
    % load files 
    load(fullfile(folders{i}, 'all'), 'ml_p', 'index');
    
    % load image 
    manual = imread(fullfile(folders{i}, strcat(index, '-mmask.jpg')));
    manual = ~imbinarize(rgb2gray(manual));
    
    pairs{i} = imfuse(manual, ml_p);
end

fig = figure();
montage(pairs);
saveas(fig, strcat(S(1).folder, "/montage.jpg"));
   