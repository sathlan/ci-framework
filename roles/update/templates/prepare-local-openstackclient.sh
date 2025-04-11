#!/usr/bin/bash

CT_NAME=lopenstackclient
OSDPNS_NAME=openstack-edpm
IMAGE=brew.$(oc get pods openstackclient -o json | jq -r .spec.containers[0].image)
OSDPNS=$(oc get osdpns $OSDPNS_NAME  -n openstack -o json)

oc rsh openstackclient cat .config/openstack/clouds.yaml > clouds.yaml
oc rsh openstackclient cat .config/openstack/secure.yaml > secure.yaml
cat > openstack <<'EOF'
#!/bin/bash
OS_CLOUD=default /usr/bin/openstack --insecure "$@"
EOF
chmod +x ./openstack
username=$(echo "$OPDPNS" | jq -r '.spec.nodeTemplate.ansible.ansibleVars.edpm_container_registry_logins["brew.registry.redhat.io"] | to_entries | .[0].key')
password=$(echo "$OPDPNS" | jq -r '.spec.nodeTemplate.ansible.ansibleVars.edpm_container_registry_logins["brew.registry.redhat.io"] | to_entries | .[0].value')
podman login -u "$username" -p "$password" brew.registry.redhat.io

podman run --network=host \
       -v /home/zuul/clouds.yaml:/home/cloud-admin/.config/openstack/clouds.yaml:ro,z \
       -v /home/zuul/secure.yaml:/home/cloud-admin/.config/openstack/secure.yaml:ro,z \
       -v /home/zuul/openstack:/home/cloud-admin/.local/bin/openstack:ro,z \
       -d --name $CT_NAME \
       $IMAGE \
       /usr/bin/sleep infinity

# cat workload_launch.sh | podman exec -i foobar bash -i
