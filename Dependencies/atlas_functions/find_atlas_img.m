function [ref,index] = find_atlas_img(str, atlas)
    if strcmp(str(1:2), 'bn')
        ref = str2double(strcat('-', str(3), '.', str(5:6)));
    else
        ref = str2double(strcat(str(3), '.', str(5:6)));
    end

    index = ref;
    ref = atlas.my_atlas(ref);
end