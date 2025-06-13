for ((i=1; i<=10; i++)); do
    curl -i https://trade-imports-decision-comparer.perf-test.cdp-int.defra.cloud
    echo 
    curl -i https://btms-gateway.perf-test.cdp-int.defra.cloud
    echo 
    sleep 5
done