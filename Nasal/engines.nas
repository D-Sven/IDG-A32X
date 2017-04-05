# A320Family JSB Engine System
# Joshua Davidson (it0uchpods)

#####################
# Initializing Vars #
#####################

var engines = props.globals.getNode("/engines").getChildren("engine");
var n1_min = 23.4;
var n2_min = 63.7;
var egt_min = 323;
var n1_spin = 5.1;
var n2_spin = 22.8;
var n1_start = 23.3;
var n2_start = 63.6;
var egt_start = 489;
var n1_max = 105.8;
var n2_max = 102.1;
var egt_max = 860;
var n1_wm = 0;
var n2_wm = 0;
var apu_max = 99.8;
var apu_egt_max = 462;
var spinup_time = 15;
var start_time = 10;
var egt_lightup_time = 3;
var egt_lightdn_time = 7;
var shutdown_time = 20;
var egt_shutdown_time = 20;
setprop("/systems/apu/rpm", 0);
setprop("/systems/apu/egt", 42);

##############################
# Trigger Startups and Stops #
##############################

setlistener("/controls/engines/engine[0]/cutoff-switch", func {
	if (getprop("/controls/engines/engine[0]/cutoff-switch") == 0) {
		start_one_check();
	} else if (getprop("/controls/engines/engine[0]/cutoff-switch") == 1) {
		setprop("/controls/engines/engine[0]/starter", 0);
		setprop("/controls/engines/engine[0]/cutoff", 1);
		setprop("/engines/engine[0]/state", 0);
		interpolate(engines[0].getNode("egt-actual"), 0, egt_shutdown_time);
	}
});

var start_one_check = func {
	if ((getprop("/controls/engines/engine-start-switch") == 2) and (getprop("/controls/APU/bleed") == 1) and (getprop("/systems/apu/rpm") >= 98)) {
		auto_start_one();
	}
}

setlistener("/controls/engines/engine[1]/cutoff-switch", func {
	if (getprop("/controls/engines/engine[1]/cutoff-switch") == 0) {
		start_two_check();
	} else if (getprop("/controls/engines/engine[1]/cutoff-switch") == 1) {
		setprop("/controls/engines/engine[1]/starter", 0);
		setprop("/controls/engines/engine[1]/cutoff", 1);
		setprop("/engines/engine[0]/state", 0);
		interpolate(engines[1].getNode("egt-actual"), 0, egt_shutdown_time);
	}
});

var start_two_check = func {
	if ((getprop("/controls/engines/engine-start-switch") == 2) and (getprop("/controls/APU/bleed") == 1) and (getprop("/systems/apu/rpm") >= 98)) {
		auto_start_two();
	}
}

####################
# Start Engine One #
####################

var auto_start_one = func {
	setprop("/engines/engine[0]/state", 1);
	setprop("/controls/engines/engine[0]/starter", 1);
	eng_one_auto_startt.start();
}

var eng_one_auto_start = func {
	if (getprop("/engines/engine[0]/n2") >= 24.1) {
		setprop("/engines/engine[0]/state", 2);
		setprop("/controls/engines/engine[0]/cutoff", 0);
		interpolate(engines[0].getNode("egt-actual"), egt_start, egt_lightup_time);
		eng_one_n2_checkt.start();
		eng_one_auto_startt.stop();
	}
}

var eng_one_n2_check = func {
	if (getprop("/engines/engine[0]/egt-actual") >= egt_start) {
		interpolate(engines[0].getNode("egt-actual"), egt_min, egt_lightdn_time);
	}
	if (getprop("/engines/engine[0]/n2") >= n2_start) {
		setprop("/engines/engine[0]/state", 3);
		eng_one_n2_checkt.stop();
	}
}

####################
# Start Engine Two #
####################

var auto_start_two = func {
	setprop("/engines/engine[1]/state", 1);
	setprop("/controls/engines/engine[1]/starter", 1);
	eng_two_auto_startt.start();
}

var eng_two_auto_start = func {
	if (getprop("/engines/engine[1]/n2") >= 24.1) {
		setprop("/engines/engine[1]/state", 2);
		setprop("/controls/engines/engine[1]/cutoff", 0);
		interpolate(engines[1].getNode("egt-actual"), egt_start, egt_lightup_time);
		eng_two_n2_checkt.start();
		eng_two_auto_startt.stop();
	}
}

var eng_two_n2_check = func {
	if (getprop("/engines/engine[1]/egt-actual") >= egt_start) {
		interpolate(engines[1].getNode("egt-actual"), egt_min, egt_lightdn_time);
	}
	if (getprop("/engines/engine[1]/n2") >= n2_start) {
		setprop("/engines/engine[1]/state", 3);
		eng_two_n2_checkt.stop();
	}
}

#############
# Start APU #
#############

setlistener("/controls/APU/start", func {
	if ((getprop("/controls/APU/master") == 1) and (getprop("/controls/APU/start") == 1)) {
		interpolate("/systems/apu/rpm", apu_max, spinup_time);
		interpolate("/systems/apu/egt", apu_egt_max, spinup_time);
	} else if (getprop("/controls/APU/master") == 0) {
		apu_stop();
	}
});

############
# Stop APU #
############

setlistener("/controls/APU/master", func {
	if (getprop("/controls/APU/master") == 0) {
		setprop("/controls/APU/start", 0);
		apu_stop();
	}
});

var apu_stop = func {
	interpolate("/systems/apu/rpm", 0, spinup_time);
	interpolate("/systems/apu/egt", 42, spinup_time);
}

#######################
# Various other stuff #
#######################

setlistener("/controls/engines/engine-start-switch", func {
	if ((getprop("/controls/engines/engine-start-switch") == 0) or (getprop("/controls/engines/engine-start-switch") == 1)) {
		if (getprop("/controls/engines/engine[0]/state") == 1) {
			eng_one_stop();
		}
		if (getprop("/controls/engines/engine[1]/state") == 1) {
			eng_two_stop();
		}
	}
});

setlistener("/controls/APU/bleed", func {
	if (getprop("/controls/APU/bleed") == 0) {
		if (getprop("/controls/engines/engine[0]/state") == 1) {
			eng_one_stop();
		}
		if (getprop("/controls/engines/engine[1]/state") == 1) {
			eng_two_stop();
		}
	}
});

# Timers
var eng_one_auto_startt = maketimer(0.5, eng_one_auto_start);
var eng_one_n2_checkt = maketimer(0.5, eng_one_n2_check);
var eng_two_auto_startt = maketimer(0.5, eng_two_auto_start);
var eng_two_n2_checkt = maketimer(0.5, eng_two_n2_check);
