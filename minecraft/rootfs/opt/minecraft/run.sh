#!/usr/bin/env bashio

EULA_PATH="eula.txt"
SERVER_PROPERTIES_PATH="server.properties"
JAVA_ARGS=${JAVA_ARGS:-'-XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M'}
SERVER_ARGS=${SERVER_ARGS:-''}
bashio::log.info "Minecraft server is starting... Version 2.1.0 of script"
main() {
 local jar_file="${1:-'server.jar'}"
    local port=$(bashio::addon.port 25565)

    # Ensure /share/minecraft exists and link /data to it
    mkdir -p /share/minecraft
    if [ -d /data ] && [ ! -L /data ]; then
      # Move existing data into /share/minecraft if any (optional)
      mv /data/* /share/minecraft/ 2>/dev/null || true
      rm -rf /data
    fi
    ln -sfn /share/minecraft /data

    bashio::log.debug "Working directory is ${PWD}"

    if [ ! -f "${jar_file}" ]; then
        bashio::log.fatal "The jar file '${jar_file}' is not accessible."
        exit 1
    fi

    write_eula "${EULA_PATH}"
    write_server_properties "${SERVER_PROPERTIES_PATH}"

    run -jar "${jar_file}" ${SERVER_ARGS} --nogui --universe /data --port "${port}"
}

write_eula() {
	local path="$1"
	local eula=$(bashio::config eula)
	cat <<-TEXT >"${path}"
		eula=${eula}
	TEXT
	bashio::log.debug "Updated ${path}"
}

write_server_properties() {
	local path="$1"
	local config=$(bashio::addon.config)
	bashio::jq "${config}" 'to_entries|map("\(.key)=\(.value)")|join("\n")' >"${path}"
	bashio::log.debug "Updated ${path}"
}

run() {
	bashio::log.debug "Running java with the following args:"
	bashio::log.debug "${JAVA_ARGS}"
	java ${JAVA_ARGS} "$@"
}

main "$@"
