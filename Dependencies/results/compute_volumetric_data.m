function compute_volumetric_data(lesion_m, left_hemi, right_hemi, index, save_dir)
    pix_area = 0.021*0.021;    

    [y, ~] = find(lesion_m);
    lesion_area = length(y)*pix_area;

    [y, ~] = find(left_hemi);
    lh_area = length(y)*pix_area;

    [y, ~] = find(right_hemi);
    rh_area = length(y)*pix_area;

%             T = table('Size',[3 1], 'VariableTypes', {'double'});
%     Names = {cell2mat(app.img_names(strcmp(app.img_names, app.IndexiesListBox.Value))); 'lesion_area'; 'left_hem_area'; 'right_hem_area'};
    Names = {num2str(index); 'lesion_area'; 'left_hem_area'; 'right_hem_area'};

%             VariableNames{end + 1} = {};

    Variables = [NaN;lesion_area; lh_area; rh_area];

    T = table(Names,Variables); 

    writetable(T, strcat(save_dir, '/results.xls'));
    
end