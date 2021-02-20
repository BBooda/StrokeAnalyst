classdef Subject
    properties
        img {mustBeNumeric}
        reference {mustBeNumeric}
        zscore {double}
        aff_hemisphere {mustBeNumeric}
        ss_hem_masks {logical}
        as_hem_masks {logical}
        aff_tranf 
        deformable_transform
        outlier_detection {mustBeNumeric}
        lesion_pred {mustBeNumeric}
    end
    
    methods
        % constructor
        function obj = Subject(img)
            obj.img = img;
        end
        
%         function map_to_subject_obj(obj, subject_info)
% %             obj.img = subject_info.subject;
%             obj.zscore = subject_info.zscore;
%         end
    end
end