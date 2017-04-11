# A320Family ADIRS system
# Jonathan Redpath
# Minor Modifications by Joshua Davidson


#####################
# Initializing Vars #
#####################
# Initializing these vars here to prevent nasal nil used in numeric context, since the electrical system doesn't until fdm init is done. -JD
setprop("/systems/electrical/bus/dc1", 0);
setprop("/systems/electrical/bus/dc2", 0);
setprop("/systems/electrical/bus/dc-ess", 0);
setprop("/systems/electrical/bus/ac1", 0);
setprop("/systems/electrical/bus/ac2", 0);
setprop("/systems/electrical/bus/ac-ess", 0);

var ADIRSinit = func {
	var motionroll = getprop("/controls/adirs/motionroll");
	var motionpitch = getprop("/controls/adirs/motionpitch");
	setprop("controls/adirs/skip",0); #define this here, as we want this to be off on startup
	adirs_timer.start();
}

var ADIRSreset = func {
	setprop("/controls/adirs/numm", 0);
	setprop("instrumentation/adirs/ir[0]/aligned",0);
	setprop("instrumentation/adirs/ir[1]/aligned",0);
	setprop("instrumentation/adirs/ir[2]/aligned",0);
	setprop("instrumentation/adirs/ir[0]/display/ttn",0);
	setprop("instrumentation/adirs/ir[1]/display/ttn",0);
	setprop("instrumentation/adirs/ir[2]/display/ttn",0);
	setprop("instrumentation/adirs/ir[0]/display/status","- - - - - - - - ");
	setprop("instrumentation/adirs/ir[1]/display/status","- - - - - - - - ");
	setprop("instrumentation/adirs/ir[2]/display/status","- - - - - - - - ");
	setprop("controls/adirs/adr[0]/fault",0);
	setprop("controls/adirs/adr[1]/fault",0);
	setprop("controls/adirs/adr[2]/fault",0);
	setprop("controls/adirs/adr[0]/off",0);
	setprop("controls/adirs/adr[1]/off",0);
	setprop("controls/adirs/adr[2]/off",0);
	setprop("controls/adirs/display/text","");
	setprop("controls/adirs/display/dataknob","5");
	setprop("controls/adirs/display/selected","1");
	setprop("controls/adirs/ir[0]/align",0);
	setprop("controls/adirs/ir[1]/align",0);
	setprop("controls/adirs/ir[2]/align",0);
	setprop("controls/adirs/ir[0]/knob","0");
	setprop("controls/adirs/ir[1]/knob","0");
	setprop("controls/adirs/ir[2]/knob","0");
	setprop("controls/adirs/ir[0]/fault",0);
	setprop("controls/adirs/ir[1]/fault",0);
	setprop("controls/adirs/ir[2]/fault",0);
	setprop("controls/adirs/onbat",0);
	setprop("controls/adirs/skip",0);
	ADIRSinit();
}

var ir_align_loop = func(i) {
	var motionroll = getprop("/controls/adirs/motionroll");
	var motionpitch = getprop("/controls/adirs/motionpitch");
	var ttn = getprop("/instrumentation/adirs/ir[" ~ i ~ "]/display/ttn");
	if ((ttn >= 0) and (ttn < 0.99)) { #make it less sensitive
		ir_align_finish(i);
	} else {
		setprop("/instrumentation/adirs/ir[" ~ i ~ "]/display/ttn", ttn - 1);
	}
	var roll = getprop("/orientation/roll-deg");
	var pitch = getprop("/orientation/pitch-deg");
	var gs = getprop("/velocities/groundspeed-kt");
	if ((abs(motionroll - roll) > 0.15) or
			(abs(motionpitch - pitch) > 0.15) or (gs > 2)) {
		setprop("/instrumentation/adirs/ir[" ~ i ~ "]/display/status", "STS-XCESS MOTION");
		ir_align_abort(i);
	}
	setprop("/controls/adirs/motionroll", roll);
	setprop("/controls/adirs/motionpitch", pitch);

}

var ir0_align_loop_timer = maketimer(1, func{ir_align_loop(0)});
var ir1_align_loop_timer = maketimer(1, func{ir_align_loop(1)});
var ir2_align_loop_timer = maketimer(1, func{ir_align_loop(2)});


var ir_align_start = func(i) {
	if (((i == 0) and !ir0_align_loop_timer.isRunning) or
			((i == 1) and !ir1_align_loop_timer.isRunning) or
			((i == 2) and !ir2_align_loop_timer.isRunning)) {
		setprop("/instrumentation/adirs/ir[" ~ i ~ "]/display/ttn", (math.sin((getprop("/position/latitude-deg") / 90) * (math.pi / 2)) * 720) + 300);
		motionroll = getprop("/orientation/roll-deg");
		motionpitch = getprop("/orientation/pitch-deg");
		if (i == 0) {
			ir0_align_loop_timer.start();
		} else if (i == 1) {
			ir1_align_loop_timer.start();
		} else if (i == 2) {
			ir2_align_loop_timer.start();
		}
		setprop("/controls/adirs/ir[" ~ i ~ "]/align", 1);
	}
}

var ir_align_finish = func(i) {
	setprop("/instrumentation/adirs/ir[" ~ i ~ "]/aligned", 1);
	if (i == 0) {
		ir0_align_loop_timer.stop();
	} else if (i == 1) {
		ir1_align_loop_timer.stop();
	} else if (i == 2) {
		ir2_align_loop_timer.stop();
	}
	setprop("/controls/adirs/ir[" ~ i ~ "]/align", 0);
}

var ir_align_abort = func(i) {
	setprop("/controls/adirs/ir[" ~ i ~ "]/fault", 1);
	if (i == 0) {
		ir0_align_loop_timer.stop();
	} else if (i == 1) {
		ir1_align_loop_timer.stop();
	} else if (i == 2) {
		ir2_align_loop_timer.stop();
	}
	setprop("/controls/adirs/ir[" ~ i ~ "]/align", 0);
}

var ir_knob_move = func(i) {
	var knob = getprop("/controls/adirs/ir[" ~ i ~ "]/knob");
	if (knob == 1) {
		setprop("/controls/adirs/ir[" ~ i ~ "]/align", 0);
		setprop("/controls/adirs/ir[" ~ i ~ "]/fault", 0);
		setprop("/instrumentation/adirs/ir[" ~ i ~ "]/aligned", 0);
		setprop("/instrumentation/adirs/ir[" ~ i ~ "]/display/status", "- - - - - - - - ");
		if (i == 0) {
			ir0_align_loop_timer.stop();
		} else if (i == 1) {
			ir1_align_loop_timer.stop();
		} else if (i == 2) {
			ir2_align_loop_timer.stop();
		}
	} else if (knob == 2) {
		if ( !getprop("/instrumentation/adirs/ir[" ~ i ~ "]/aligned") and
				(getprop("/systems/electrical/bus/ac-ess") > 9) ) {
			ir_align_start(i);
		}
	}
}

setlistener("/controls/adirs/ir[0]/knob", func { ir_knob_move(0) });
setlistener("/controls/adirs/ir[1]/knob", func { ir_knob_move(1) });
setlistener("/controls/adirs/ir[2]/knob", func { ir_knob_move(2) });

var onbat_light = func {
	if (((getprop("/systems/electrical/bus/dc1") > 25) or (getprop("/systems/electrical/bus/dc2") > 25)) and 
			((getprop("/systems/electrical/bus/ac1") < 110) and getprop("/systems/electrical/bus/ac2") < 110) and
			((getprop("/controls/adirs/ir[0]/knob") > 1) or
			(getprop("/controls/adirs/ir[1]/knob") > 1) or
			(getprop("/controls/adirs/ir[2]/knob") > 1))) {
		setprop("/controls/adirs/onbat", 1);
	} else {
		setprop("/controls/adirs/onbat", 0);
	}
}

var onbat_light_b = func {
	setprop("/controls/adirs/onbat", 1);
	setprop("/controls/adirs/numm", 0);
	interpolate("/controls/adirs/numm", 5, 4);
	var nummlist = setlistener("/controls/adirs/numm", func {
		if (getprop("/controls/adirs/numm") == 5) {
			removelistener(nummlist);
			onbat_light();
		}
	});
}

setlistener("/controls/electrical/switches/gen-apu", onbat_light);
setlistener("/controls/electrical/switches/gen1", onbat_light);
setlistener("/controls/electrical/switches/gen2", onbat_light);
setlistener("/controls/electrical/switches/gen-ext", onbat_light);
setlistener("/systems/electrical/bus/ac-ess", onbat_light);
setlistener("/controls/adirs/ir[0]/knob", onbat_light_b);
setlistener("/controls/adirs/ir[1]/knob", onbat_light_b);
setlistener("/controls/adirs/ir[2]/knob", onbat_light_b);


var adirs_display = func() {
	var data_knob = getprop("/controls/adirs/display/dataknob");
	var selected_ir = getprop("/controls/adirs/display/selected");
	if ( selected_ir == 1 ) {
		setprop("/controls/adirs/display/text", "");
	} else {
		if ( data_knob == 1 ) {
			setprop("/controls/adirs/display/text", "888888888888888");
		} else if ( data_knob == 2 ) {
			if ( ((selected_ir == 2) and getprop("/instrumentation/adirs/ir[0]/aligned")) or
				((selected_ir == 3) and getprop("/instrumentation/adirs/ir[2]/aligned")) or
				((selected_ir == 4) and getprop("/instrumentation/adirs/ir[1]/aligned")) ) {
					setprop("/controls/adirs/display/text", sprintf("     %03i", getprop("/orientation/track-magnetic-deg")) ~ sprintf("     %03i", getprop("/velocities/groundspeed-kt")));
			} else {
				setprop("/controls/adirs/display/text", "- - - - - - - - ");
			}
		} else if ( data_knob == 3 ) {
			var lat = abs(getprop("/position/latitude-deg"));
			var lon = abs(getprop("/position/longitude-deg"));
			setprop("/controls/adirs/display/text", substr(getprop("/position/latitude-string"), -1, 1) ~
								sprintf("%2i", lat) ~ "'" ~
								sprintf("%2.1f", (lat - math.floor(lat)) * 60) ~
								substr(getprop("/position/longitude-string"), -1, 1) ~
								sprintf("%3i", lon) ~ "'" ~
								sprintf("%2.1f", (lon - math.floor(lon)) * 60));
		} else if ( data_knob == 4 ) {
			if ( ((selected_ir == 2) and getprop("/instrumentation/adirs/ir[0]/aligned")) or
				((selected_ir == 3) and getprop("/instrumentation/adirs/ir[2]/aligned")) or
				((selected_ir == 4) and getprop("/instrumentation/adirs/ir[1]/aligned")) ) {
					setprop("/controls/adirs/display/text", sprintf("     %03i", getprop("/environment/wind-from-heading-deg")) ~ sprintf("     %03i", getprop("/environment/wind-speed-kt")));
			} else {
				setprop("/controls/adirs/display/text", "- - - - - - - - ");
			}
		} else if ( data_knob == 5 ) {
			# Time to Nav
			if ( ((selected_ir == 2) and getprop("/instrumentation/adirs/ir[0]/aligned")) or
				((selected_ir == 3) and getprop("/instrumentation/adirs/ir[2]/aligned")) or
				((selected_ir == 4) and getprop("/instrumentation/adirs/ir[1]/aligned")) ) {
					setprop("/controls/adirs/display/text", sprintf("   %3.1f", getprop("/orientation/heading-deg")) ~ "- - - - ");
			} else {
				if ( (selected_ir == 2) and getprop("/controls/adirs/ir[0]/align") ) {
					setprop("controls/adirs/display/text", "- - - - " ~ sprintf(" TTN %2i", (getprop("/instrumentation/adirs/ir[0]/display/ttn") / 60)));
				} else if ( (selected_ir == 3) and getprop("/controls/adirs/ir[2]/align") ) {
					setprop("controls/adirs/display/text", "- - - - " ~ sprintf(" TTN %2i", (getprop("/instrumentation/adirs/ir[2]/display/ttn") / 60)));
				} else if ( (selected_ir == 4) and getprop("/controls/adirs/ir[1]/align") ) {
					setprop("controls/adirs/display/text", "- - - - " ~ sprintf(" TTN %2i", (getprop("/instrumentation/adirs/ir[1]/display/ttn") / 60)));
				} else {
					setprop("/controls/adirs/display/text", "- - - - - - - - ");
				}
			}	
		} else if ( data_knob == 6 ) {
			if ( selected_ir == 2 ) {
				#var ir0dispstat = getprop("/instrumentation/adirs/ir[0]/display/status");
				setprop("/controls/adirs/display/text","- - - - - - - - ");
			} else if ( selected_ir == 3 ) {
				#var ir1dispstat = getprop("/instrumentation/adirs/ir[1]/display/status");
				setprop("/controls/adirs/display/text","- - - - - - - - ");
			} else if ( selected_ir == 4 ) {
				#var ir2dispstat = getprop("/instrumentation/adirs/ir[2]/display/status");
				setprop("/controls/adirs/display/text","- - - - - - - - ");
			}
		}
	}
}
var skip_ADIRS = func {
	setprop("controls/adirs/display/selected","2");
	setprop("controls/adirs/ir[0]/knob","2");
	setprop("controls/adirs/ir[1]/knob","2");
	setprop("controls/adirs/ir[2]/knob","2");
	setprop("instrumentation/adirs/ir[0]/display/ttn",1); #set it to 1 so it counts down from 1 to 0
	setprop("instrumentation/adirs/ir[1]/display/ttn",1);
	setprop("instrumentation/adirs/ir[2]/display/ttn",1);
}

var adirs_skip = setlistener("/controls/adirs/skip", func {
	var skipping = getprop("/controls/adirs/skip");
		if (skipping == 1) {
			skip_ADIRS();
		}
	});

var adirs_timer = maketimer(1, adirs_display);

