# frozen_string_literal: true

module TogodxMcp
  module Config
    module_function

    def togodx_base_url
      ENV.fetch("TOGODX_BASE_URL", "https://togodx.dbcls.jp/human")
    end

    def togodx_config_url
      ENV.fetch(
        "TOGODX_CONFIG_URL",
        "https://raw.githubusercontent.com/togodx/togodx-config-human/develop/config/attributes.dx-server.json"
      )
    end

    def togoid_base_url
      ENV.fetch("TOGOID_BASE_URL", "https://api.togoid.dbcls.jp")
    end

    def togodx_ui_url
      ENV.fetch("TOGODX_UI_URL", "https://togodx.dbcls.jp/human")
    end
  end
end
