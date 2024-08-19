:local failover do={
  # <-----------options---------------->
  :local yandexDns1 77.88.8.1;
  :local yandexDns2 77.88.8.8;

  :local checkDnsIsp1 $yandexDns1;
  :local checkDnsIsp2 $yandexDns2;
  :local routeMarkIsp1 "isp1-default";
  :local routeMarkIsp2 "isp2-default";
  :local connectionMarkIsp1 "con-isp1";
  :local connectionMarkIsp2 "con-isp2";
  :local forceUseEnabled false;
  :local forceUseIsp "isp1";
  # :local forceUseIsp "isp2";
  # <-----------options---------------->

  :local pingLimit 5;
  :local hasRouteIsp1 [:tobool [/ip route find comment=$routeMarkIsp1]];
  :local hasRouteIsp2 [:tobool [/ip route find comment=$routeMarkIsp2]];
  :local pingsCountIsp1 0;
  :local pingsCountIsp2 0;
  :local isRouteDisabledIsp1 false;
  :local isRouteDisabledIsp2 false;

  :if (!$hasRouteIsp1) do={ :log warn "failover: missing isp1 route"; }
  :if (!$hasRouteIsp2) do={ :log warn "failover: missing isp2 route"; }

  :if ($hasRouteIsp1) do={
    :set pingsCountIsp1 [/ping $checkDnsIsp1 count=$pingLimit];
    :set isRouteDisabledIsp1 [/ip route get [find comment=$routeMarkIsp1] disable];

    :if ($pingsCountIsp1=$pingLimit && $isRouteDisabledIsp1) do={
      :log info "failover: enable isp1 route";
      /ip route enable [find comment=$routeMarkIsp1];

      :if ($forceUseEnabled && $forceUseIsp = "isp1") do={
        :delay 2;
        :log info "failover: remove connections with mark $connectionMarkIsp2";
        /ip firewall connection remove [find connection-mark=$connectionMarkIsp2];
      }
    }
  }

  :if ($hasRouteIsp2) do={
    :set pingsCountIsp2 [/ping $checkDnsIsp2 count=$pingLimit];
    :set isRouteDisabledIsp2 [/ip route get [find comment=$routeMarkIsp2] disable];

    :if ($pingsCountIsp2=$pingLimit && $isRouteDisabledIsp2) do={
      :log info "failover: enable isp2 route";
      /ip route enable [find comment=$routeMarkIsp2];

      :if ($forceUseEnabled && $forceUseIsp = "isp2") do={
        :delay 2;
        :log info "failover: remove connections with mark $connectionMarkIsp1";
        /ip firewall connection remove [find connection-mark=$connectionMarkIsp1];
      }
    }
  }

  :log info "failover: route isp1 pings: $pingsCountIsp1; route isp2 pings: $pingsCountIsp2";

  :if ($hasRouteIsp1 && $pingsCountIsp1=0 && $pingsCountIsp2=$pingLimit && !$isRouteDisabledIsp1) do={
    :log info "failover: disable $routeMarkIsp1 route";
    /ip route disable [find comment=$routeMarkIsp1];
    :delay 2;
    :log info "failover: remove connections with mark $connectionMarkIsp1";
    /ip firewall connection remove [find connection-mark=$connectionMarkIsp1];
  }

  :if ($hasRouteIsp2 && $pingsCountIsp2=0 && $pingsCountIsp1=$pingLimit && !$isRouteDisabledIsp2) do={
    :log info "failover: disable $routeMarkIsp2 route";
    /ip route disable [find comment=$routeMarkIsp2];
    :delay 2;
    :log info "failover: remove connections with mark $connectionMarkIsp2";
    /ip firewall connection remove [find connection-mark=$connectionMarkIsp2];
  }
}

$failover;
