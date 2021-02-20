%% aquire data to run, set variables
dramms_path = "home/makis/myprograms/dramms/bin";
atlas_path = "../data_dependencies";

%set variables
subject = subject_info.subject;
reference = subject_info.reference;
index = subject_info.index;

% aquire atlas 
ttc_atlas = load(strcat(atlas_path, '/myatlasv1.mat'));

