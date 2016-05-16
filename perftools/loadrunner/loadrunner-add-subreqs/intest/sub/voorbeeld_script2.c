FB01()
{

	lr_start_transaction("01_A2C_FB01");


	sapgui_set_ok_code("FB01", 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1053", 
		END_OPTIONAL);

	lr_start_sub_transaction("01_A2C_FB01_01","01_A2C_FB01");


	sapgui_send_vkey(ENTER, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1054", 
		END_OPTIONAL);

	lr_end_sub_transaction("01_A2C_FB01_01", LR_AUTO);

	lr_think_time(tt);

	sapgui_set_text("Document Date", 
		"{today}", 
		ctxtBKPF1, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1057", 
		END_OPTIONAL);

	sapgui_set_text("Type", 
		"SA", 
		ctxtBKPF2, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1058", 
		END_OPTIONAL);

	sapgui_set_text("Company Code", 
		"{fb01_cc}", 
		ctxtBKPF3, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1059", 
		END_OPTIONAL);

	sapgui_set_text("Posting Date", 
		"{today}", 
		ctxtBKPF4, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1060", 
		END_OPTIONAL);

	sapgui_set_text("Currency/Rate", 
		"EUR", 
		ctxtBKPF5, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1061", 
		END_OPTIONAL);

	sapgui_set_text("PstKy", 
		"40", 
		ctxtRF05A1, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1062", 
		END_OPTIONAL);

	sapgui_set_text("Account", 
		"514000", 
		ctxtRF05A2, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1063", 
		END_OPTIONAL);

	sapgui_set_focus(ctxtRF05A2, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1064", 
		END_OPTIONAL);

	sapgui_send_vkey(ENTER, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1066", 
		END_OPTIONAL);

	sapgui_set_text("Amount", 
		"1000", 
		txtBSEG1, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1069", 
		END_OPTIONAL);

	sapgui_set_text("Tax Code", 
		"{fb01_tc}", 
		ctxtBSEG1, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1070", 
		END_OPTIONAL);

	sapgui_set_text("PstKy", 
		"50", 
		ctxtRF05A1, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1071", 
		END_OPTIONAL);

	sapgui_set_text("Account", 
		"287000", 
		ctxtRF05A2, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1072", 
		END_OPTIONAL);

	sapgui_set_focus(ctxtRF05A2, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1073", 
		END_OPTIONAL);

	sapgui_send_vkey(ENTER, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1075", 
		END_OPTIONAL);

	sapgui_set_text("Amount", 
		"1000", 
		txtBSEG1, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1078", 
		END_OPTIONAL);

	sapgui_press_button("Post   (Ctrl+S)", 
		btn3, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1080", 
		END_OPTIONAL);

	sapgui_status_bar_get_text("paramStatusBarText", 
		BEGIN_OPTIONAL, 
			"Recorded status bar text: Document 30000001 was posted in company code 2000", 
			"AdditionalInfo=sapgui1083", 
		END_OPTIONAL);

	lr_end_transaction("01_A2C_FB01",LR_AUTO);

	lr_think_time(5);

	sapgui_set_ok_code("/n", 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1084", 
		END_OPTIONAL);

	sapgui_send_vkey(ENTER, 
		BEGIN_OPTIONAL, 
			"AdditionalInfo=sapgui1085", 
		END_OPTIONAL);

	sapgui_table_fill_data("Table", 
	  tblSAPMV45ATCTRL_U_ERF_AUFTRAG1, 
	  "{VA01_MaterialPlant}", 
	  BEGIN_OPTIONAL, 
	  "AdditionalInfo=sapgui1029", 
	  END_OPTIONAL);

	return 0;
}
