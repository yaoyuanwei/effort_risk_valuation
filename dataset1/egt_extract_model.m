% Extract events and timing information for SPM for each subject
% Author: Yuanwei Yao
% Date: June 31, 2023

function [onsets, names, durations, nr_ind] = egt_extract_model(task_name, anal_fold, sub_data, run_n, sub_sv, si)

    % generated mat file name
    matfile     = [task_name, '_model_sv'];

    % add sub_id to the no-response recording matrix
    nr_ind      = zeros(1,run_n+1);
    % last column for sub-id
    nr_ind(1,run_n+1) = si;
    % index for no-response trials
    nan_ind     = (sub_data.response == 0)|isnan(sub_data.response);
    
    % divide subjective values based on the median
    sv_md       = median(sub_sv);
    sv_high     = (sub_sv >= sv_md);
    sv_low      = (sub_sv < sv_md);
    
    % cue onset and trial duration
    cue_ons     = sub_data.StrTime;
    trial_dur   = sub_data.dur;
    trial_rt    = sub_data.RT;
    
    % generate events and timing info for each run
    for ri = 1:run_n
            
        trial_ri    = (sub_data.run == ri);
        % any trials without response in this run?
        nan_ri      = trial_ri & nan_ind;
        % valid trial index
        valid_ri    = trial_ri & ~(nan_ind);

        % high and low sv trials index for each run
        sv_hri      = sv_high & valid_ri;
        sv_lri      = sv_low & valid_ri;
        
        % initialize names, onsets, durations for each run
        names       = {};
        onsets      = {};
        durations   = {};
        
        % cue onset
        cue_ons_ri  = cue_ons(valid_ri);
        % onset for high and low sv cues
        svh_ons_ri  = cue_ons(sv_hri);
        svl_ons_ri  = cue_ons(sv_lri);
            
        % build spm mat: high and low sv were included as two regressors of interest
        % no-response trials (if any) were included as a regressor of no interest
        if max(nan_ri) > 0
            nr_ons_ri   = cue_ons(nan_ri);
            nr_dur_ri   = trial_dur(nan_ri);
            onsets      = {svh_ons_ri, svl_ons_ri, nr_ons_ri};
            names       = {'sv_high', 'sv_low', 'missing'};
            durations   = {0 0 nr_dur_ri};
            nr_ind(1,ri)  = 1;
        % only 2 regressors if all trials were selected
        else
            onsets      = {svh_ons_ri, svl_ons_ri};
            names       = {'sv_high', 'sv_low'};
            durations   = {0 0};
        end
        
        % create a heb folder to store the generated mat file
        sub_id      = sprintf('sub-%d', si);
        aim_fold    = fullfile(anal_fold, sub_id, 'beh');
        if ~isfolder(aim_fold)
            mkdir(aim_fold);
        end
        
        % save names, onsets, durations as a mat file for checking
        save([aim_fold '/' matfile '_r' num2str(ri) '.mat'], 'names', 'onsets', 'durations');
    end
end