local require = require
local ngx = ngx

local function is_empty(s)
  return (s == nil) or (s == '')
end

local function is_not_empty(s)
  return (s ~= nil) and (s ~= '')
end

local resolver = require "resty.dns.resolver"

-- Use Spartan (https://github.com/dcos/spartan) when running on DC/OS
if is_not_empty(os.getenv("OIDC_USE_SPARTAN_RESOLVER")) then
    r, err = resolver:new{
        nameservers = {{"198.51.100.1", 53},
                       {"198.51.100.2", 53},
                       {"198.51.100.3", 53}},
        retrans = 3,  -- retransmissions on receive timeout
        timeout = 2000,  -- msec
    }
else
-- Use the OpenDNS resolvers
    r, err = resolver:new{
        nameservers = {{"208.67.220.220", 53},
                       {"208.67.222.222", 53}},
        retrans = 3,  -- retransmissions on receive timeout
        timeout = 2000,  -- msec
    }
end

if not r then
    ngx.log(ngx.ERR, "Failed to instantiate the resolver: " .. err)
    return nil
end

local proxy_opts = {}

if is_not_empty(os.getenv("HTTP_PROXY")) then
    proxy_opts["http_proxy"] = os.getenv("HTTP_PROXY")
end

if is_not_empty(os.getenv("HTTPS_PROXY")) then
    proxy_opts["https_proxy"] = os.getenv("HTTPS_PROXY")
end

if is_not_empty(os.getenv("NO_PROXY")) then
    proxy_opts["no_proxy"] = os.getenv("NO_PROXY")
end

-- Don't pass on an empty proxy_opts table
if next(proxy_opts) == nil then
   proxy_opts = nil
end

-- OpenID Connect Options
local opts = {
    redirect_uri_path = os.getenv("OIDC_REDIRECT_URI") or "/redirect_uri",
    discovery = os.getenv("OIDC_DISCOVERY_URI"),
    client_id = os.getenv("OIDC_CLIENT_ID"),
    client_secret = os.getenv("OIDC_CLIENT_SECRET"),
    ssl_verify = os.getenv("OIDC_TLS_VERIFY") or "yes",
    token_endpoint_auth_method = os.getenv("OIDC_AUTH_METHOD") or "client_secret_basic",
    scope = os.getenv("OIDC_SCOPE") or "openid profile email",
    iat_slack = 600,
    proxy_opts = proxy_opts
}

ngx.log(ngx.DEBUG, "redirect_uri: " .. tostring(opts.redirect_uri_path))
ngx.log(ngx.DEBUG, "discovery: " .. tostring(opts.discovery))
ngx.log(ngx.DEBUG, "client_id: " .. tostring(opts.client_id))
-- ngx.log(ngx.DEBUG, tostring(opts.client_secret))

-- Don't trigger the OpenID Connect authentication flow if the minimal options aren't set
if is_empty(opts.redirect_uri_path) or is_empty(opts.discovery) or is_empty(opts.client_id) or is_empty(opts.client_secret) then
    return true
end

-- Set a fixed and unique session secret for every domain to prevent an infinite redirect loop
--   https://github.com/pingidentity/lua-resty-openidc/issues/32#issuecomment-273900768
--   https://github.com/openresty/lua-nginx-module#set_by_lua
ngx.log(ngx.DEBUG, "ngx.var.server_name: " .. tostring(ngx.var.server_name))
local session_opts = {
    secret = ngx.encode_base64(ngx.var.server_name):sub(0, 32)
}
ngx.log(ngx.DEBUG, "session_opts.secret: " .. tostring(session_opts.secret))

-- Change the redirect uri to the root uri to prevent a 500 error
local request_uri_args = ngx.req.get_uri_args()
if ngx.var.request_uri == opts.redirect_uri_path and (not request_uri_args.code or not request_uri_args.state) then
    -- https://github.com/openresty/lua-nginx-module#ngxreqset_uri
    -- Note: 1. 'jump=true' isn't allowed in 'access_by_lua' directive
    --       2. 'ngx.req.set_uri' will not change the value of 'ngx.var.request_uri'
    --ngx.req.set_uri("/", false)
    ngx.log(ngx.DEBUG, "Changing redirect_uri to root uri...")
    return ngx.redirect("/")
end

local res, err, _target, session = require("resty.openidc").authenticate(opts)

ngx.log(ngx.DEBUG, "resty.openidc.authenticate res: " .. tostring(res))
ngx.log(ngx.DEBUG, "resty.openidc.authenticate err: " .. tostring(err))

if err then
    ngx.status = 500
    ngx.header.content_type = 'text/html';

    ngx.say("There was an error while logging in: " .. err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

ngx.log(ngx.DEBUG, "Authentication successful")

-- Only authorize a valid user, based on their email address, if specified
if is_not_empty(os.getenv("OIDC_EMAIL")) then
    ngx.log(ngx.DEBUG, "Authorizing Email: " .. os.getenv("OIDC_EMAIL") .. " against " .. tostring(res.user.email))
    if res.user.email ~= os.getenv("OIDC_EMAIL") then
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

-- Only authorize a valid user, based on their User Principal Name (UPN), if specified
if is_not_empty(os.getenv("OIDC_UPN")) then
    ngx.log(ngx.DEBUG, "Authorizing UPN: " .. os.getenv("OIDC_UPN") .. " against " .. tostring(res.user.upn))
    if res.user.email ~= os.getenv("OIDC_UPN") then
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

ngx.log(ngx.DEBUG, "Authorization successful")

ngx.log(ngx.DEBUG, "Setting Authorization Bearer Token Header...")
ngx.req.set_header("Authorization", "Bearer " .. session.data.enc_id_token)

-- Set Authentication headers for downstream SSO
if res.id_token.username then
    ngx.log(ngx.DEBUG, "Setting X-User Header...")
    ngx.req.set_header("X-User", res.id_token.username)
    ngx.log(ngx.DEBUG, "Setting X-Remote-User Header...")
    ngx.req.set_header("X-Remote-User", res.id_token.username)
    if res.id_token.groups then
        ngx.log(ngx.DEBUG, "Setting X-Remote-Group Header(s)...")
        for i, group in ipairs(res.id_token.groups) do
            ngx.req.set_header("X-Remote-Group", group)
        end
    end
else
    ngx.req.clear_header("X-USER")
    ngx.req.clear_header("X-Remote-USER")
    ngx.req.clear_header("X-Remote-GROUP")
end

ngx.log(ngx.DEBUG, "Proxy-Passing...")
