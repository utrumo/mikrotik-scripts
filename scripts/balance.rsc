:local balance do={
  # <-----------options---------------->
  :local maxSpeedInMbitsIsp1 93;
  :local maxSpeedInMbitsIsp2 21;

  :local interfaceIsp1 "ether2";
  :local interfaceIsp2 "ether3";
  :local defaultRouteMarkIsp1 "isp1-default";
  :local defaultRouteMarkIsp2 "isp2-default";
  # <-----------options---------------->

  :local distanceFrom 251;
  :local distanceTo 253;

  :local hasDefaultRouteIsp1 [:tobool [/ip route find comment=$defaultRouteMarkIsp1]];
  :local hasDefaultRouteIsp2 [:tobool [/ip route find comment=$defaultRouteMarkIsp2]];

  :if (!$hasDefaultRouteIsp1) do={
    :log warn "balance: missing $defaultRouteMarkIsp1 route, exit";
    :return nil;
  }

  :if (!$hasDefaultRouteIsp2) do={
    :log warn "balance: missing $defaultRouteMarkIsp2 route, exit";
    :return nil;
  }

  :local isDefaultRouteDisabledIsp1 [/ip route get [find comment=$defaultRouteMarkIsp1] disable];
  :local isDefaultRouteDisabledIsp2 [/ip route get [find comment=$defaultRouteMarkIsp2] disable];

  :if ($isDefaultRouteDisabledIsp1) do={
    :log warn "balance: disabled $defaultRouteMarkIsp1 route, exit";
    :return nil;
  }

  :if ($isDefaultRouteDisabledIsp2) do={
    :log warn "balance: disabled $defaultRouteMarkIsp2 route, exit";
    :return nil;
  }

  :local maxSpeedInBitsIsp1 ($maxSpeedInMbitsIsp1 * 1000 * 1000);
  :local maxSpeedInBitsIsp2 ($maxSpeedInMbitsIsp2 * 1000 * 1000);

  # rx-bits-per-second: rx - receive from interface
  # tx-bits-per-second: tx - transmit to interface
  :local bitsPerSecondIsp1 ([/interface monitor-traffic $interfaceIsp1 once as-value]->"rx-bits-per-second");
  :local bitsPerSecondIsp2 ([/interface monitor-traffic $interfaceIsp2 once as-value]->"rx-bits-per-second");

  :local loadInPercentIsp1 ($bitsPerSecondIsp1 * 100 / $maxSpeedInBitsIsp1);
  :local loadInPercentIsp2 ($bitsPerSecondIsp2 * 100 / $maxSpeedInBitsIsp2);

  if ($loadInPercentIsp1 = 0 && $loadInPercentIsp2 = 0) do={
    :log info "balance: no load on any interface";
    :return nil;
    };

  :local distance [/ip route/get value-name=distance number=[find comment=$defaultRouteMarkIsp1]];

  :local activeRoute $defaultRouteMarkIsp1;
  if ($distance = $distanceTo) do={ :set activeRoute $defaultRouteMarkIsp2; }

  :log info "balance: isp1 load: $loadInPercentIsp1%, isp2 load: $loadInPercentIsp2%, active route: $activeRoute";

  if ($loadInPercentIsp1 > $loadInPercentIsp2) do={
    if ($distance != $distanceTo) do={
      :log info "balance: loading isp1 > isp2 - change distance for route $defaultRouteMarkIsp1 from $distanceFrom to $distanceTo";
      /ip route set distance=$distanceTo numbers=[find comment=$defaultRouteMarkIsp1];
    }
  }

  if ($loadInPercentIsp1 < $loadInPercentIsp2) do={
    if ($distance != $distanceFrom) do={
      :log info "balance: loading isp1 < isp2 - change distance for route $defaultRouteMarkIsp1 from $distanceTo to $distanceFrom";
      /ip route set distance=$distanceFrom numbers=[find comment=$defaultRouteMarkIsp1];
    }
  }
}

$balance;
