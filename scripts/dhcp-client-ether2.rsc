local addRoutes [:parse [/system/script/get add-routes source]];

:local yandexDns1 77.88.8.1;
:local yandexDns2 77.88.8.8;

$addRoutes \
bound=$bound \
gatewayAddress=$"gateway-address" \
defaultRouteMark="isp1-default" \
defaultRouteDistance=251 \
checkRouteMark="isp1-check" \
routingTableName="to-isp1-table" \
tableRouteMark="to-isp1-table-default" \
connectionMark="con-isp1" \
checkRouteDstAddress=$yandexDns1;
