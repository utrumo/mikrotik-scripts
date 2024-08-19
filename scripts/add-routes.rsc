:local addRoutes do={
  :if ($bound = 0) do={
    /ip route remove [find comment=$defaultRouteMark];
    /ip route remove [find comment=$checkRouteMark];
    /ip route remove [find comment=$tableRouteMark];
    :delay 2;
    /ip firewall connection remove [find connection-mark=$connectionMark];
    :return nil;
  }

  :local defaultRoutesCount [/ip route print count-only where comment=$defaultRouteMark];

  :if ($defaultRoutesCount = 0) do={
    /ip route add gateway=$gatewayAddress distance=$defaultRouteDistance comment=$defaultRouteMark;
    /ip route add gateway=$gatewayAddress distance=10 dst-address=$checkRouteDstAddress comment=$checkRouteMark;

    :local hasTable [:tobool [/routing table find name=$routingTableName]];
    :if (!$hasTable) do={ /routing table add fib name=$routingTableName }

    /ip route add gateway=$gatewayAddress distance=10 routing-table=$routingTableName comment=$tableRouteMark;
    :return nil;
  }

  :if ($defaultRoutesCount = 1) do={
    :local defaultRoute [/ip route find where comment=$defaultRouteMark];
    :local defaultRouteGateway [/ip route get $defaultRoute gateway];
    :if ($defaultRouteGateway != $gatewayAddress) do={ /ip route set $defaultRoute gateway=$gatewayAddress; }

    :local checkRoute [/ip route find where comment=$checkRouteMark];
    :local checkRouteGateway [/ip route get $checkRouteMark gateway];
    :if ($checkRouteGateway != $gatewayAddress) do={ /ip route set $checkRoute gateway=$gatewayAddress; }

    :local tableRoute [/ip route find where comment=$tableRouteMark];
    :local tableRouteGateway [/ip route get $tableRoute gateway];
    :if ($tableRouteGateway != $gatewayAddress) do={ /ip route set $tableRoute gateway=$gatewayAddress; }
    :return nil;
  }

  :error "Multiple default routes found";
}

$addRoutes \
bound=$bound \
gatewayAddress=$gatewayAddress \
defaultRouteMark=$defaultRouteMark \
defaultRouteDistance=$defaultRouteDistance \
checkRouteMark=$checkRouteMark \
routingTableName=$routingTableName \
tableRouteMark=$tableRouteMark \
connectionMark=$connectionMark \
checkRouteDstAddress=$checkRouteDstAddress;
