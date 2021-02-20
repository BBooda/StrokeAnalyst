 function nifti_save(img, name, path)
%             app.LogTextArea.Value = [app.LogTextArea.Value ; "file created..."];
    [~, ~, channels] = size(img);

    if channels > 2 
        img = rgb2gray(img);
    end



    % create a nifti file and load header info
    if isempty(path)
       path = pwd; 
    end

    fullname = strcat(path, '/', name, '.nii');

    niftiwrite(single(img), fullname);

    % read header info 
    header = niftiinfo(fullname);

    % alter header according to input arguments 
    header.PixelDimensions = [0.0210 0.0210];
    header.Datatype =  'single';
    header.BitsPerPixel = 32;
    header.SpaceUnits = 'Millimeter';
    header.TimeUnits = 'Second';
    header.MultiplicativeScaling = 1;
    header.TransformName = 'Sform';

    header.Transform.T = [0.0210, 0, 0, 0; 0, 0.0210, 0, 0; 0, 0, 1.0000, 0;  0.0210, 0.0210, 1.0000, 1.0000];

% "header.raw" values are updated with the changes of the header(above code, not sure, check this); 

    header.raw.pixdim = [1 0.0210 0.0210 1 0 0 0 0];
    header.raw.scl_slope = 1;
    header.raw.xyzt_units = 10;
    header.raw.qform_code = 2;
    header.raw.sform_code = 2;
    header.raw.qoffset_x = 0.0210;
    header.raw.qoffset_y = 0.0210;
    header.raw.qoffset_z = 1;
    header.raw.srow_x = [0.0210 0 0 0.0210];
    header.raw.srow_y = [0 0.0210 0 0.0210];
    header.raw.srow_z = [0 0 1 1];
    header.raw.qform_code = 2;
    header.raw.sform_code = 2;
    header.raw.qoffset_x = 0.0210;
    header.raw.qoffset_y = 0.0210;
    header.raw.qoffset_z = 1;


    % re-save file with new header.
    niftiwrite(single(img), fullname, header);




end