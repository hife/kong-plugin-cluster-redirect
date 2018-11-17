local helpers = require "spec.helpers"
local cjson = require "cjson"

for _, strategy in helpers.each_strategy() do
  describe("plugin: cluster-redirect (access) [#" .. strategy .. "]", function()
    local db, bp, dao
    local client

    -- Admin API REST interface
    local function api_send(method, path, body, forced_port)
      local api_client = helpers.admin_client()
      local res, err = api_client:send({
        method = method,
        path = path,
        headers = {
          ["Content-Type"] = "application/json"
        },
        body = body,
      })
      if not res then
        api_client:close()
        return nil, err
      end
      local res_body = res.status ~= 204 and cjson.decode((res:read_body()))
      api_client:close()
      return res.status, res_body
    end

    setup(function()
      bp, db, dao = helpers.get_db_utils(strategy)

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- set the config item to make sure our plugin gets loaded
        plugins = "bundled,cluster-redirect",         -- since Kong CE 0.14
        custom_plugins = "cluster-redirect",          -- pre Kong CE 0.14
      }))

      assert.same(201, api_send("POST", "/upstreams", { name = "europe_cluster", slots = 10 }))
      assert.same(201, api_send("POST", "/upstreams", { name = "italy_cluster", slots = 10 }))
      assert.same(201, api_send("POST", "/upstreams/europe_cluster/targets", { target = "requestloggerbin.herokuapp.com:80"} ))
      assert.same(201, api_send("POST", "/upstreams/italy_cluster/targets", { target = "mockbin.org:80" }))

      assert.same(201, api_send("POST", "/services", {
        name = "europe-service",
        url = "http://europe_cluster:80/bin/a10f2738-6456-4bae-b5a9-f6c5e0463a66/view",
      }))

      assert.same(201, api_send("POST", "/services/europe-service/routes", {
        paths = { "/local" },
      }))

      assert.same(201, api_send("POST", "/services/europe-service/plugins", {
        name = "cluster-redirect",
        config = {
          redirect = "italy_cluster",
        }
      }))

    end)

    teardown(function()
      helpers.stop_kong(nil, true)
      db:truncate("routes")
      db:truncate("services")
      db:truncate("targets")
      db:truncate("upstreams")
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)

    -- Case 0: request with /local X-Country header (Italy) and X-Region
    describe("request", function()
      it("Positive case: matching for italy_cluster", function()
        local r = assert(client:send {
          method = "GET",
          path = "/local",  -- makes mockbin return the entire request
           headers = {
            ["X-Country"] = "Italy",
            ["X-Regione"] = "Abruzzo",
            ["Host"] = "test.com",
          }
        })
       
        local body = assert.res_status(200, r)
        assert.equal("", body)
      end)

      -- Case 1: request with /local X-Country header (non-Italy) and X-Region
      it("Negative case: going streight to europe_cluster", function()
        local r = assert(client:send {
          method = "GET",
          path = "/local",  -- makes mockbin return the entire request
           headers = {
            ["X-Country"] = "Spain",
            ["X-Regione"] = "Abruzzo",
            ["Host"] = "test.com",
          }
        })
       
        local body = assert.res_status(200, r)
        local json = cjson.decode(body)

        assert.is_string(json.content.text)
        assert.equal("This is europe_cluster", json.content.text)
      end)
    end)

    describe("request", function()
    end)

  end)
end
