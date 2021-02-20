classdef Subject
    properties
        img {mustBeNumeric}
        reference {mustBeNumeric}
        zscore {mustBeNumeric}
        aff_hemisphere {mustBeNumeric}
        ss_hem_masks {logical}
        as_hem_masks {logical}
        aff_tranf 
        deformable_transform
    end
    
    methods
        % constructor
        function obj = Subject(img)
            obj.img = img;
        end
    end
end