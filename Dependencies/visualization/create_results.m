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
    
   