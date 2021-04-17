%% specify path variables
save_dir = '/home/makis/Documents/GitRepos/data_dependencies/atlas_final/bn1_34';


%% load slices mask and allen slice
% load TTC average slice

%NOTE: The registered.mat file is the file created from the
%create_ttc_atlas.m script

load(fullfile(save_dir, 'registered.mat'), 'a_slice', 'S', 'index');
% cast index to number
if isa(index,'char')
    if index(end -4) == 'n'
        index(end - 2) = '.';
        index= str2double(index(3:end));
        index = index * -1;
    else 
        index(end - 2) = '.';
        index = str2double(index(3:end));
    end
end
bregma = index;
% bregma = 2.80;
ind = calculate_atlas_index(bregma);
allen = extract_allen_slice(ind);
%   mask_index = bregma/0.025 + 313;
mask = extract_allen_mask(ind);

% save a copy of the original allen mask. Use it to remove interpolated
% values
ori_allen_labels = mask;

%% set control points to perform registration

cpselect(allen, adapthisteq(uint8(a_slice)));
%% after exporting the assigned control points to work space, execute this part to perform the registration
% NOTE: keep an eye to the control points variable names, as you can export
% them with different variable names`
tform2 = fitgeotrans(movingPoints2,fixedPoints2,'lwm', 15);
allen_subject = imwarp(allen,tform2,'OutputView',imref2d(size(a_slice)));
mask_TTC_sp = imwarp(mask,tform2,'OutputView',imref2d(size(a_slice)));
Im_blend(uint8(allen_subject), uint8(a_slice))

%% visualazation and data extraction

% make a copy of tranformed (to TTC atlas space) anatomical mask
label_mask = mask_TTC_sp;
% remove interpolated values from label mask
int_indexies = ismember(label_mask, ori_allen_labels);
label_mask(int_indexies) = 0;

if (size(label_mask, 1) == size(a_slice, 1)) && (size(label_mask, 2) == size(a_slice, 2))
    % save results
    imwrite(uint8(a_slice), fullfile(save_dir, strcat(num2str(bregma), '_AVG.jpg')));
    imwrite(uint8(S), fullfile(save_dir, strcat(num2str(bregma), '_STD.jpg')));
    % create grid overlay
    grid_over = uint8(255*imbinarize(label_mask))+ uint8(a_slice);
    imwrite(uint8(grid_over), fullfile(save_dir, strcat(num2str(bregma), '_grid_overlay.jpg')));
    %save grid
    imwrite(uint8(255*imbinarize(label_mask)), fullfile(save_dir, strcat(num2str(bregma), '_grid.jpg')));
end
save(fullfile(save_dir, 'allen_points.mat'))




