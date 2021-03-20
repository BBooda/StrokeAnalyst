%% create atlas map object 
atlas_add = containers.Map('KeyType','double','ValueType','any');
% set variables 
dramms_path = "home/makis/myprograms/dramms/bin";
save_dir = '/home/makis/Documents/GitRepos/data_dependencies/atlas_final';
folder_path = '~/Documents/GitRepos/data_dependencies/atlas_final/bn2_54';
index = 'bn2_54';
save_dir = strcat(save_dir, '/', index);
imgs = load_dir_imgs(strcat('b'), folder_path);
mkdir(strcat(save_dir, '/transformations'));
%% affine register to template 

ref_ind = 1;

% set transformations path 
trans_path = strcat(save_dir, '/transformations');

% exclude template image
imgs_to_register = cell(1, (length(imgs) - 1));
counter = 1;
for i = 1:length(imgs)
    if i ~= ref_ind
        imgs_to_register{counter} = pcaV1(imgs{i});
        counter = counter + 1;            
    end
end

template = pcaV1(imgs{ref_ind});

% flip images in respect to midline
temp = cell(1, 2*length(imgs_to_register));

counter = 1;
for i = 1:length(imgs_to_register)
    temp{counter} = imgs_to_register{i};
    temp{counter + 1} = flip(imgs_to_register{i}, 2);
    counter = counter + 2;
end
imgs_to_register = temp; 
clear('temp');

% create cell to store linearly transformed images
linear_out = cell(1, length(imgs_to_register));

file_names = cell(1, (length(imgs_to_register) + 1));

% perform linear transformation and save corresponding nifti files to
% directory 

for i = 1:length(imgs_to_register)
    % perform linear registration 
    lin_out = linear_registration((imgs_to_register{i}), (template));
    
    % create file names for deformable registration 
    file_names{i} = strcat('aff_',num2str(i));
    nifti_save(lin_out.RegisteredImage, file_names{i}, trans_path);
    linear_out{i} = lin_out.RegisteredImage;
end

% create nifti for reference image 
nifti_save((template), 'reference', trans_path);
file_names{end} = 'reference';



montage(linear_out)

%% perform non linear registration 

% create paths 
linear_paths = cell(1, length(linear_out));
registered = cell(1, length(linear_out));
for i = 1:length(linear_out)
    linear_paths{i} = strcat(trans_path, '/', file_names{i}, '.nii');
end

reference_path = strcat(trans_path, '/', file_names{end}, '.nii');

for i = 1:length(linear_paths)
    registered_name = strcat(num2str(i));

    non_lin_reg_info = dramms_2dregistration(reference_path, linear_paths{i}, ...
        trans_path, registered_name, dramms_path);
    
    registered{i} = niftiread(strcat( trans_path, '/', 'registered_', ...
        registered_name, '_to_average.nii'));
end

% montage(registered);

% create average and standard deviation image

first_time = true;
concat = [];
concat = cat(3, concat, (template));
for i = 1:length(registered)
  concat = cat(3, concat, registered{i});
end
a_slice = mean(concat, 3);
S = std(double(concat), 0,3);

% nifti_save(a_slice, 'average', save_dir);

% save('std_img', 'S');

new_regi = registered;
% save registered 
save(strcat(save_dir, '/registered'));

temp = cell(1, length(registered));
for i = 1:length(registered)
temp{i} = uint8(registered{i});
end
montage(temp);

%% exclude and recompute average

first_time = false;

concat = [];
concat = cat(3, concat, (template));
for i = 1:length(new_regi)
  concat = cat(3, concat, new_regi{i});
end
a_slice = mean(concat, 3);
S = std(double(concat), 0,3);

% nifti_save(a_slice, 'average', save_dir);

% save('std_img', 'S');


% save registered 
save(strcat(save_dir, '/registered'));








