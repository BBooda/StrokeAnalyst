function region_naming(allen_json, allen_masks, index, ...
    lesion_AS, allen_atlas_path, save_dir)
      
    %extract original allen mask and keep unique
    ori_allen_labels = unique(extract_allen_mask_ui(calculate_atlas_index(index), allen_atlas_path));

    % cast to number
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
    
    % that mask exists
    if allen_masks.isKey(index)
        label_mask = allen_masks(index);
        
        % sanity check, label mask and lesion_AS mask dimensions must agree
        if isequal(size(label_mask), size(lesion_AS))
            % filter allen mask using lesion prediction
            affected_regions_mask = label_mask .* lesion_AS;

            % aquire interpolated points indexies
            int_indexies = ismember(affected_regions_mask, ori_allen_labels);      

            % filter out interpolated points, set to zero

            affected_regions_mask(~int_indexies) = 0;

            % filter duplicates and find affected regions 

            labels = unique(fix(affected_regions_mask(:)));

            hit_regions = cell(numel(labels),1);
            for i = 1:numel(labels)
%                 hit_regions{i} = js_find(app.dictionary.msg, labels(i));
                hit_regions{i} = js_find(allen_json.msg, labels(i));
            end

            filePh = fopen(strcat(save_dir,'/affected_regions.txt'),'w');
            fprintf(filePh,'%s\n',hit_regions{:});
            fclose(filePh);
        end
    end

end