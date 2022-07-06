function pb_send_h_to_table_callback(source, ~, h_uitable, tbl_row)
% get date, session, side, & muscle from info_struc
h_fig = source.Parent;
info = h_fig.UserData.info_struc;
t = datetime(info.date, 'InputFormat','M/d/yy');

% session = info.session;
% subject = parse_fname_for_subj(info.filename);
% side = lookup_inv_uninv(subject, info.side);
% muscle = info.muscle;

for tr_cnt = 1:3
	tag_str = ['h_ampl' num2str(tr_cnt) '_checkbox'];
	h_ampl_show = findobj(h_fig, 'Tag', tag_str);
	if ~isfield(h_ampl_show.UserData, 'max_ampl_h_line')
		break
	end
	
	% put ampl in the table
	tbl_var = ['h_max_' num2str(tr_cnt), '_us'];
	h_uitable.Data.(tbl_var)(tbl_row) = h_ampl_show.UserData.max_ampl_h_line.UserData.max_ampl;

end

h_dur_text = findobj(h_fig, 'Tag', 'duration_text');
tmp = regexp(h_dur_text.String{2}, '(?<duration>\d*\.\d*)', 'names');
if ~isempty(tmp)
	h_duration = str2double(tmp.duration);
else
	h_duration = 0;
end
h_late_text = findobj(h_fig, 'Tag', 'latency_text');
tmp = regexp(h_late_text.String{2}, '(?<latency>\d*\.\d*)', 'names');
if ~isempty(tmp)
	h_latency = str2double(tmp.latency);
else
	h_latency = 0;
end

% update the row
h_uitable.Data.h_latency_ms(tbl_row) = h_latency;
h_uitable.Data.h_dur_ms(tbl_row) = h_duration;

if ~h_uitable.UserData.table_changed
	h_uitable.UserData.table_changed = true;
end
return
