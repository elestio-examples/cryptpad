#set env vars
set -o allexport; source .env; set +o allexport;

mkdir -p ./data
mkdir -p ./data/blob
mkdir -p ./data/block
mkdir -p ./data/data
mkdir -p ./data/data/logs
mkdir -p ./data/files
mkdir -p ./customize

chown -R 4001:4001 ./data
chown -R 4001:4001 ./customize

cat > ./data/cryptpad.conf << 'EOF'
server {
    listen 443 ssl;

    # Set trusted proxy and header containing real client IP
    set_real_ip_from  172.0.0.0/8;
    real_ip_recursive on;
    real_ip_header    X-Forwarded-For;
    listen [::]:443 ssl;

    set $main_domain "${DOMAIN}";
    set $sandbox_domain "sandbox-${DOMAIN}";

    set $allowed_origins "*";

    set $api_domain "${main_domain}";
    set $files_domain "${main_domain}";

    # nginx doesn't let you set server_name via variables, so you need to hardcode your domains here
    server_name ${DOMAIN} sandbox-${DOMAIN};

    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;

    ssl_dhparam /etc/nginx/dhparam.pem; # openssl dhparam -out /etc/nginx/dhparam.pem 4096

    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;
    ssl_session_tickets off;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    # replace with the IP address of your resolver
    resolver 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 208.67.222.222 208.67.220.220;

    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options nosniff;
    add_header Access-Control-Allow-Origin "${allowed_origins}";
    # add_header X-Frame-Options "SAMEORIGIN";

    # Opt out of Google's FLoC Network
    add_header Permissions-Policy interest-cohort=();

    # Enable SharedArrayBuffer in Firefox (for .xlsx export)
    add_header Cross-Origin-Resource-Policy cross-origin;
    add_header Cross-Origin-Embedder-Policy require-corp;

    # Insert the path to your CryptPad repository root here
    root /cryptpad;
    index index.html;
    error_page 404 /customize.dist/404.html;

    # any static assets loaded with "ver=" in their URL will be cached for a year
    if ($args ~ ver=) {
        set $cacheControl max-age=31536000;
    }


    if ($uri ~ ^(\/|.*\/|.*\.html)$) {
        set $cacheControl no-cache;
    }

    # Will not set any header if it is emptystring
    add_header Cache-Control $cacheControl;

    # CSS can be dynamically set inline, loaded from the same domain, or from $main_domain
    set $styleSrc   "'unsafe-inline' 'self' https://${main_domain}";

    set $connectSrc "'self' https://${main_domain} blob: wss://${api_domain} https://${sandbox_domain}";

    # fonts can be loaded from data-URLs or the main domain
    set $fontSrc    "'self' data: https://${main_domain}";

    # images can be loaded from anywhere, though we'd like to deprecate this as it allows the use of images for tracking
    set $imgSrc     "'self' data: blob: https://${main_domain}";

    set $frameSrc   "'self' https://${sandbox_domain} blob:";

    # specifies valid sources for loading media using video or audio
    set $mediaSrc   "blob:";

    set $childSrc   "https://${main_domain}";

    set $workerSrc  "'self'";

    # script-src specifies valid sources for javascript, including inline handlers
    set $scriptSrc  "'self' resource: https://${main_domain}";

    set $frameAncestors "'self' https://${main_domain}";
    # set $frameAncestors "'self' https: vector:";

    set $unsafe 0;
    # the following assets are loaded via the sandbox domain
    # they unfortunately still require exceptions to the sandboxing to work correctly.
    if ($uri ~ ^\/(sheet|doc|presentation)\/inner.html.*$) { set $unsafe 1; }
    if ($uri ~ ^\/common\/onlyoffice\/.*\/.*\.html.*$) { set $unsafe 1; }

    # everything except the sandbox domain is a privileged scope, as they might be used to handle keys
    if ($host != $sandbox_domain) { set $unsafe 0; }
    if ($uri ~ ^\/unsafeiframe\/inner\.html.*$) { set $unsafe 1; }

    # privileged contexts allow a few more rights than unprivileged contexts, though limits are still applied
    if ($unsafe) {
        set $scriptSrc "'self' 'unsafe-eval' 'unsafe-inline' resource: https://${main_domain}";
    }

    # Finally, set all the rules you composed above.
    add_header Content-Security-Policy "default-src 'none'; child-src $childSrc; worker-src $workerSrc; media-src $mediaSrc; style-src $styleSrc; script-src $scriptSrc; connect-src $connectSrc; font-src $fontSrc; img-src $imgSrc; frame-src $frameSrc; frame-ancestors $frameAncestors";

    location ^~ /cryptpad_websocket {
        proxy_pass http://localhost:3000;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # WebSocket support (nginx 1.4)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection upgrade;
    }

    location ^~ /customize.dist/ {
        # This is needed in order to prevent infinite recursion between /customize/ and the root
    }

    location ^~ /customize/ {
        rewrite ^/customize/(.*)$ $1 break;
        try_files /customize/$uri /customize.dist/$uri;
    }

    location ~ ^/api/.*$ {
        proxy_pass http://localhost:3000;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # These settings prevent both NGINX and the API server
        # from setting the same headers and creating duplicates
        proxy_hide_header Cross-Origin-Resource-Policy;
        add_header Cross-Origin-Resource-Policy cross-origin;
        proxy_hide_header Cross-Origin-Embedder-Policy;
        add_header Cross-Origin-Embedder-Policy require-corp;
    }

    # encrypted blobs are immutable and are thus cached for a year
    location ^~ /blob/ {
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' "${allowed_origins}";
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'application/octet-stream; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        add_header X-Content-Type-Options nosniff;
        add_header Cache-Control max-age=31536000;
        add_header 'Access-Control-Allow-Origin' "${allowed_origins}";
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Content-Length';
        add_header 'Access-Control-Expose-Headers' 'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Range,Content-Length';
        try_files $uri =404;
    }

    location ^~ /block/ {
        add_header X-Content-Type-Options nosniff;
        add_header Cache-Control max-age=0;
        try_files $uri =404;
    }

    location ~ ^/(register|login|settings|user|pad|drive|poll|slide|code|whiteboard|file|media|profile|contacts|todo|filepicker|debug|kanban|sheet|support|admin|notifications|teams|calendar|presentation|doc|form|report|convert|checkup)$ {
        rewrite ^(.*)$ $1/ redirect;
    }

    # Finally, serve anything the above exceptions don't govern.
    try_files /customize/www/$uri /customize/www/$uri/index.html /www/$uri /www/$uri/index.html /customize/$uri;
}
EOF

cat > ./data/config.js << 'EOF'
module.exports = {

    httpUnsafeOrigin: 'https://${DOMAIN}',
    httpSafeOrigin: 'https://sandbox-${DOMAIN}',
    httpAddress: '0.0.0.0',
    // maxWorkers: 4,

    /* =====================
     *         Admin
     * ===================== */

    adminKeys: [
        "",
    ],
    adminEmail: '${ADMIN_EMAIL}',
    supportMailboxPublicKey: '',

    /* =====================
     *        STORAGE
     * ===================== */

    //inactiveTime: 90, // days
    //archiveRetentionTime: 15,
     //accountRetentionTime: 365,
    //disableIntegratedEviction: true,
    maxUploadSize: 150 * 1024 * 1024,
    //premiumUploadSize: 100 * 1024 * 1024,

    //1GB
    defaultStorageLimit: 1 * 1024 * 1024 * 1024,

    /* =====================
     *   DATABASE VOLUMES
     * ===================== */

    filePath: './datastore/',
    archivePath: './data/archive',
    pinPath: './data/pins',
    taskPath: './data/tasks',
    blockPath: './block',
    blobPath: './blob',
    blobStagingPath: './data/blobstage',
    decreePath: './data/decrees',
    logPath: './data/logs',

    /* =====================
     *       Debugging
     * ===================== */

    cryptpad_content_security_enabled: "False",
    cryptpad_pad_content_security_enabled: "False",
    logToStdout: false,
    logLevel: 'info',
    logFeedback: false,
    verbose: false,
    installMethod: 'docker',
};
EOF
chown -R 4001:4001 ./data/config.js

openssl dhparam -out ./data/dh.pem 2048