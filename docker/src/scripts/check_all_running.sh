cat <<EOF >  ~/project/.circleci/check_all_running.sh

#!/bin/bash

function checkUp(   )
{
    running="$(docker-compose ps --services --filter "status=running")"
    services="$(docker-compose ps --services)"
    if [ "$running" != "$services" ]; then
        echo "Wait running" 
        comm -13 <(sort <<<"$running") <(sort <<<"$services")

        sleep 10
        checkUp
    else
        echo "All services are running"
    fi
}

checkUp

EOF

bash ~/project/.circleci/check_all_running.sh