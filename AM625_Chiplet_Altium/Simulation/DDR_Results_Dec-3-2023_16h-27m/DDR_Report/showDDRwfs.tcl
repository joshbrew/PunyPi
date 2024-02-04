#Notes:
#runEZwave.bat finds and calls Ams\..\ezwave.bat showDDRwfs.tcl
#The arguments are passed to showDDRwfs.tcl within environment variables
#
#Arguments:
#runEZwave.bat DataRate TableType ThresholdsStr Time WFfile1 WFname1 WFfile2 WFname2 WFfile3 WFname3 WFfile4 WFname4
#
#The arguments DataRate TableType ThresholdsStr Time should be "N/A" in case of error/missing data

# --- vvv ---- UNCOMMENT TO DEBUG ARGUMENTS --- vvv ---
#set fdebug [open "d:\\debug.txt" "a+"]
#puts $fdebug "### showDDRwfs.tcl BEGIN ###"
#puts $fdebug "DataRate  =$env(DataRate)"
#puts $fdebug "TableType =$env(TableType)"
#if { [info exists ::env(EZWave_IMG_Path) ] } {		
#	puts $fdebug "EZWave_IMG_Path=$env(EZWave_IMG_Path)"
#}
#if { [info exists ::env(Thresholds) ] } {		
#	puts $fdebug "Thresholds=$env(Thresholds)"
#}
#puts $fdebug "Time      =$env(Time)"
#if { [info exists ::env(WFname1) ] } {		
#	puts $fdebug "WFname1   =$env(WFname1)"
#}
#if { [info exists ::env(WFname2) ] } {		
#	puts $fdebug "WFname2   =$env(WFname2)"
#}
#if { [info exists ::env(WFname3) ] } {		
#	puts $fdebug "WFname3   =$env(WFname3)"
#}
#if { [info exists ::env(WFname4) ] } {		
#	puts $fdebug "WFname4   =$env(WFname4)"
#}
#if { [info exists ::env(WFfile1) ] } {		
#	puts $fdebug "WFfile1   =$env(WFfile1)"
#}
#if { [info exists ::env(WFfile2) ] } {		
#	puts $fdebug "WFfile2   =$env(WFfile2)"
#}
#if { [info exists ::env(WFfile3) ] } {		
#	puts $fdebug "WFfile3   =$env(WFfile3)"
#}
#if { [info exists ::env(WFfile4) ] } {		
#	puts $fdebug "WFfile4   =$env(WFfile4)"
#}
#close $fdebug
# --- ^^^ ---- UNCOMMENT TO DEBUG ARGUMENTS --- ^^^ ---

proc draw_waveform {WFfile WFname WFlabel Option} {
	# needed to support files with spaces
	set WF [string map {"\"" ""} $WFfile]
	dataset open "$WF"
	set WF [file tail "$WF"]
	set WF [string map {".csv" ""} $WF]

	set wfn "<${WF}>$WFname"
	wfc "WF_str = \"$wfn\""
	set wfdraw [wfc {wf(WF_str)}]
	add wave $Option -zerolevel on -label $WFlabel $wfdraw
	return $wfdraw
}

proc zoom {DataRateEnv TimeEnv} {
	#set fdebug [open "d:\\debug.txt" "a+"]
	#puts $fdebug " A#"
	#close $fdebug
	
	set DataRate [expr {$DataRateEnv * 1e+6}]
	set Tclk [expr {1/($DataRate/2)}]
	if {$TimeEnv ne "N/A"} {
		#set fdebug [open "d:\\debug.txt" "a+"]
		#puts $fdebug " B#"
		#close $fdebug
		
		set Tmeas [expr {$TimeEnv * 1e-9}]
		# define Start and End values for zoom
		set Xstart [expr {$Tmeas - $Tclk/1.5}]
		if {$Xstart < 0 } {
			set Xstart 0
		}
		
		#set fdebug [open "d:\\debug.txt" "a+"]
		#puts $fdebug " C#"
		#close $fdebug

		set Xend [expr {$Tmeas + $Tclk/1.5}]
		wave zoomrange $Xstart $Xend
	}
}

proc add_one_horiz_cursor {TMeasDX YthresholdL YthresholdH case} {
	wfc "ThX = $TMeasDX"
	# get yval for cursor
	set yval [wfc {yval(wf(WF_str), ThX)}]
	
	# Choose which cursor to show - High or Low.
	# Draw cursor only if Setup Measurement (Hold Measuement) Y value is near threshold
	if {[expr abs($yval - $YthresholdL)] < 0.02} {
		# Add 'Setup_Low'/'Hold_Low' cursor
		wave addcursor -name ${case}_Low -horizontal -time $YthresholdL
	} elseif {[expr abs($yval - $YthresholdH)] < 0.02} {
		# Add 'Setup_High'/'Hold_High' cursor
		wave addcursor -name ${case}_High -horizontal -time $YthresholdH
	}
}

proc add_both_horiz_cursors {MeasType YthresholdL YthresholdH} {
	wave addcursor -name ${MeasType}_Low -horizontal -time $YthresholdL
	wave addcursor -name ${MeasType}_High -horizontal -time $YthresholdH
}

proc add_delta_marker {MeasType TmeasX1 TmeasY1 TMeasX2 TMeasY2 MeasX_ps WF1 WF2} {
	# first wf is  (TmeasX1, TMeasY1)
	# second wf is (TMeasX2, TMeasY2)
	wave adddeltamarker -xdelta -wf1 $WF1 -x1 $TmeasX1 -y1 $TmeasY1 -wf2 $WF2 -x2 $TMeasX2 -y2 $TMeasY2 -text "$MeasType=${MeasX_ps}ps"
}


if { [info exists env(Thresholds) ] } {
	set ThresholdsStr [string map {"\"" ""} $env(Thresholds)]
}

if {$env(TableType) eq "Skew"}  {
	# 1 window:
	# runEZwave.bat 1600 Skew "DQSRX|CLKRX;N/A|2.738" 2.738 ...
	# runEZwave.bat 1600 Skew "CLKRX|DQSRX;3.982|3.932" 3.982 ...
	# 2 windows:
	# runEZwave.bat 1600 Skew "CLKTX|CLKRX|DQSTX|DQSRX;2.156|2.738|2.069|2.685" 2.738 ...
	#                         |<-- ThresholdsStr ---------------------------->|
	#                         |<-- SkewlabelsStr ---->|<-- CursorsStr ------->|
	set temp [split $ThresholdsStr ";"]
	set SkewlabelsStr [lindex $temp 0]
	set Skewlabels [split $SkewlabelsStr "|"]
	set CursorsStr [lindex $temp 1]
	set Cursors [split $CursorsStr "|"]
	set WindowName [lindex $Skewlabels 0]
	append WindowName " - " [lindex $Skewlabels 1]
	wave closewindow -all
	wave addwindow -title $WindowName
	set Option "-append"
	set i 0
	foreach label $Skewlabels {
		set Cursor [lindex $Cursors $i]
		incr i
		set WF_name [string map {"\"" ""} $env(WFname$i)]
		set WF_label "$label=$WF_name"
		if {$i == 3} {
			zoom $env(DataRate) $env(Time)
			set WindowName $label
			append WindowName " - " [lindex $Skewlabels 3]
			wave addwindow -title $WindowName
		}
		draw_waveform $env(WFfile$i) $WF_name $WF_label $Option
		if {$Cursor ne "N/A"} {
			#set fdebug [open "d:\\debug.txt" "a+"]
			#puts $fdebug " D# Cursor = $Cursor"
			#close $fdebug

			set Tmeas [expr {$Cursor * 1e-9}]
			wave addcursor -name $label -time $Tmeas
		}
	}
	zoom $env(DataRate) $env(Time)
	if {$i == 4} {
		wave tile -horizontal
	}
} else {
	# runEZwave.bat 1600 Data "" N/A  ...
	# runEZwave.bat 1600 Data "Eye_Mask;0.3702;0.2302" 50.182 ...
	# runEZwave.bat 1600 Data "Setup;0.3702;0.2302;370.6" 68.932  ...
	# runEZwave.bat 1600 Data "Hold;0.3702;0.2302;194.7" 3.323 ...
	# runEZwave.bat 1600 Data "Pulse_Width;0.3002;0.2302" 72.058 ...
	# runEZwave.bat 1600 Data "" 60.182  ...
	# runEZwave.bat 1600 Data "tDIHL;0.3002;0.2302;0.3002;0.2302" 72.058 ...
	# runEZwave.bat 1600 Address "tDIHL;0.3002;0.2302;0.3002;0.2302" 72.058 ...
	# runEZwave.bat 1600 Diff_Overshoot "Horizontal;Overshoot_Peak;0.1635;Overshoot_Limit;0.3000" 1.923 ...
	# runEZwave.bat 1600 Diff_Undershoot "Horizontal;Undershoot_Peak;0.0011;Undershoot_Limit;0.3000" 1.301 ...
	# runEZwave.bat 1600 Differential "" 1.784 
	# runEZwave.bat 1600 Diff_Vix "" 3.364 
	# runEZwave.bat 1600 Diff_Vinse "Horizontal;Measurement_High;1.0019;Measurement_Low;-1.0019" 3.186 
	# runEZwave.bat 1600 Diff_Vinse "Horizontal;Vref;0.6332;Measurement;0.4340" 3.191
	# runEZwave.bat 1600 Diff_Vinse "Horizontal;Measurement;0.5528;Vref;0.6332" 3.810 
	set WF_name1 [string map {"\"" ""} $env(WFname1)]
	set WF1_label "$WF_name1"
	# load the second waveform first
	if { [info exists env(WFfile2) ] } {
		set WF_name2 [string map {"\"" ""} $env(WFname2)]
		# labels
		if {$env(TableType) eq "Data"} {
			set WF2_label "DQS=$WF_name2"
			set WF1_label "DQ=$WF_name1"
		} elseif {$env(TableType) eq "Address"} {
			set WF2_label "CLK=$WF_name2"
			set WF1_label "ADDR=$WF_name1"
		} elseif {$env(TableType) eq "Differential"} {
			set WF2_label "CLK=$WF_name2"
			set WF1_label "DQS=$WF_name1"
		} elseif {$env(TableType) eq "Diff_Vix" || $env(TableType) eq "Diff_Vinse" || $env(TableType) eq "Diff_Overshoot" || $env(TableType) eq "Diff_Undershoot"} {
			set WF2_label "Opp=$WF_name2"
			set WF1_label "Main=$WF_name1"
		}
		set WF2 [draw_waveform $env(WFfile2) $WF_name2 $WF2_label ""]
		#puts $fdebug "WF2 = $WF2"
		if {$env(Time) ne "N/A"} {
			#set fdebug [open "d:\\debug.txt" "a+"]
			#puts $fdebug " E#"
			#close $fdebug

			set TMeasX [expr {$env(Time) * 1e-9}]
			wfc "TmX = $TMeasX"
			set TMeasY1 [wfc {yval(wf(WF_str), TmX)}]
		}
	}
	set Option "-append"

	# Vix handled differently
	if {$env(TableType) eq "Diff_Vix" || $env(TableType) eq "Diff_Vinse" || $env(TableType) eq "Diff_Overshoot" || $env(TableType) eq "Diff_Undershoot"} {
		set Option "-append"
	}

	# draw first waveform
	set WF1 [draw_waveform $env(WFfile1) $WF_name1 $WF1_label $Option]

	# add threshold cursors
	# TODO: Implement common treshold transfer protocol.
	#       Now this should be synchronized with get_EZwave_linkwith procedure in createDDRreport.py, see thresholds_str
	set MeasX_ps ""
	if { [info exists env(Thresholds) ] } {
        #runEZwave.bat DataRate TableType ThresholdsStr Time WFfile1 WFname1 WFfile2 WFname2 WFfile3 WFname3 WFfile4 WFname4
		set fieldList [split $ThresholdsStr ";"]
		set MeasType [lindex $fieldList 0]
		set count [llength $fieldList]
		if {$MeasType eq "Vinse"} {
			# runEZwave.bat 1600 Diff_Vinse "Vinse;Measurement_High;1.0019;Measurement_Low;-1.0019" 3.186 ...
			# runEZwave.bat 1600 Diff_Vinse "Vinse;Vref;0.6332;Measurement;0.4340" 3.191 ...
			# runEZwave.bat 1600 Diff_Vinse "Vinse;Measurement;0.5528;Vref;0.6332" 3.810 ...

			for {set i 1} {$i < $count} {set i [expr {$i + 2}]} {
				set thresholdName [lindex $fieldList $i]
				set threshold [lindex $fieldList [expr {$i + 1}]]
				wave addcursor -name ${MeasType}_${thresholdName} -horizontal -time $threshold
			}
		} elseif {$MeasType eq "Overshoot" && $count eq 7} {
			# runEZwave.bat 1600 Diff_Overshoot "Overshoot;Measurement;0.163;Limit;0.3;Margin;0.1365" 3.186 ...
			#thresholds_ddr4 = [overshoot_meas, overshoot_limit, overshoot_margin]
			set Measurement [lindex $fieldList 2]
			set Limit [lindex $fieldList 4]
			set Margin [lindex $fieldList 6]
			if {$env(Time) ne "N/A" && $Measurement ne "N/A" && $Limit ne "N/A" && $Margin ne "N/A"} {
				set Measurement [expr {round($Measurement*100.0)/100.0}]
				set TMeasX [expr {$env(Time) * 1e-9}]
				wfc "TmX = $TMeasX"
				#TMeasY1 is already calculated, see line 193
				set TMeasY2 [wfc {yval(wf(WF_str), TmX)}]
				#Calculate PeakY = max(TMeasY1, TMeasY2)
				set PeakY [expr {$TMeasY1 > $TMeasY2 ? $TMeasY1 : $TMeasY2}]
				set VddY  [expr {round(100.0*($PeakY - $Measurement))/100.0}]
				set VddPlusLimitY  [expr {$VddY + $Limit}]
				
				wave addcursor -name Threshold -time $TMeasX
				if {$Measurement < 0.0 || $Measurement > 0.0} {
					#Nitin: The one mod I’d recommend is to turn off VddY/VssY and VddPlusLimitY/VssMinusLimitY if the corresponding Measurement is 0.  
					#If there is no over shoot or undershoot, the Measurement is set to zero (not a negative number).  (***)
					wave addcursor -name Vdd -horizontal -time $VddY
				}
				wave addcursor -name Peak -horizontal -time $PeakY
				if {$Measurement < 0.0 || $Measurement > 0.0} {
					# See comment above (***)
					wave addcursor -name Vdd_Plus_Limit -horizontal -time $VddPlusLimitY
				}
				# TODO: increase y axis range, to fit Vss_Minus_Limit cursor
			}
		} elseif {$MeasType eq "Undershoot" && $count eq 7} {
			# runEZwave.bat 1600 Diff_Undershoot "Undershoot;Measurement;0.11;Limit;0.3;Margin;0.2988" 3.186 ...
			#thresholds_ddr4 = [overshoot_meas, overshoot_limit, overshoot_margin]
			set Measurement [lindex $fieldList 2]
			set Limit [lindex $fieldList 4]
			set Margin [lindex $fieldList 6]
			if {$env(Time) ne "N/A" && $Measurement ne "N/A" && $Limit ne "N/A" && $Margin ne "N/A"} {
				set Measurement [expr {round($Measurement*100.0)/100.0}]
				set TMeasX [expr {$env(Time) * 1e-9}]
				wfc "TmX = $TMeasX"
				#TMeasY1 is already calculated, see line 193
				set TMeasY2 [wfc {yval(wf(WF_str), TmX)}]
				#Calculate PeakY = min(TMeasY1, TMeasY2)
				set PeakY [expr {$TMeasY1 < $TMeasY2 ? $TMeasY1 : $TMeasY2}]
				#round to 2 digits
				set VssY  [expr {round(100.0*($PeakY - $Measurement))/100.0}] 
				set VssMinusLimitY  [expr {$VssY - $Limit}]
				
				wave addcursor -name Threshold -time $TMeasX
				if {$Measurement < 0.0 || $Measurement > 0.0} {
					#Nitin: The one mod I’d recommend is to turn off VddY/VssY and VddPlusLimitY/VssMinusLimitY if the corresponding Measurement is 0.  
					#If there is no over shoot or undershoot, the Measurement is set to zero (not a negative number).  (***)
					#So, the voltage will unnaturally be shown at the peak voltage
					wave addcursor -name Vss -horizontal -time $VssY
				}
				wave addcursor -name Peak -horizontal -time $PeakY
				if {$Measurement < 0.0 || $Measurement > 0.0} {
					# See comment above (***)
					wave addcursor -name Vss_Minus_Limit -horizontal -time $VssMinusLimitY
				}
				# TODO: increase y axis range, to fit Vss_Minus_Limit cursor
			}
		} elseif {$MeasType eq "tDIHL" && $count eq 5} {
			# runEZwave.bat 1600 Data "tDIHL;0.7359;0.6609;0.7359;0.6609" 15.747 ...
			# runEZwave.bat 1600 Address "tDIHL;0.3002;0.2302;0.3002;0.2302" 72.058 ...
			
			# Cursors: H_(K), H_(L), V_(AG), V_(AH)
			set Horizontal_K [lindex $fieldList 1]
			set Horizontal_L [lindex $fieldList 2]
			set Vertical_AG [lindex $fieldList 3]
			set Vertical_AH [lindex $fieldList 4]

			if {$Horizontal_K ne "N/A"} {
				wave addcursor -name Upper_Eye_Mask -horizontal -time $Horizontal_K
			}
			if {$Horizontal_L ne "N/A"} {
				wave addcursor -name Lower_Eye_Mask -horizontal -time $Horizontal_L
			}
			if {$Vertical_AG ne "N/A"} {
				wave addcursor -name Signal_Trace_Point_Left -time $Vertical_AG
			}
			if {$Vertical_AH ne "N/A"} {
				wave addcursor -name Signal_Trace_Point_Right -time $Vertical_AH
			}
		} elseif {$MeasType eq "Vrx_2" && $count eq 3} {
		    #Vrx/2 cursors: H(VrxMs/1000), H(VrxR/1000)
		    #runEZwave.bat 1600 Diff_Vrx_2 "Vrx_2;1;2" 1234
			set Horizontal_VrxMs [lindex $fieldList 1]
			set Horizontal_VrxR [lindex $fieldList 2]

			if {$Horizontal_VrxMs ne "N/A"} {
				wave addcursor -name VrxMs -horizontal -time $Horizontal_VrxMs
			}
			if {$Horizontal_VrxR ne "N/A"} {
				wave addcursor -name VrxR -horizontal -time $Horizontal_VrxR
			}

		} else {
			set YthresholdH [lindex $fieldList 1]
			set YthresholdL [lindex $fieldList 2]
			if {$count eq 4} {
				set MeasX_ps [lindex $fieldList 3]
			}
			if {$env(Time) ne "N/A"} {
				# Threshold time
				#set fdebug [open "d:\\debug.txt" "a+"]
				#puts $fdebug " F#"
				#close $fdebug
				
				set TMeasX1 [expr {$env(Time) * 1e-9}]
				if {$MeasType eq "Setup" || $MeasType eq "Hold"} {
					# runEZwave.bat 1600 Data "Setup;0.8204;0.6844;220.0" 36.214  ...
					# runEZwave.bat 1600 Data "Hold;0.8109;0.6609;349.0" 33.872  ...
					# runEZwave.bat 1600 Address "Setup;0.925;0.575;448.6" 41.216 ...
					# runEZwave.bat 1600 Address "Hold;0.850;0.650;704.5" 38.716  ....
					#                                                               TMeasX1
					#                                                   MeasX_ps
					if {$MeasX_ps ne ""} {
						if {$MeasType eq "Setup"} {
							#set fdebug [open "d:\\debug.txt" "a+"]
							#puts $fdebug " G#"
							#close $fdebug

							set TMeasX2 [expr {$TMeasX1 - $MeasX_ps * 1e-12}]
						} else {
							#set fdebug [open "d:\\debug.txt" "a+"]
							#puts $fdebug " H#"
							#close $fdebug
							
							set TMeasX2 [expr {$TMeasX1 + $MeasX_ps * 1e-12}]
						}
						add_one_horiz_cursor $TMeasX2 $YthresholdL $YthresholdH $MeasType
						wfc "TmX2 = $TMeasX2"
						set TMeasY2 [wfc {yval(wf(WF_str), TmX2)}]
						add_delta_marker $MeasType $TMeasX1 $TMeasY1 $TMeasX2 $TMeasY2 $MeasX_ps $WF2 $WF1
					} else {
						add_both_horiz_cursors $MeasType $YthresholdL $YthresholdH
					}
				} elseif {$MeasType eq "Eye_Mask"} {
					# runEZwave.bat 1600 Data "Eye_Mask;0.8204;0.6844" 35.589 ...
					add_both_horiz_cursors $MeasType $YthresholdL $YthresholdH
					wave addcursor -name Threshold -time $TMeasX1
				} elseif {$MeasType eq "Pulse_Width"} {
					# runEZwave.bat 1600 Data "Pulse_Width;0.7359;0.6609" 15.747 ...
					wave addcursor -name ${MeasType} -horizontal -time $YthresholdH
					wave addcursor -name Threshold -time $TMeasX1
				}
			} else {
				add_both_horiz_cursors $MeasType $YthresholdL $YthresholdH
			}
		}
	} elseif {$env(Time) ne "N/A"} {
		# No Threshold environment variable (runEZwave.bat Thresholds parameter = "" ), show default vertical cursor then.
		#set fdebug [open "d:\\debug.txt" "a+"]
		#puts $fdebug " I#"
		#close $fdebug

		set TMeasX1 [expr {$env(Time) * 1e-9}]
		wave addcursor -name Threshold -time $TMeasX1
	}
	zoom $env(DataRate) $env(Time)
}
if { [info exists env(EZWave_IMG_Path) ] } {
	# write png $env(EZWave_IMG_Path) -colorasdisplayed -visiblewindows -resolution printerlow
	write png $env(EZWave_IMG_Path) -colorasdisplayed -visiblewindows
	dataset close -all
}
#set fdebug [open "d:\\debug.txt" "a+"]
#puts $fdebug "### showDDRwfs.tcl END ###"
#close $fdebug
