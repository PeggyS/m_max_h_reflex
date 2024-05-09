function h_fig = create_m_fig(info_struc, h_uitable, tbl_row)

% create new figure window in a position depending upon how many other
% m-max figures are open
num_figs = length(findobj('Name', 'M-Max Analysis Figure'));
switch mod(num_figs, 4)
	case 0
		position(1) = 278;
		position(2) = 745;
	case 1
		position(1) = 1251;
		position(2) = 745;
	case 2
		position(1) = 278;
		position(2) = 69;
	case 3
		position(1) = 1251;
		position(2) = 69;
end
position(3) = 975;
position(4) = 600;

h_fig = figure('Name', 'M-Max Analysis Figure', 'Position', position);
h_fig.UserData.info_struc = info_struc;

h_ax = axes('Position', [0.13,0.12,0.65,0.81]);
box on
hold on

mep_start_time = 12;
mep_end_time = 45;

% data lines
t = maket(info_struc.data(:,1), info_struc.samp_freq);
h_lines = plot(h_ax, t*1000, info_struc.data, 'Tag', 'data_line');
set(h_lines, 'LineWidth', 2);
% draggable(h_lines, 'v', [-inf inf])
emg.XData = h_lines(1).XData;
emg.YData = h_lines(1).YData;
% initialize auc patch
[vertices, faces] = compute_patch(mep_start_time, mep_end_time, emg, 0);

% init each line
show_missing_pw_error = true;
for h_cnt = 1:length(h_lines)
	createLineMove2MinMaxMenu(h_lines(h_cnt))
% 	% make line draggable - -no way to get the line back to it's original
% 	position
% 	draggable(h_lines(h_cnt), @data_line_motionfcn, 'v', [-inf inf])
	
	emg.YData = h_lines(h_cnt).YData;
	
	% the line's auc patch
	h_lines(h_cnt).UserData.h_auc_patch = patch('Faces', faces, 'Vertices', vertices, ...
		'FaceColor', h_lines(h_cnt).Color, 'FaceAlpha', 0.7, ...
		'EdgeColor', h_lines(h_cnt).Color, 'Visible', 'off');
	% menu for the patch
	hcmenu = uicontextmenu;
	uimenu(hcmenu, 'Label', 'Show Data Line', 'Tag', 'menuShowDataLine', ...
		'Callback', {@menuPatchShowDataLine_Callback, h_lines(h_cnt)});
	uimenu(hcmenu, 'Label', 'Hide Data Line', 'Tag', 'menuHideDataLine', ...
		'Callback', {@menuPatchShowDataLine_Callback, h_lines(h_cnt)});
	h_lines(h_cnt).UserData.h_auc_patch.UIContextMenu = hcmenu;
	
	h_lines(h_cnt).UserData.move_amt = 0;
	h_lines(h_cnt).UserData.stim_ampl = info_struc.stim_ampl(h_cnt);

	if ~isempty(info_struc.stim_pw)
		h_lines(h_cnt).UserData.stim_pw = info_struc.stim_pw(h_cnt);
	else
		h_lines(h_cnt).UserData.stim_pw = 0;
		if show_missing_pw_error
			beep
			fprintf('No PW info in file %s.\nRe-export from Cadwell to add PW.\n', info_struc.filename);
			show_missing_pw_error = false; %#ok<NASGU>
		end
	end
	h_lines(h_cnt).UserData.trial_num = h_cnt;
	h_lines(h_cnt).UserData.disabled = false;
end
drawnow

% if uitable contains h info, then the stim offset is 0 (myopro study), otherwise it was
% recorded with 10 ms offset (tdcs_vgait study)
if any(contains(h_uitable.ColumnName, 'h_'))
	h_fig.UserData.stim_offset = 0;
else
	h_fig.UserData.stim_offset = 10;
end
% m-wave begin & end lines
h_ax.YLimMode = 'manual';
if ~isnan(h_uitable.Data.mep_latency_ms(tbl_row))
	mep_start_time = h_uitable.Data.mep_latency_ms(tbl_row) + h_fig.UserData.stim_offset; 
end
h_l = line(h_ax, [mep_start_time mep_start_time], h_ax.YLim, 'Color', 'b', 'LineWidth', 2, ...
	'Tag', 'mwave_beg_line');
draggable(h_l, 'h', [-inf inf], @dur_line_motionfcn);
if ~isnan(h_uitable.Data.mep_dur_ms(tbl_row))
	mep_end_time = mep_start_time + h_uitable.Data.mep_dur_ms(tbl_row);
end
h_l = line(h_ax, [mep_end_time mep_end_time], h_ax.YLim, 'Color', 'b', 'LineWidth', 2, ...
	'Tag', 'mwave_end_line');
draggable(h_l, 'h', [-inf inf], @dur_line_motionfcn);

% axes
xlabel('Time (msec)')
ylabel('EMG (\muV)')
title(h_ax, [info_struc.subject ' - ' info_struc.session ' - ' info_struc.side ' ' info_struc.muscle])
h_ax.FontSize = 14;
h_ax.LineWidth = 2;
h_ax.YLimMode = 'manual';
h_ax.XLim(2) = max(t)*1000;


% amplitude marker lines
y_low = h_ax.YLim(1)+0.1*abs(h_ax.YLim(1));
h_l = line(h_ax, h_ax.XLim, [y_low y_low], 'Color', 'b', 'LineWidth', 2, ...
	'Tag', 'ampl_low_line');
hcmenu = uicontextmenu(h_fig);
uimenu(hcmenu, 'Label', 'Move Troughs to This Line', 'Tag', 'menuTroughs2Me', ...
	'Callback', {@menuLineMoveLines2Me_Callback, h_l});
uimenu(hcmenu, 'Label', 'Return all to Baseline', 'Tag', 'menuReturnAll2Baseline', ...
	'Callback', {@menuLineMoveLines2Me_Callback, h_l});
uimenu(hcmenu, 'Label', 'Move Me to Min Trough', 'Tag', 'menuMe2Trough', ...
	'Callback', {@menuLineMoveMe2Lines_Callback, h_l});
h_l.UIContextMenu = hcmenu;
draggable(h_l, 'v', [-inf inf], @ampl_line_motionfcn);

y_hi = h_ax.YLim(2)-0.1*abs(h_ax.YLim(2));
h_l = line(h_ax, h_ax.XLim, [y_hi y_hi], 'Color', 'b', 'LineWidth', 2, ...
	'Tag', 'ampl_hi_line');
hcmenu = uicontextmenu(h_fig);
uimenu(hcmenu, 'Label', 'Move Peaks to This Line', 'Tag', 'menuPeaks2Me', ...
	'Callback', {@menuLineMoveLines2Me_Callback, h_l});
uimenu(hcmenu, 'Label', 'Return all to Baseline', 'Tag', 'menuReturnAll2Baseline', ...
	'Callback', {@menuLineMoveLines2Me_Callback, h_l});
uimenu(hcmenu, 'Label', 'Move Me to Max Peak', 'Tag', 'menuMe2Peak', ...
	'Callback', {@menuLineMoveMe2Lines_Callback, h_l});
h_l.UIContextMenu = hcmenu;
draggable(h_l, 'v', [-inf inf], @ampl_line_motionfcn);


% amplitude & duration  text displays
uicontrol(h_fig, ...
		'Style', 'text', ...
		'Tag', 'ampl_text', ...
		'String', {'M-wave Amplitude'; 'xx µV'}, ...
		'Units', 'normalized', ...
		'Position', [0.8,0.8,0.165,0.094], ...
		'FontSize', 14);
h_ampl_chkbx = uicontrol(h_fig, ...
		'Style', 'checkbox', ...
		'Tag', 'ampl_checkbox', ...
		'String', 'Show', ...
		'Units', 'normalized', ...
		'Position', [0.82,0.885,0.165,0.038], ...
		'FontSize', 14, ...
		'Callback', @chkbx_show_ampl_callback);
uicontrol(h_fig, ...
		'Style', 'text', ...
		'Tag', 'ampl_trial_text', ...
		'String', {'Trial xx : xx mA : xx µs'}, ...
		'Units', 'normalized', ...
		'Position', [0.8,0.72,0.165,0.094], ...
		'FontSize', 14);
uicontrol(h_fig, ...
		'Style', 'text', ...
		'Tag', 'cursor_ampl_text', ...
		'String', {'Cursor Amplitude'; 'xx µV'}, ...
		'Units', 'normalized', ...
		'Position', [0.8,0.6,0.165,0.094], ...
		'FontSize', 14);
uicontrol(h_fig, ...
		'Style', 'text', ...
		'Tag', 'auc_text', ...
		'String', {'M-wave AUC'; 'xx µV*ms'}, ...
		'Units', 'normalized', ...
		'Position', [0.788,0.45,0.165,0.094], ...
		'FontSize', 14);
uicontrol(h_fig, ...
		'Style', 'text', ...
		'Tag', 'auc_trial_text', ...
		'String', {'Trial xx : xx mA : xx µs'}, ...
		'Units', 'normalized', ...
		'Position', [0.8,0.375,0.165,0.094], ...
		'FontSize', 14);
h_auc_chkbx = uicontrol(h_fig, ...
		'Style', 'checkbox', ...
		'Tag', 'auc_checkbox', ...
		'String', 'Show', ...
		'Units', 'normalized', ...
		'Position', [0.82,0.535,0.165,0.038], ...
		'FontSize', 14, ...
		'Callback', @chkbx_show_auc_callback);
uicontrol(h_fig, ...
		'Style', 'text', ...
		'Tag', 'latency_text', ...
		'String', {'M-wave Latency'; 'xx ms'}, ...
		'Units', 'normalized', ...
		'Position', [0.8,0.275,0.165,0.094], ...
		'FontSize', 14);
uicontrol(h_fig, ...
		'Style', 'text', ...
		'Tag', 'duration_text', ...
		'String', {'M-wave Duration'; 'xx ms'}, ...
		'Units', 'normalized', ...
		'Position', [0.8,0.2,0.165,0.094], ...
		'FontSize', 14);
% uicontrol(h_fig, ...
% 		'Style', 'pushbutton', ...
% 		'Tag', 'save_bp', ...
% 		'String', {'Save to File'}, ...
% 		'Units', 'normalized', ...
% 		'Position', [0.8,0.1,0.165,0.094], ...
% 		'FontSize', 14, ...
% 		'Callback', @pb_save_callback);
uicontrol(h_fig, ...
		'Style', 'pushbutton', ...
		'Tag', 'send_bp', ...
		'String', {'Send to Table'}, ...
		'Units', 'normalized', ...
		'Position', [0.8,0.1,0.165,0.094], ...
		'FontSize', 14, ...
		'Callback', {@pb_send_to_table_callback, h_uitable, tbl_row});

drawnow
update_cursor_lines_amplitude(h_fig)
update_duration(h_fig)
update_ampl_and_auc(h_fig)

% check the checkboxes
h_ampl_chkbx.Value = 1;
chkbx_show_ampl_callback(h_ampl_chkbx, [])
h_auc_chkbx.Value = 1;
chkbx_show_auc_callback(h_auc_chkbx, [])

% create close function callback to uncheck
% the line in the uitable when window is closed
h_fig.CloseRequestFcn = {@close_m_fig_fcn, h_uitable, tbl_row};

return

% =============================================================

% -------------------------------------
function dur_line_motionfcn(h_line)
update_duration(h_line.Parent.Parent)
update_ampl_and_auc(h_line.Parent.Parent)
return

% -------------------------------------
function ampl_line_motionfcn(h_line)
update_cursor_lines_amplitude(h_line.Parent.Parent)
return

% -------------------------------------
function update_cursor_lines_amplitude(h_fig)
hi_line = findobj(h_fig, 'Tag', 'ampl_hi_line');
low_line = findobj(h_fig, 'Tag', 'ampl_low_line');

ampl = hi_line.YData(1) - low_line.YData(1);

cursor_ampl_text = findobj(h_fig, 'Tag', 'cursor_ampl_text');
cursor_ampl_text.String{2} = [num2str(ampl, '%6.0f') char(181) 'V'];
return

% -------------------------------------
function update_duration(h_fig)
beg_line = findobj(h_fig, 'Tag', 'mwave_beg_line');
end_line = findobj(h_fig, 'Tag', 'mwave_end_line');

dur = end_line.XData(1) - beg_line.XData(1);

dur_text = findobj(h_fig, 'Tag', 'duration_text');
dur_text.String{2} = [num2str(dur, '%5.1f') ' ms'];

% also update latency
latency = beg_line.XData(1) - h_fig.UserData.stim_offset; 
late_text = findobj(h_fig, 'Tag', 'latency_text');
late_text.String{2} = [num2str(latency, '%5.1f') ' ms'];
return

% -------------------------------------
function update_ampl_and_auc(h_fig)
auc_max = 0;
auc_max_h_line = [];
% auc_max_trial_num = 0;
max_ampl = 0;
max_ampl_h_line = [];
% max_ampl_trial_num = 0;

% auc display
h_auc_text = findobj(h_fig, 'Tag', 'auc_text');
if isfield(h_auc_text.UserData, 'auc_max_h_line')
	prev_h_auc_max_line = h_auc_text.UserData.auc_max_h_line;
else
	prev_h_auc_max_line = [];
end
% ampl display
h_ampl_text = findobj(h_fig, 'Tag', 'ampl_text');
if isfield(h_ampl_text.UserData, 'ampl_max_h_line')
	prev_h_max_ampl_line = h_ampl_text.UserData.ampl_max_h_line;
else
	prev_h_max_ampl_line = [];
end

% times defining begin & end of m-wave
beg_line = findobj(h_fig, 'Tag', 'mwave_beg_line');
end_line = findobj(h_fig, 'Tag', 'mwave_end_line');
mep_start_time = beg_line.XData(1);
mep_end_time = end_line.XData(1);

h_auc_show = findobj(h_fig, 'Tag', 'auc_checkbox');
h_auc_trial_text = findobj(h_fig, 'Tag', 'auc_trial_text');
h_ampl_show = findobj(h_fig, 'Tag', 'ampl_checkbox');
h_ampl_trial_text = findobj(h_fig, 'Tag', 'ampl_trial_text');

h_lines = findobj(h_fig, 'Tag', 'data_line');
emg.XData = h_lines(1).XData;
data_msk = h_lines(1).XData >= mep_start_time & h_lines(1).XData <= mep_end_time;

for h_cnt = 1:length(h_lines)
	% patch & auc
	if h_lines(h_cnt).UserData.move_amt ~= 0
		emg.YData = h_lines(h_cnt).YData - h_lines(h_cnt).UserData.move_amt;
	else
		emg.YData = h_lines(h_cnt).YData;
	end
	[vertices, faces] = compute_patch(mep_start_time, mep_end_time, emg, 0);
	h_lines(h_cnt).UserData.auc = compute_auc(vertices);
	if h_lines(h_cnt).UserData.auc > auc_max && ~h_lines(h_cnt).UserData.disabled
		auc_max = h_lines(h_cnt).UserData.auc;
		auc_max_h_line = h_lines(h_cnt);
% 		auc_max_trial_num = h_lines(h_cnt).UserData.trial_num;
		if h_auc_show.Value
			if ~isempty(prev_h_auc_max_line)
				prev_h_auc_max_line.UserData.h_auc_patch.Visible = 'off';
			end
		end
	end
	h_lines(h_cnt).UserData.h_auc_patch.Faces = faces;
	h_lines(h_cnt).UserData.h_auc_patch.Vertices = vertices;
	
	% max ampl
	data = h_lines(h_cnt).YData(data_msk);
	h_lines(h_cnt).UserData.m_wave_ampl = max(data) - min(data);
	if h_lines(h_cnt).UserData.m_wave_ampl > max_ampl && ~h_lines(h_cnt).UserData.disabled
		max_ampl = h_lines(h_cnt).UserData.m_wave_ampl;
		max_ampl_h_line = h_lines(h_cnt);
% 		max_ampl_trial_num = h_lines(h_cnt).UserData.trial_num;
		if h_ampl_show.Value
			if ~isempty(prev_h_max_ampl_line)
				prev_h_max_ampl_line.LineWidth = 2;
			end
		end
		
	end
end

% update display
h_auc_text.String{2} = [num2str(auc_max, '%5.0f') ' ' char(181) 'V*ms'];
if h_auc_show.Value
	auc_max_h_line.UserData.h_auc_patch.Visible = 'on';
end
h_auc_text.UserData.auc_max_h_line = auc_max_h_line;
% if auc_max_trial_num > 0
	h_auc_trial_text.String = {['Trial ' num2str(auc_max_h_line.UserData.trial_num) ...
		' : ' num2str(auc_max_h_line.UserData.stim_ampl) ...
		' mA : ' num2str(auc_max_h_line.UserData.stim_pw) ' ' char(181) 's']};
% end
h_ampl_text.String{2} = [num2str(max_ampl, '%5.0f') ' ' char(181) 'V'];
if h_ampl_show.Value
	h_ampl_show.UserData.h_max_ampl_line = max_ampl_h_line;
	max_ampl_h_line.LineWidth = 4;
	uistack(max_ampl_h_line, 'top')
end
h_ampl_text.UserData.ampl_max_h_line = max_ampl_h_line;
% if max_ampl_trial_num > 0
	h_ampl_trial_text.String = {['Trial ' num2str(max_ampl_h_line.UserData.trial_num) ...
		' : ' num2str(max_ampl_h_line.UserData.stim_ampl) ...
		' mA : ' num2str(max_ampl_h_line.UserData.stim_pw) ' ' char(181) 's']};
% end
return

% -------------------------------------
function createLineMove2MinMaxMenu(hLine)
hcmenu = uicontextmenu;
uimenu(hcmenu, 'Label', 'Move Peak to Max Line', 'Tag', 'menuPeak2Max', ...
	'Callback', {@menuLineMove2MinMax_Callback, hLine});
uimenu(hcmenu, 'Label', 'Return to baseline', 'Tag', 'menuReturn2bl', ...
	'Callback', {@menuLineMove2MinMax_Callback, hLine});
uimenu(hcmenu, 'Label', 'Move Trough to Min Line', 'Tag', 'menuTrough2Min', ...
	'Callback', {@menuLineMove2MinMax_Callback, hLine});
uimenu(hcmenu, 'Label', 'Disable', 'Tag', 'menuDisable', ...
	'Callback', {@menuLineDisable_Callback, hLine});
set(hLine, 'UIContextMenu', hcmenu);
return

% -------------------------------------
function menuLineDisable_Callback(source, ~, hLine)
disabled_color = [0.5 0.5 0.5];
switch source.Checked
	case 'on'
		source.Checked = 'off';
		hLine.Color = hLine.UserData.prev_color;
		hLine.UserData.h_auc_patch.FaceColor = hLine.UserData.prev_color;
		hLine.UserData.h_auc_patch.EdgeColor = hLine.UserData.prev_color;
		hLine.UserData.disabled = false;
	case 'off'
		source.Checked = 'on';
		hLine.UserData.prev_color = hLine.Color;
		hLine.Color = disabled_color;
		hLine.UserData.h_auc_patch.FaceColor = disabled_color;
		hLine.UserData.h_auc_patch.EdgeColor = disabled_color;
		hLine.LineWidth = 2;
		hLine.UserData.disabled = true;
end
update_ampl_and_auc(hLine.Parent.Parent)
return

% -------------------------------------
function menuLineMoveMe2Lines_Callback(source, ~, hLine)
% find all data lines
h_lines = findobj(hLine.Parent, 'Tag', 'data_line');
if isempty(h_lines)
	return
end
% use line data between mwave_beg & end lines
[beg_t, end_t] = get_begin_end_t(hLine);

% data betw beg & end - one row for each line
for l_cnt = 1:length(h_lines)
	y_data(l_cnt,:) = h_lines(l_cnt).YData(h_lines(l_cnt).XData>beg_t & h_lines(l_cnt).XData<end_t); %#ok<AGROW>
end
switch source.Tag
	case 'menuMe2Peak'
		val = max(max(y_data));
	case 'menuMe2Trough'
		val = min(min(y_data));
end
% move the line
move_amt = val - hLine.YData(1);
hLine.YData = hLine.YData + move_amt;
hLine.UserData.move_amt = val;

update_cursor_lines_amplitude(hLine.Parent.Parent)
return


% -------------------------------------
function [beg_t, end_t] = get_begin_end_t(hLine)
h_mwave_beg_line = findobj(hLine.Parent, 'Tag', 'mwave_beg_line');
h_mwave_end_line = findobj(hLine.Parent, 'Tag', 'mwave_end_line');
beg_t = h_mwave_beg_line.XData(1);
end_t = h_mwave_end_line.XData(1);
return

% -------------------------------------
function menuLineMove2MinMax_Callback(source, ~, hLine)
% use line data between mwave_beg & end lines
[beg_t, end_t] = get_begin_end_t(hLine);

% data betw beg & end
y_data = hLine.YData(hLine.XData>beg_t & hLine.XData<end_t);
switch source.Tag
	case 'menuPeak2Max'
		% max line
		max_line = findobj(hLine.Parent, 'Tag', 'ampl_hi_line');
		max_data = max(y_data);
		move_amt = max_line.YData(1) - max_data;
	case 'menuReturn2bl'
		move_amt = -hLine.UserData.move_amt;
	case 'menuTrough2Min'
		min_line = findobj(hLine.Parent, 'Tag', 'ampl_low_line');
		min_data = min(y_data);
		move_amt = min_line.YData(1) - min_data;
end

hLine.UserData.move_amt = hLine.UserData.move_amt + move_amt;

% move the line
hLine.YData = hLine.YData + move_amt;
return

% -------------------------------------
function menuLineMoveLines2Me_Callback(source, ~, hLine)
% find all data lines
h_lines = findobj(hLine.Parent, 'Tag', 'data_line');
if isempty(h_lines)
	return
end

% use line data between mwave_beg & end lines
[beg_t, end_t] = get_begin_end_t(hLine);

% move each line's max value in between beg_t & end_t to the y value of
% this line
y_target = hLine.YData(1);

for l_cnt = 1:length(h_lines)
	y_data = h_lines(l_cnt).YData(h_lines(l_cnt).XData>beg_t & h_lines(l_cnt).XData<end_t);
	switch source.Tag
		case 'menuPeaks2Me'
			val = max(y_data);
			move_amt = y_target - val;
		case 'menuReturnAll2Baseline'
			move_amt = -h_lines(l_cnt).UserData.move_amt;
		case 'menuTroughs2Me'
			val = min(y_data);
			move_amt = y_target - val;
	end
	h_lines(l_cnt).YData = h_lines(l_cnt).YData + move_amt;
	h_lines(l_cnt).UserData.move_amt = h_lines(l_cnt).UserData.move_amt + move_amt;
end
return

% -------------------------------------
function menuPatchShowDataLine_Callback(source, ~, hLine)
switch source.Tag
	case 'menuShowDataLine'
		hLine.LineWidth = 4;
		uistack(hLine, 'top')
	case 'menuHideDataLine'
		hLine.LineWidth = 2;
		uistack(hLine, 'bottom')
end
return

% -------------------------------------
function chkbx_show_auc_callback(source, ~)
h_auc_text = findobj(source.Parent, 'Tag', 'auc_text');
if source.Value
	h_auc_text.UserData.auc_max_h_line.UserData.h_auc_patch.Visible = 'on';
else
	h_auc_text.UserData.auc_max_h_line.UserData.h_auc_patch.Visible = 'off';
end
return

% -------------------------------------
function chkbx_show_ampl_callback(source, ~)
if source.Value
	h_max_ampl_line = find_max_ampl_line(source.Parent);
	source.UserData.h_max_ampl_line = h_max_ampl_line;
	source.UserData.h_max_ampl_line.LineWidth = 4;
	uistack(source.UserData.h_max_ampl_line, 'top')
else
	source.UserData.h_max_ampl_line.LineWidth = 2;
end
return

% -------------------------------------
function [h_max_ampl_line] = find_max_ampl_line(h_fig)
h_data_lines = findobj(h_fig, 'Tag', 'data_line');

max_ampl = 0;
h_max_ampl_line = [];

for l_cnt = 1:length(h_data_lines)
	ampl = h_data_lines(l_cnt).UserData.m_wave_ampl;
	if ampl > max_ampl
		max_ampl = ampl;
		h_max_ampl_line = h_data_lines(l_cnt);
	end
end
return



