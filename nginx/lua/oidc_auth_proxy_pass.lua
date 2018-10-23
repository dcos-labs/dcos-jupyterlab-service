local require = require
local ngx = ngx

local function is_empty(s)
  return (s == nil) or (s == '')
end

local function is_not_empty(s)
  return (s ~= nil) and (s ~= '')
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

-- OpenID Connect Options - https://github.com/zmartzone/lua-resty-openidc
local opts = {
    redirect_uri = os.getenv("OIDC_REDIRECT_URI"),
    discovery = os.getenv("OIDC_DISCOVERY_URI"),
    client_id = os.getenv("OIDC_CLIENT_ID"),
    client_secret = os.getenv("OIDC_CLIENT_SECRET"),
    scope = os.getenv("OIDC_SCOPE") or "openid profile email",
    refresh_session_interval = os.getenv("OIDC_REFRESH_SESSION_INTERVAL") or 3300,
    iat_slack = os.getenv("OIDC_IAT_SLACK") or 300,
    logout_path = os.getenv("OIDC_LOGOUT_PATH") or "/logout",
    redirect_after_logout_with_id_token_hint = os.getenv("OIDC_REDIRECT_AFTER_LOGOUT_WITH_ID_TOKEN_HINT") or true,
    token_endpoint_auth_method = os.getenv("OIDC_TOKEN_ENDPOINT_AUTH_METHOD") or "client_secret_basic",
    ssl_verify = os.getenv("OIDC_TLS_VERIFY") or "yes",
    renew_access_token_on_expiry = os.getenv("OIDC_RENEW_ACCESS_TOKEN_ON_EXPIRY") or true,
    revoke_tokens_on_logout = os.getenv("OIDC_REVOKE_TOKENS_ON_LOGOUT") or true,
    proxy_opts = proxy_opts
}

ngx.log(ngx.DEBUG, "redirect_uri: " .. tostring(opts.redirect_uri))
ngx.log(ngx.DEBUG, "discovery: " .. tostring(opts.discovery))
ngx.log(ngx.DEBUG, "client_id: " .. tostring(opts.client_id))
-- ngx.log(ngx.DEBUG, tostring(opts.client_secret))

if is_not_empty(os.getenv("OIDC_AUTHORIZATION_PARAMS")) then
    -- authorization_params = { hd="zmartzone.eu", resource="ABC:DEF:GH-12345-6789-foo-bar" },
    opts["authorization_params"] = require("cjson").decode(os.getenv("OIDC_AUTHORIZATION_PARAMS"))
    ngx.log(ngx.DEBUG, "authorization_params: " .. tostring(opts.authorization_params))
end

if is_not_empty(os.getenv("OIDC_REDIRECT_AFTER_LOGOUT_URI")) then
    opts["redirect_after_logout_uri"] = os.getenv("OIDC_REDIRECT_AFTER_LOGOUT_URI")
    ngx.log(ngx.DEBUG, "redirect_after_logout_uri: " .. tostring(opts.redirect_after_logout_uri))
end

if is_not_empty(os.getenv("OIDC_POST_LOGOUT_REDIRECT_URI")) then
    opts["post_logout_redirect_uri"] = os.getenv("OIDC_POST_LOGOUT_REDIRECT_URI")
    ngx.log(ngx.DEBUG, "post_logout_redirect_uri: " .. tostring(opts.post_logout_redirect_uri))
end

-- Don't trigger the OpenID Connect authentication flow if the minimal options aren't set
if is_empty(opts.discovery) or is_empty(opts.client_id) then
    return true
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
    ngx.log(ngx.DEBUG, "Authorizing UPN: " .. os.getenv("OIDC_UPN") .. " against " .. tostring(res.id_token.upn))
    if res.id_token.upn ~= os.getenv("OIDC_UPN") then
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

ngx.log(ngx.DEBUG, "Authorization successful")

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
