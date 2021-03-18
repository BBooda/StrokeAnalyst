%% create atlas map object 
atlas_add = containers.Map('KeyType','double','ValueType','any');
% set variables 
save_dir = '';
folder_path = '';
%% affine register to template 

% exclude template image
imgs_to_register = zeros(1, (length(imgs) - 1));
counter = 1;
for i = 1:length(imgs)
    if i ~= ref_ind
        imgs_to_register(counter) = i;
        counter = counter + 1;            
    end
end

template = imgs{ref_ind};

% create cell to store linearly transformed images
linear_out = cell(1, length(imgs_to_register));

file_names = cell(1, (length(imgs_to_register) + 1));

% perform linear transformation and save corresponding nifti files to
% directory 

for i = 1:length(imgs_to_register)
    % perform linear registration 
    lin_out = linear_registration(imgs_to_register{i}, template);
    
    % create file names for deformable registration 
    file_names{i} = strcat('aff_',num2str(ind_list(i)));
    nifti_save(aff_out.RegisteredImage, file_names{i}, save_dir);
end









