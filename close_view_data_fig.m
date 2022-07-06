function close_view_data_fig(app, view_row, h_or_m)

switch h_or_m
	case 'm'
		if isfield(app.UITable.UserData, 'h_mfigs')
			if length(app.UITable.UserData.h_mfigs) >= view_row
				delete(app.UITable.UserData.h_mfigs(view_row));
			end
		end
	case 'h'
		if isfield(app.UITable.UserData, 'h_hfigs')
			if length(app.UITable.UserData.h_hfigs) >= view_row
				delete(app.UITable.UserData.h_hfigs(view_row));
			end
		end
		
end

return