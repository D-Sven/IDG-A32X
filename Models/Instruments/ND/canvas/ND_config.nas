canvas.NDConfig = {
    properties: {
        des_apt: "/autopilot/route-manager/destination/airport",
        dep_apt: "/autopilot/route-manager/departure/airport",
        des_rwy: "/autopilot/route-manager/destination/runway",
        dep_rwy: "/autopilot/route-manager/departure/runway",
        fplan_active: 'autopilot/route-manager/active',
        athr: '/it-autoflight/output/athr',
        cur_wp: "/autopilot/route-manager/current-wp",
        vnav_node: "/autopilot/route-manager/vnav/",
        spd_node: "/autopilot/route-manager/spd/",
        holding: "/flight-management/hold",
        holding_points: "/flight-management/hold/points",
        adf1_frq: 'instrumentation/adf/frequencies/selected-khz',
        adf2_frq: 'instrumentation/adf[1]/frequencies/selected-khz',
        nav1_frq: 'instrumentation/nav/frequencies/selected-mhz',
        nav2_frq: 'instrumentation/nav[1]/frequencies/selected-mhz',
        lat_ctrl: 'flight-management/control/lat-ctrl',
        ver_ctrl: "flight-management/control/ver-ctrl",
    }
};
