Code.require_file "support/test_helpers.ex", __DIR__

ExUnit.start()
Application.ensure_all_started(:bypass)
