local addRoutes [:parse [/system/script/get add-routes source]];

:local yandexDns1 77.88.8.1;
:local yandexDns2 77.88.8.8;

$addRoutes \
bound=$bound \
gatewayAddress=$"gateway-address" \
defaultRouteMark="isp2-default" \
defaultRouteDistance=252 \
checkRouteMark="isp2-check" \
routingTableName="to-isp2-table" \
tableRouteMark="to-isp2-table-default" \
connectionMark="con-isp2" \
checkRouteDstAddress=$yandexDns2;
