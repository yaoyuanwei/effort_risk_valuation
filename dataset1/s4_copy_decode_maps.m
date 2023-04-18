clear;
clc;

%define the directory structure
base_path   = '/Volumes/projects/ERGT/EGT/mvpa';
result_dir  = 'results';
model_dir   = 'egt_model4sv_decode';
sub_fold    = dir(fullfile(base_path, 'sub*'));
sub_dir     = {sub_fold.name}';
mapsToCopy  = {'res_accuracy_minus_chance.nii'};
dest_path   = fullfile(base_path, 'stats', model_dir, 'unsmoothed');
if ~exist(dest_path,'dir')
    mkdir(dest_path);
end


for si = 1:length(sub_dir)
    
    sub_path        = fullfile(base_path, sub_dir{si}, result_dir, model_dir);
    
    source_file     = spm_select('FPList', sub_path, mapsToCopy{1});
    [path,name,ext] = fileparts(mapsToCopy{1});
    dest_file_name  = sprintf('%s_%s%s',name,sub_dir{si},ext); % res_accuracy_minus_chance_sub-19.nii
    dest_file       = fullfile(dest_path, dest_file_name);
    copyfile(source_file,dest_file);
    
end