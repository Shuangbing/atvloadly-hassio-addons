#!/usr/bin/with-contenv bashio

set -euo pipefail

readonly app_dir="/opt/atvloadly"
readonly data_dir="/data"
readonly config_path="${data_dir}/config.yaml"
readonly settings_path="${data_dir}/settings.json"
readonly ingress_proxy_port="58080"

service_port="$(bashio::config 'service_port')"
language="$(bashio::config 'language')"
log_level="$(bashio::config 'log_level')"
http_proxy="$(bashio::config 'http_proxy')"
https_proxy="$(bashio::config 'https_proxy')"
ddi_cn_proxy="$(bashio::config 'developer_disk_image_cn_proxy')"
ddi_image_source="$(bashio::config 'developer_disk_image_image_source')"

if [[ -z "${service_port}" ]]; then
  service_port="5533"
fi

if [[ "${service_port}" == "${ingress_proxy_port}" ]]; then
  bashio::log.error "service_port must not be ${ingress_proxy_port}, it is reserved for Home Assistant Ingress proxying"
  exit 1
fi

case "${language}" in
  en|zh_cn)
    ;;
  *)
    bashio::log.warning "Unsupported language '${language}', fallback to zh_cn"
    language="zh_cn"
    ;;
esac

case "${log_level}" in
  info|debug|trace)
    ;;
  *)
    bashio::log.warning "Unsupported log_level '${log_level}', fallback to info"
    log_level="info"
    ;;
esac

mkdir -p \
  "${app_dir}" \
  "${data_dir}/lockdown" \
  "${data_dir}/log" \
  "${data_dir}/PlumeImpactor/pairing_files" \
  /run/dbus \
  /etc/nginx/conf.d

mkdir -p "${HOME}/.config"
if [[ ! -e "${HOME}/.config/PlumeImpactor" ]]; then
  ln -s "${data_dir}/PlumeImpactor" "${HOME}/.config/PlumeImpactor"
fi

rm -rf /var/lib/lockdown
ln -s "${data_dir}/lockdown" /var/lib/lockdown

if [[ -d /keep/lib ]]; then
  rm -rf "${data_dir}/PlumeImpactor/lib"
  cp -a /keep/lib "${data_dir}/PlumeImpactor/"
fi

if [[ -d /keep/DeveloperDiskImages ]]; then
  rm -rf "${data_dir}/DeveloperDiskImages"
  cp -a /keep/DeveloperDiskImages "${data_dir}/"
fi

cat > /etc/nginx/conf.d/ingress.conf <<EOF
server {
    listen 8099;
    server_name _;

    client_max_body_size 0;
    proxy_http_version 1.1;
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;
    proxy_buffering off;
    proxy_request_buffering off;

    location = /ingress-shim.js {
        root /opt/ingress;
        access_log off;
        expires -1;
    }

    location / {
        allow 172.30.32.2;
        deny all;

        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        sub_filter_once off;
        sub_filter_types text/html;
        sub_filter 'href="/assets/' 'href="./assets/';
        sub_filter 'src="/assets/' 'src="./assets/';
        sub_filter 'href="/img/' 'href="./img/';
        sub_filter 'src="/img/' 'src="./img/';
        sub_filter '</head>' '<script src="./ingress-shim.js"></script></head>';
        proxy_pass http://127.0.0.1:${service_port};
    }
}
EOF

cat > "${config_path}" <<EOF
app:
  developer_disk_image:
    image_source: ${ddi_image_source}
    cn_proxy: ${ddi_cn_proxy}
log:
  level: ${log_level}
  log_file: ${data_dir}/app.log
  access_log: ${data_dir}/access.log
server:
  listen_addr: 0.0.0.0
  port: ${service_port}
  work_dir: ${data_dir}
EOF

if [[ ! -f "${settings_path}" ]]; then
  cat > "${settings_path}" <<EOF
{
  "app": {
    "language": "${language}"
  }
}
EOF
fi

if [[ -n "${http_proxy}" ]]; then
  export HTTP_PROXY="${http_proxy}"
  export http_proxy="${http_proxy}"
fi

if [[ -n "${https_proxy}" ]]; then
  export HTTPS_PROXY="${https_proxy}"
  export https_proxy="${https_proxy}"
fi

dbus-uuidgen --ensure=/etc/machine-id
dbus-daemon --system --fork --nopidfile
avahi-daemon --daemonize --no-chroot
/etc/init.d/usbmuxd start

bashio::log.info "Starting atvloadly on 0.0.0.0:${service_port}"
/usr/bin/atvloadly server -c "${config_path}" &
atvloadly_pid=$!

cleanup() {
  if kill -0 "${atvloadly_pid}" 2>/dev/null; then
    kill "${atvloadly_pid}" 2>/dev/null || true
    wait "${atvloadly_pid}" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

bashio::log.info "Starting ingress proxy on 127.0.0.1:${ingress_proxy_port} -> 127.0.0.1:${service_port}"

exec nginx -g 'daemon off;'
