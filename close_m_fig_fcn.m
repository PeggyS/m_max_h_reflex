function close_m_fig_fcn(h_fig, evt, h_uitable, tbl_row)
switch h_fig.Name
	case 'M-Max Analysis Figure'
		tbl_var = 'view_m';
	case 'H-Max Analysis Figure'
		tbl_var = 'view_h';
end
try
	% uncheck the row in the uitable
	h_uitable.Data.(tbl_var)(tbl_row) = false;
catch
	% do nothing
end
delete(h_fig)
return